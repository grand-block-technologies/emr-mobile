import 'dart:async';

import 'package:emr_core/emr_core.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../app/crew_routes.dart';

/// App lock: the crew PIN is asked on a restored session and after [idleLock] in the background.
class LockService extends GetxService {
  LockService({required SessionService session, DateTime Function()? now, this.idleLock = const Duration(minutes: 10)})
      : _session = session,
        _now = now ?? DateTime.now;

  final SessionService _session;
  final DateTime Function() _now;
  final Duration idleLock;

  final locked = true.obs;
  DateTime? _hiddenAt;
  AppLifecycleListener? _listener;

  @override
  void onInit() {
    super.onInit();
    _listener = AppLifecycleListener(onHide: onHidden, onShow: onShown);
  }

  void unlock() => locked.value = false;
  void lock() => locked.value = true;

  @visibleForTesting
  void onHidden() => _hiddenAt = _now();

  @visibleForTesting
  void onShown() {
    final at = _hiddenAt;
    _hiddenAt = null;
    if (at == null || !_session.isSignedIn || locked.value) return;
    if (_now().difference(at) >= idleLock) {
      lock();
      unawaited(Get.toNamed<void>(CrewRoutes.pinUnlock));
    }
  }

  @override
  void onClose() {
    _listener?.dispose();
    super.onClose();
  }
}

/// Sends every crew screen to the PIN unlock while the app is locked.
class LockGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) =>
      Get.find<LockService>().locked.value ? const RouteSettings(name: CrewRoutes.pinUnlock) : null;
}
