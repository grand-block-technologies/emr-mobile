import 'package:emr_core/emr_core.dart';
import 'package:get/get.dart';

import '../../data/citizen_repository.dart';

/// Two steps: phone → SMS code + identity + password. Then the user signs in with the phone.
class SignUpController extends GetxController with FormStatus {
  SignUpController({required CitizenRepository repo}) : _repo = repo;

  final CitizenRepository _repo;
  final challengeId = RxnString();
  final accountExists = false.obs;
  String phone = '';

  bool get codeSent => challengeId.value != null;

  Future<void> start(String input) async {
    if (busy.value) return;
    clearErrors();
    accountExists.value = false;
    final e164 = Phone.toE164(input);
    if (!applyLocal({'phone': e164 == null ? 'v_phone' : null})) return;
    busy.value = true;
    try {
      phone = e164!;
      challengeId.value = (await _repo.signUpStart(phone)).challengeId;
    } on Object catch (e) {
      _show(ApiError.of(e));
    } finally {
      busy.value = false;
    }
  }

  Future<bool> finish({
    required String code,
    required String nationalId,
    required String fullNameAr,
    required String fullNameEn,
    required String password,
    required String repeat,
  }) async {
    final id = challengeId.value;
    if (busy.value || id == null) return false;
    clearErrors();
    final ok = applyLocal({
      'code': Validators.smsCode(code.trim()),
      'nationalId': Validators.nationalId(nationalId),
      'fullNameAr': Validators.arabicName(fullNameAr),
      'password': Validators.password(password),
      'repeat': password == repeat ? null : 'v_password_match',
    });
    if (!ok) return false;
    busy.value = true;
    try {
      await _repo.signUpFinish(
        SignUpFinishBody(
          challengeId: id,
          code: code.trim(),
          nationalId: nationalId.trim(),
          fullNameAr: fullNameAr.trim(),
          fullNameEn: fullNameEn.trim().isEmpty ? null : fullNameEn.trim(),
          password: password,
        ),
      );
      return true;
    } on Object catch (e) {
      _show(ApiError.of(e));
      return false;
    } finally {
      busy.value = false;
    }
  }

  void _show(ApiError e) {
    accountExists.value = e.code == 'CITIZEN_PHONE_ACCOUNT_EXISTS' || e.code == 'CITIZEN_ID_ACCOUNT_EXISTS';
    showApiError(e);
  }

  void changePhone() {
    challengeId.value = null;
    clearErrors();
  }
}
