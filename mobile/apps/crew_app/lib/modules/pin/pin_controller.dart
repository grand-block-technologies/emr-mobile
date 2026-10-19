import 'package:emr_core/emr_core.dart';
import 'package:get/get.dart';

import '../../app/crew_routes.dart';
import '../../data/crew_repository.dart';
import '../../services/lock_service.dart';
import '../../services/pin_service.dart';

enum PinMode {
  /// First sign-in on this phone: set a new PIN, or prove the one you already have.
  setup,

  /// App lock: unlock with the PIN (server when reachable, local verifier when offline).
  unlock,
}

class PinController extends GetxController with FormStatus {
  PinController({
    required this.mode,
    required CrewRepository repo,
    required PinService pins,
    required LockService lock,
    required SessionService session,
  })  : _repo = repo,
        _pins = pins,
        _lock = lock,
        _session = session;

  final PinMode mode;
  final CrewRepository _repo;
  final PinService _pins;
  final LockService _lock;
  final SessionService _session;

  /// In setup: true = "I already have a PIN" (verify), false = "set a new PIN".
  final haveExisting = false.obs;
  final message = RxnString();

  Future<void> submit(String pin, {String? repeat}) async {
    if (busy.value) return;
    clearErrors();
    message.value = null;
    final checks = {'pin': Validators.pin(pin)};
    final setting = mode == PinMode.setup && !haveExisting.value;
    if (setting) checks['repeat'] = pin == repeat ? null : 'pin_mismatch';
    if (!applyLocal(checks)) return;

    busy.value = true;
    try {
      if (setting) {
        await _repo.setPin(pin);
      } else {
        await _repo.verifyPin(pin);
      }
      await _pins.remember(pin);
      await _done();
    } on Object catch (e) {
      final err = ApiError.of(e);
      // Server unreachable or failing (offline, 5xx, tunnel down): unlock with the phone's verifier.
      // Real refusals (PIN_INVALID, PIN_LOCKED) still come from the server.
      if (err.isRetryable && mode == PinMode.unlock) {
        await _offlineCheck(pin);
      } else {
        showApiError(err);
      }
    } finally {
      busy.value = false;
    }
  }

  Future<void> _offlineCheck(String pin) async {
    switch (await _pins.check(pin)) {
      case PinCheck.ok:
        await _done();
      case PinCheck.wrong:
        message.value = 'pin_wrong_left'.trParams({'n': '${PinService.maxTries - await _pins.failures()}'});
      case PinCheck.locked:
        final until = await _pins.lockedUntil();
        message.value = 'pin_locked_until'.trParams({'t': until == null ? '' : SudanTime.clock(until)});
      case PinCheck.notSet:
        message.value = 'pin_offline_not_set'.tr;
    }
  }

  Future<void> _done() async {
    _lock.unlock();
    await Get.offAllNamed<void>(CrewRoutes.home);
  }

  Future<void> signOut() => _session.signOut();
}
