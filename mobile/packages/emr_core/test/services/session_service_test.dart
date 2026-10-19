import 'dart:async';
import 'dart:convert';

import 'package:emr_core/emr_core.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_adapter.dart';

/// Unsigned JWT with the given expiry (the app never verifies signatures).
String jwt(DateTime exp) {
  String part(Map<String, Object> m) => base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${part({'alg': 'none'})}.${part({'sub': 'u1', 'exp': exp.millisecondsSinceEpoch ~/ 1000})}.sig';
}

void main() {
  late FakeAdapter http;
  late MemorySecureStore secure;
  late SessionService session;
  late ApiClient api;
  late List<SessionEvent> events;
  final now = DateTime.utc(2026, 10, 15, 8);

  setUp(() {
    http = FakeAdapter();
    secure = MemorySecureStore({SecureKeys.deviceId: 'dev-1', SecureKeys.cacheKey: 'k'});
    session = SessionService(secure: secure, authApi: () => api.auth, now: () => now);
    api = ApiClient(
      config: const AppConfig(clientApp: ClientApp.crew, version: '1.0.0', apiBaseUrl: 'http://test'),
      tokens: session,
      adapter: http,
    );
    events = [];
    session.events.listen(events.add);
  });

  const meJson = {'id': 'u1', 'username': 'demo.driver1', 'role': 'DRIVER', 'preferredLanguage': 'ar'};

  test('start saves only the refresh token on disk', () async {
    await session.start(LoginTokens(accessToken: jwt(now.add(const Duration(minutes: 15))), refreshToken: 'rt-1'));
    expect(session.isSignedIn, isTrue);
    expect(secure.values[SecureKeys.refreshToken], 'rt-1');
    expect(secure.values.values, isNot(contains(session.accessToken)));
  });

  test('mustChangePassword puts the session in the change-password state', () async {
    await session.start(LoginTokens(accessToken: jwt(now), refreshToken: 'rt', mustChangePassword: true));
    expect(session.status.value, SessionStatus.mustChangePassword);
    session.passwordChanged();
    expect(session.status.value, SessionStatus.signedIn);
  });

  test('loadMe caches the profile and restore() brings it back offline', () async {
    http.reply('GET /api/v1/me', 200, meJson);
    await session.start(LoginTokens(accessToken: jwt(now), refreshToken: 'rt-1'));
    await session.loadMe();

    final offline = FakeAdapter()..fallback = (_, _) => const FakeReply.offline();
    final restored = SessionService(secure: secure, authApi: () => api2(offline, null).auth, now: () => now);
    await restored.restore();
    await pumpEventQueue();

    expect(restored.isSignedIn, isTrue, reason: 'an offline restart keeps the crew signed in');
    expect(restored.me.value!.username, 'demo.driver1');
    expect(restored.accessToken, isNull);
  });

  test('restore without a refresh token means signed out', () async {
    await session.restore();
    expect(session.status.value, SessionStatus.signedOut);
  });

  test('refresh is single-flight', () async {
    await secure.write(SecureKeys.refreshToken, 'rt');
    final gate = Completer<void>();
    http.on('POST /api/v1/auth/refresh', (_, _) async {
      await gate.future;
      return FakeReply(200, {'accessToken': jwt(now.add(const Duration(minutes: 15)))});
    });

    final a = session.refreshAccessToken();
    final b = session.refreshAccessToken();
    gate.complete();
    final results = await Future.wait([a, b]);

    expect(results.every((r) => r is Refreshed), isTrue);
    expect(http.calls('POST /api/v1/auth/refresh'), hasLength(1));
    expect(http.bodies.single, {'refreshToken': 'rt'});
    expect(events.whereType<TokenRefreshed>(), hasLength(1));
  });

  test('a request made during the startup refresh waits for it (one refresh, no 401)', () async {
    await secure.write(SecureKeys.refreshToken, 'rt');
    final gate = Completer<void>();
    http.on('POST /api/v1/auth/refresh', (_, _) async {
      await gate.future;
      return const FakeReply(200, {'accessToken': 'fresh'});
    });
    http.reply('GET /api/v1/me', 200, meJson);

    final refresh = session.refreshAccessToken();
    final me = session.loadMe();
    gate.complete();
    await Future.wait([refresh, me]);

    expect(http.calls('POST /api/v1/auth/refresh'), hasLength(1));
    expect(http.calls('GET /api/v1/me').single.headers['Authorization'], 'Bearer fresh');
  });

  test('refresh offline is Unreachable and keeps the session', () async {
    await secure.write(SecureKeys.refreshToken, 'rt');
    http.offline('POST /api/v1/auth/refresh');
    expect(await session.refreshAccessToken(), isA<RefreshUnreachable>());
    expect(secure.values[SecureKeys.refreshToken], 'rt');
  });

  test('a refused refresh is Rejected with the server error', () async {
    await secure.write(SecureKeys.refreshToken, 'rt');
    http.reply('POST /api/v1/auth/refresh', 401, errorBody('SESSION_INVALID'));
    final r = await session.refreshAccessToken();
    expect((r as RefreshRejected).error.code, 'SESSION_INVALID');
  });

  test('an expired access token is refreshed transparently for a normal call', () async {
    await session.start(LoginTokens(accessToken: 'expired', refreshToken: 'rt'));
    http.reply('GET /api/v1/me', 401, errorBody('UNAUTHORIZED'));
    http.reply('GET /api/v1/me', 200, meJson);
    http.reply('POST /api/v1/auth/refresh', 200, {'accessToken': 'new-token'});

    final me = await session.loadMe();

    expect(me.username, 'demo.driver1');
    expect(session.accessToken, 'new-token');
    expect(http.calls('GET /api/v1/me').last.headers['Authorization'], 'Bearer new-token');
  });

  test('DEVICE_BLOCKED wipes the session and every registered cache but keeps the device id', () async {
    var wiped = 0;
    session.onWipe(() async => wiped++);
    await session.start(LoginTokens(accessToken: jwt(now), refreshToken: 'rt'));
    await secure.write(SecureKeys.pinVerifier, 'v');
    await secure.write(SecureKeys.me, '{}');
    http.reply('GET /api/v1/crew/job', 401, errorBody('DEVICE_BLOCKED'));

    await expectLater(api.crew.job(), throwsA(anything));
    await pumpEventQueue();

    expect(session.status.value, SessionStatus.signedOut);
    expect(wiped, 1);
    expect(secure.values.keys, unorderedEquals([SecureKeys.deviceId, SecureKeys.cacheKey]));
    expect((events.whereType<SessionEnded>().single.reason)!.code, 'DEVICE_BLOCKED');
    expect(http.calls('POST /api/v1/auth/logout'), isEmpty, reason: 'a blocked device cannot log out');
  });

  test('signOut calls the server, wipes, and fires once even if called twice', () async {
    http.reply('POST /api/v1/auth/logout', 204);
    await session.start(LoginTokens(accessToken: jwt(now), refreshToken: 'rt'));

    await Future.wait([session.signOut(), session.signOut()]);
    await pumpEventQueue();

    expect(http.calls('POST /api/v1/auth/logout'), hasLength(1));
    expect(events.whereType<SessionEnded>(), hasLength(1));
    expect(events.whereType<SessionEnded>().single.reason, isNull);
    expect(session.accessToken, isNull);
  });

  test('signingOut is true while the server logout runs, false after', () async {
    final gate = Completer<void>();
    http.on('POST /api/v1/auth/logout', (_, _) async {
      await gate.future;
      return const FakeReply(204);
    });
    await session.start(LoginTokens(accessToken: jwt(now), refreshToken: 'rt'));
    final f = session.signOut();
    await pumpEventQueue();
    expect(session.signingOut.value, isTrue);
    gate.complete();
    await f;
    expect(session.signingOut.value, isFalse);
  });

  test('signOut still wipes locally when the server is unreachable', () async {
    http.offline('POST /api/v1/auth/logout');
    await session.start(LoginTokens(accessToken: jwt(now), refreshToken: 'rt'));
    await session.signOut();
    expect(secure.values.containsKey(SecureKeys.refreshToken), isFalse);
    expect(session.status.value, SessionStatus.signedOut);
  });

  test('APP_UPDATE_REQUIRED raises UpdateRequired and keeps the session', () async {
    await session.start(LoginTokens(accessToken: jwt(now), refreshToken: 'rt'));
    session.onSessionError(const ApiError(status: 426, code: 'APP_UPDATE_REQUIRED', ar: '', en: ''));
    await pumpEventQueue();
    expect(events.whereType<UpdateRequired>(), hasLength(1));
    expect(session.isSignedIn, isTrue);
  });

  test('refreshes proactively one minute before the access token expires', () {
    fakeAsync((async) {
      final clock = async.getClock(now);
      final s = SessionService(secure: secure, authApi: () => api.auth, now: clock.now);
      api = ApiClient(
        config: const AppConfig(clientApp: ClientApp.crew, version: '1', apiBaseUrl: 'http://test'),
        tokens: s,
        adapter: http,
      );
      http.reply('POST /api/v1/auth/refresh', 200, {'accessToken': jwt(now.add(const Duration(minutes: 29)))});
      unawaited(s.start(LoginTokens(accessToken: jwt(now.add(const Duration(minutes: 15))), refreshToken: 'rt')));
      async.flushMicrotasks();

      async.elapse(const Duration(minutes: 13, seconds: 50));
      expect(http.calls('POST /api/v1/auth/refresh'), isEmpty);

      async.elapse(const Duration(seconds: 20));
      async.flushMicrotasks();
      expect(http.calls('POST /api/v1/auth/refresh'), hasLength(1));
    });
  });
}

ApiClient api2(FakeAdapter http, AuthTokenSource? tokens) => ApiClient(
      config: const AppConfig(clientApp: ClientApp.crew, version: '1', apiBaseUrl: 'http://test'),
      tokens: tokens ?? _Null(),
      adapter: http,
    );

class _Null implements AuthTokenSource {
  @override
  Future<RefreshOutcome>? get pendingRefresh => null;
  @override
  String? get accessToken => null;
  @override
  Future<RefreshOutcome> refreshAccessToken() async => const RefreshUnreachable();
  @override
  void onSessionError(ApiError error) {}
}
