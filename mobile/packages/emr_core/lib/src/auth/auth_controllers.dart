import 'dart:async';

import 'package:get/get.dart';

import '../api/api_error.dart';
import '../i18n/locale_service.dart';
import '../models/auth_models.dart';
import '../services/session_service.dart';
import '../ui/widgets/basics.dart';
import '../util/format.dart';
import '../util/validators.dart';
import 'auth_flow.dart';
import 'auth_repository.dart';

/// Shared busy/error state for a form. `error` is a whole-form error; `fieldErrors` sit under fields.
/// Field errors are kept as translation keys / bilingual server errors and re-rendered when the
/// language changes, so switching language never leaves messages in the old one.
mixin FormStatus on GetxController {
  final busy = false.obs;
  final error = Rxn<ApiError>();
  final fieldErrors = <String, String>{}.obs;
  final _sources = <String, Object>{};
  Worker? _lang;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<LocaleService>()) _lang = ever(Get.find<LocaleService>().locale, (_) => _render());
  }

  @override
  void onClose() {
    _lang?.dispose();
    super.onClose();
  }

  void _render() => fieldErrors.assignAll(
        _sources.map((k, v) => MapEntry(k, v is FieldError ? v.message(currentLang()) : (v as String).tr)),
      );

  void clearErrors() {
    error.value = null;
    _sources.clear();
    fieldErrors.clear();
  }

  /// Puts server field errors on their fields; everything else on the form.
  void showApiError(ApiError e) {
    _sources
      ..clear()
      ..addAll({for (final f in e.fields) f.field: f});
    _render();
    error.value = e;
  }

  /// Field → translation key.
  void setFieldKeys(Map<String, String> keys) {
    _sources
      ..clear()
      ..addAll(keys);
    _render();
  }

  /// Local validation result (translation keys) → visible messages.
  bool applyLocal(Map<String, String?> checks) {
    setFieldKeys({
      for (final e in checks.entries)
        if (e.value != null) e.key: e.value!,
    });
    return fieldErrors.isEmpty;
  }
}

/// Arguments passed from login to the SMS screen.
class SmsArgs {
  const SmsArgs({required this.challengeId, required this.username, this.expiresAt});
  final String challengeId;
  final String username;
  final DateTime? expiresAt;
}

class LoginController extends GetxController with FormStatus {
  LoginController({required AuthRepository repo, required SessionService session, required AuthFlow flow})
      : _repo = repo,
        _session = session,
        _flow = flow;

  final AuthRepository _repo;
  final SessionService _session;
  final AuthFlow _flow;

  /// A message carried in from a previous session (blocked phone, session ended) or sign-up.
  final notice = RxnString();
  final noticeIsError = true.obs;
  String? prefillUsername;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is LoginArgs) {
      notice.value = args.message;
      noticeIsError.value = args.isError;
      prefillUsername = args.username;
    }
  }

  Future<void> submit(String username, String password) async {
    if (busy.value) return;
    clearErrors();
    notice.value = null;
    if (!applyLocal({'username': Validators.required(username), 'password': Validators.required(password)})) return;
    busy.value = true;
    try {
      username = _flow.config.normalizeUsername?.call(username.trim()) ?? username.trim();
      final r = await _repo.login(username, password);
      final tokens = r.tokens;
      if (tokens != null) {
        await _session.start(tokens);
        await _flow.completeSignIn();
        return;
      }
      if (r.challengeId == null) throw ApiError.unexpected;
      await Get.toNamed<void>(
        AuthRoutes.smsCode,
        arguments: SmsArgs(challengeId: r.challengeId!, username: username.trim(), expiresAt: r.expiresAt),
      );
    } on Object catch (e) {
      final err = ApiError.of(e);
      // APP_UPDATE_REQUIRED is routed by the session; nothing to show here.
      if (err.code != 'APP_UPDATE_REQUIRED') showApiError(err);
    } finally {
      busy.value = false;
    }
  }
}

class SmsCodeController extends GetxController with FormStatus {
  SmsCodeController({
    required AuthRepository repo,
    required SessionService session,
    required AuthFlow flow,
    required SmsArgs args,
    this.resendAfter = const Duration(seconds: 60),
    this.maxResends = 3,
  })  : _repo = repo,
        _session = session,
        _flow = flow,
        challengeId = args.challengeId,
        username = args.username;

  final AuthRepository _repo;
  final SessionService _session;
  final AuthFlow _flow;
  final String username;
  final Duration resendAfter;
  final int maxResends;

  String challengeId;
  final secondsLeft = 0.obs;
  final resends = 0.obs;
  final info = RxnString();
  Timer? _timer;

  bool get canResend => secondsLeft.value == 0 && resends.value < maxResends && !busy.value;

  @override
  void onInit() {
    super.onInit();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    secondsLeft.value = resendAfter.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsLeft.value <= 1) {
        secondsLeft.value = 0;
        t.cancel();
      } else {
        secondsLeft.value--;
      }
    });
  }

  Future<void> submit(String code) async {
    if (busy.value) return;
    clearErrors();
    info.value = null;
    if (!applyLocal({'code': Validators.smsCode(code.trim())})) return;
    busy.value = true;
    try {
      final t = await _repo.verify(challengeId, code);
      await _session.start(t);
      if (t.mustChangePassword) {
        await Get.offAllNamed<void>(AuthRoutes.changePassword);
        return;
      }
      await _flow.completeSignIn();
    } on Object catch (e) {
      showApiError(ApiError.of(e));
    } finally {
      busy.value = false;
    }
  }

  Future<void> resend() async {
    if (!canResend) return;
    clearErrors();
    busy.value = true;
    try {
      final c = await _repo.resend(challengeId);
      if (c.challengeId != null) challengeId = c.challengeId!;
      resends.value++;
      info.value = 'code_resent'.tr;
      _startCountdown();
    } on Object catch (e) {
      showApiError(ApiError.of(e));
    } finally {
      busy.value = false;
    }
  }

  /// Debug builds only: reads the code from `/dev/sms/latest` for the given phone.
  Future<String?> devFetchCode(String phoneInput) async {
    final phone = Phone.toE164(phoneInput) ?? phoneInput.trim();
    try {
      return await _repo.devLatestCode(phone);
    } on Object catch (e) {
      showApiError(ApiError.of(e));
      return null;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}

class ChangePasswordController extends GetxController with FormStatus {
  ChangePasswordController({required AuthRepository repo, required SessionService session, required AuthFlow flow})
      : _repo = repo,
        _session = session,
        _flow = flow;

  final AuthRepository _repo;
  final SessionService _session;
  final AuthFlow _flow;

  Future<void> submit(String oldPassword, String newPassword, String repeat) async {
    if (busy.value) return;
    clearErrors();
    final ok = applyLocal({
      'oldPassword': Validators.required(oldPassword),
      'newPassword': Validators.password(newPassword, username: _session.me.value?.username),
      'repeat': newPassword == repeat ? null : 'v_password_match',
    });
    if (!ok) return;
    busy.value = true;
    try {
      await _repo.changePassword(oldPassword, newPassword);
      _session.passwordChanged();
      showToast('password_changed'.tr);
      await _flow.completeSignIn();
    } on Object catch (e) {
      showApiError(ApiError.of(e));
    } finally {
      busy.value = false;
    }
  }

  Future<void> signOut() => _session.signOut();
}

/// Two steps: username → (SMS) code + new password.
class ForgotPasswordController extends GetxController with FormStatus {
  ForgotPasswordController({required AuthRepository repo}) : _repo = repo;

  final AuthRepository _repo;
  final challenge = Rxn<ResetRequested>();
  final done = false.obs;
  String username = '';

  bool get codeSent => challenge.value?.challengeId != null;

  Future<void> requestCode(String user) async {
    if (busy.value) return;
    clearErrors();
    if (!applyLocal({'username': Validators.required(user)})) return;
    busy.value = true;
    try {
      username = user.trim();
      challenge.value = await _repo.forgot(username);
    } on Object catch (e) {
      showApiError(ApiError.of(e));
    } finally {
      busy.value = false;
    }
  }

  /// The server's own explanation (e.g. "ask an administrator"), in the UI language.
  String? get serverMessage {
    final c = challenge.value;
    if (c == null) return null;
    return currentLang() == 'en' ? (c.messageEn ?? c.messageAr) : (c.messageAr ?? c.messageEn);
  }

  Future<void> reset(String code, String newPassword, String repeat) async {
    final id = challenge.value?.challengeId;
    if (busy.value || id == null) return;
    clearErrors();
    final ok = applyLocal({
      'code': Validators.smsCode(code.trim()),
      'newPassword': Validators.password(newPassword, username: username),
      'repeat': newPassword == repeat ? null : 'v_password_match',
    });
    if (!ok) return;
    busy.value = true;
    try {
      await _repo.reset(id, code, newPassword);
      done.value = true;
    } on Object catch (e) {
      showApiError(ApiError.of(e));
    } finally {
      busy.value = false;
    }
  }
}
