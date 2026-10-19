import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../api/api_error.dart';
import '../api/apis.dart';
import '../api/auth_interceptor.dart';
import '../models/auth_models.dart';
import '../storage/secure_store.dart';
import '../util/jwt.dart';

enum SessionStatus { unknown, signedOut, signedIn, mustChangePassword }

/// Things the UI layer reacts to (navigation, dialogs). Services never navigate.
sealed class SessionEvent {
  const SessionEvent();
}

/// The session ended. [reason] is null for a normal sign-out.
class SessionEnded extends SessionEvent {
  const SessionEnded(this.reason);
  final ApiError? reason;
}

class UpdateRequired extends SessionEvent {
  const UpdateRequired();
}

class TokenRefreshed extends SessionEvent {
  const TokenRefreshed(this.accessToken);
  final String accessToken;
}

/// Owns tokens and the current user. Access token in memory only; refresh token and the
/// cached profile in secure storage so the crew app can start offline.
class SessionService extends GetxService implements AuthTokenSource {
  SessionService({
    required SecureStore secure,
    required AuthApi Function() authApi,
    DateTime Function()? now,
    this.refreshLead = const Duration(seconds: 60),
  })  : _secure = secure,
        _authApi = authApi,
        _now = now ?? DateTime.now;

  final SecureStore _secure;
  final AuthApi Function() _authApi;
  final DateTime Function() _now;

  /// Refresh this long before the access token expires (15 min tokens → ~14 min).
  final Duration refreshLead;

  final status = SessionStatus.unknown.obs;

  /// True while [signOut] runs (server logout can take a few seconds): buttons show a spinner.
  final signingOut = false.obs;
  final me = Rxn<Me>();
  final _events = StreamController<SessionEvent>.broadcast();
  final _wipeHooks = <Future<void> Function()>[];

  Stream<SessionEvent> get events => _events.stream;

  String? _access;
  Completer<RefreshOutcome>? _refreshing;
  Timer? _refreshTimer;

  @override
  String? get accessToken => _access;

  @override
  Future<RefreshOutcome>? get pendingRefresh => _refreshing?.future;

  bool get isSignedIn => status.value == SessionStatus.signedIn;

  /// Registers cleanup that runs on every sign-out (outbox, caches, live socket, GPS).
  void onWipe(Future<void> Function() hook) => _wipeHooks.add(hook);

  /// Restores a session saved on disk. Works offline: the cached profile is used and
  /// the access token is fetched in the background once the server is reachable.
  Future<void> restore() async {
    final rt = await _secure.read(SecureKeys.refreshToken);
    if (rt == null) {
      status.value = SessionStatus.signedOut;
      return;
    }
    final cached = await _secure.read(SecureKeys.me);
    if (cached != null) {
      try {
        me.value = Me.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      } on Object {
        me.value = null;
      }
    }
    status.value = me.value?.mustChangePassword == true ? SessionStatus.mustChangePassword : SessionStatus.signedIn;
    unawaited(refreshAccessToken());
  }

  /// Starts a session from `/auth/verify` (or a `signed_in` login).
  Future<void> start(LoginTokens tokens) async {
    _access = tokens.accessToken;
    if (tokens.refreshToken != null) await _secure.write(SecureKeys.refreshToken, tokens.refreshToken!);
    status.value = tokens.mustChangePassword ? SessionStatus.mustChangePassword : SessionStatus.signedIn;
    _scheduleRefresh(tokens.accessToken);
  }

  /// `GET /me`, cached for offline start.
  Future<Me> loadMe() async {
    final m = await _authApi().me();
    me.value = m;
    await _secure.write(SecureKeys.me, jsonEncode(m.toJson()));
    if (m.mustChangePassword) status.value = SessionStatus.mustChangePassword;
    return m;
  }

  /// After a successful `/auth/change-password`.
  void passwordChanged() {
    if (status.value == SessionStatus.mustChangePassword) status.value = SessionStatus.signedIn;
  }

  /// Single-flight refresh: concurrent callers wait for the same answer.
  @override
  Future<RefreshOutcome> refreshAccessToken() {
    final running = _refreshing;
    if (running != null) return running.future;
    final c = _refreshing = Completer<RefreshOutcome>();
    unawaited(_doRefresh().then(c.complete).whenComplete(() => _refreshing = null));
    return c.future;
  }

  Future<RefreshOutcome> _doRefresh() async {
    final rt = await _secure.read(SecureKeys.refreshToken);
    if (rt == null) return const RefreshRejected(ApiError(status: 401, code: 'UNAUTHORIZED', ar: 'انتهت الجلسة', en: 'Session ended'));
    try {
      final r = await _authApi().refresh(RefreshBody(rt));
      final t = r.accessToken;
      if (t == null) return const RefreshUnreachable();
      _access = t;
      _scheduleRefresh(t);
      _events.add(TokenRefreshed(t));
      return Refreshed(t);
    } on DioException catch (e) {
      final err = ApiError.of(e);
      if (err.isRetryable) {
        _scheduleRetry();
        return const RefreshUnreachable();
      }
      return RefreshRejected(err);
    }
  }

  void _scheduleRefresh(String token) {
    _refreshTimer?.cancel();
    final exp = jwtExpiry(token);
    if (exp == null) return;
    var wait = exp.difference(_now().toUtc()) - refreshLead;
    if (wait < const Duration(seconds: 5)) wait = const Duration(seconds: 5);
    _refreshTimer = Timer(wait, () => unawaited(_proactiveRefresh()));
  }

  void _scheduleRetry() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(seconds: 30), () => unawaited(_proactiveRefresh()));
  }

  Future<void> _proactiveRefresh() async {
    if (status.value == SessionStatus.signedOut) return;
    final outcome = await refreshAccessToken();
    if (outcome is RefreshRejected) onSessionError(outcome.error);
  }

  /// Only session-level errors arrive here (see `sessionCodes` and rejected refreshes).
  /// Anything other than "update" or "change password" ends the session and wipes local data:
  /// lost phone (DEVICE_BLOCKED), revoked session, disabled account, dead refresh token.
  @override
  void onSessionError(ApiError error) {
    switch (error.code) {
      case 'APP_UPDATE_REQUIRED':
        _events.add(const UpdateRequired());
      case 'PASSWORD_CHANGE_REQUIRED':
        if (status.value != SessionStatus.signedOut) status.value = SessionStatus.mustChangePassword;
      default:
        unawaited(signOut(reason: error, callServer: false));
    }
  }

  bool _signingOut = false;

  /// Ends the session: tells the server (best effort), wipes tokens, profile, PIN verifier
  /// and every registered cache. The device id stays.
  Future<void> signOut({ApiError? reason, bool callServer = true}) async {
    if (_signingOut || status.value == SessionStatus.signedOut) return;
    _signingOut = true;
    signingOut.value = true;
    try {
      if (callServer && _access != null) {
        try {
          await _authApi().logout().timeout(const Duration(seconds: 5));
        } on Object {
          // Offline or already revoked; the local wipe below is what matters.
        }
      }
      _refreshTimer?.cancel();
      _access = null;
      for (final k in SecureKeys.sessionKeys) {
        await _secure.delete(k);
      }
      for (final hook in _wipeHooks) {
        try {
          await hook();
        } on Object {
          // One failing cleanup must not keep data from the others being wiped.
        }
      }
      me.value = null;
      status.value = SessionStatus.signedOut;
      _events.add(SessionEnded(reason));
    } finally {
      _signingOut = false;
      signingOut.value = false;
    }
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    unawaited(_events.close());
    super.onClose();
  }
}
