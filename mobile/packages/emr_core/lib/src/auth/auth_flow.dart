import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../api/api_error.dart';
import '../i18n/locale_service.dart';
import '../models/auth_models.dart';
import '../services/session_service.dart';

abstract final class AuthRoutes {
  static const splash = '/';
  static const login = '/login';
  static const smsCode = '/login/code';
  static const changePassword = '/change-password';
  static const forgotPassword = '/forgot-password';
  static const forceUpdate = '/update';
}

/// What each app plugs into the shared auth module.
class AuthFlowConfig {
  const AuthFlowConfig({
    required this.homeRoute,
    required this.roleAllowed,
    required this.appTitleKey,
    this.afterSignIn,
    this.loginFooter,
    this.usernameLabelKey = 'username',
    this.devPhones = const {},
    this.normalizeUsername,
    this.brandIcon,
    this.showEmergencyCall = false,
  });

  /// Citizen: offer "call 999" on the sign-in screens (help must not depend on an account).
  final bool showEmergencyCall;

  /// The app's mark on the sign-in screens.
  final IconData? brandIcon;

  /// Rewrites what the user typed before login (citizen: `0912…` → `+249912…`).
  final String Function(String input)? normalizeUsername;

  final String homeRoute;

  /// Second line of defence after the server's `WRONG_CLIENT_APP`.
  final bool Function(Me me) roleAllowed;

  /// Runs after every sign-in ([freshLogin] true) and every restored session (false). May return
  /// a route to open instead of home (the crew app asks for the PIN on a restored session).
  final Future<String?> Function(Me me, {required bool freshLogin})? afterSignIn;

  /// Extra actions under the login form (citizen: "Create an account").
  final WidgetBuilder? loginFooter;
  final String appTitleKey;
  final String usernameLabelKey;

  /// Debug only: username → phone, to read SMS codes from `/dev/sms/latest`.
  final Map<String, String> devPhones;
}

/// Arguments for the login screen (a message to show, e.g. "this phone was blocked").
class LoginArgs {
  const LoginArgs({this.message, this.username, this.isError = true});
  final String? message;

  /// Prefills the username (after sign-up).
  final String? username;

  /// False for good news ("account created").
  final bool isError;
}

/// Glues the session to navigation. Services never navigate; this is the one place that does.
class AuthFlow extends GetxService {
  AuthFlow({required this.config, required SessionService session, required LocaleService locale})
      : _session = session,
        _locale = locale;

  final AuthFlowConfig config;
  final SessionService _session;
  final LocaleService _locale;
  StreamSubscription<SessionEvent>? _sub;
  Worker? _statusWorker;
  final _afterSignInHooks = <Future<void> Function(Me me)>[];

  /// Extra work after sign-in that never decides navigation (push token registration …).
  void onSignedIn(Future<void> Function(Me me) hook) => _afterSignInHooks.add(hook);

  @override
  void onInit() {
    super.onInit();
    _sub = _session.events.listen(_onEvent);
    _statusWorker = ever<SessionStatus>(_session.status, (s) {
      if (s == SessionStatus.mustChangePassword && Get.currentRoute != AuthRoutes.changePassword) {
        unawaited(Get.offAllNamed<void>(AuthRoutes.changePassword));
      }
    });
  }

  void _onEvent(SessionEvent e) {
    switch (e) {
      case SessionEnded(:final reason):
        unawaited(Get.offAllNamed<void>(AuthRoutes.login, arguments: LoginArgs(message: endedMessage(reason))));
      case UpdateRequired():
        unawaited(Get.offAllNamed<void>(AuthRoutes.forceUpdate));
      case TokenRefreshed():
        break;
    }
  }

  static const wrongApp = ApiError(status: 403, code: 'WRONG_CLIENT_APP', ar: '', en: '');

  /// Text shown on the login screen after the session ended.
  static String? endedMessage(ApiError? reason) {
    if (reason == null) return null;
    if (reason.code == 'WRONG_CLIENT_APP') return 'wrong_app'.tr;
    if (reason.code == 'DEVICE_BLOCKED' || reason.code == 'DEVICE_INVALID' || reason.code == 'ACCOUNT_DISABLED') {
      return reason.message(currentLang());
    }
    return 'session_ended'.tr;
  }

  /// After tokens are stored: profile, language, role check, hooks, then the right screen.
  /// Throws [ApiError] when the profile cannot be loaded.
  Future<void> completeSignIn() async {
    final me = await _session.loadMe();
    if (!config.roleAllowed(me)) {
      // The SessionEnded event carries the reason to the login screen.
      await _session.signOut(reason: wrongApp);
      return;
    }
    await _locale.set(me.preferredLanguage);
    if (_session.status.value == SessionStatus.mustChangePassword) {
      await Get.offAllNamed<void>(AuthRoutes.changePassword);
      return;
    }
    await openHome(me, freshLogin: true);
  }

  /// Opens home (or the app's override) for a signed-in user. Also used after an offline restore.
  Future<void> openHome(Me me, {required bool freshLogin}) async {
    for (final hook in _afterSignInHooks) {
      unawaited(hook(me).catchError((Object _) {}));
    }
    _log('afterSignIn(freshLogin: $freshLogin)');
    final override = await config.afterSignIn?.call(me, freshLogin: freshLogin);
    _log('open ${override ?? config.homeRoute}');
    await Get.offAllNamed<void>(override ?? config.homeRoute);
  }

  /// Decides the first screen after the splash.
  Future<void> start() async {
    await _session.restore();
    _log('restored: ${_session.status.value.name}');
    switch (_session.status.value) {
      case SessionStatus.signedOut || SessionStatus.unknown:
        await Get.offAllNamed<void>(AuthRoutes.login);
      case SessionStatus.mustChangePassword:
        await Get.offAllNamed<void>(AuthRoutes.changePassword);
      case SessionStatus.signedIn:
        final me = _session.me.value;
        if (me != null) {
          await _locale.set(me.preferredLanguage);
          _log('locale ${_locale.lang}');
          await openHome(me, freshLogin: false);
          return;
        }
        try {
          await completeSignIn();
        } on Object {
          // No cached profile and no network: nothing safe to show, so sign in again.
          await _session.signOut(callServer: false);
        }
    }
  }

  static void _log(String m) {
    if (kDebugMode) debugPrint('[auth] $m');
  }

  @override
  void onClose() {
    unawaited(_sub?.cancel());
    _statusWorker?.dispose();
    super.onClose();
  }
}
