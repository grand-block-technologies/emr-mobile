import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

/// Source of "is there any network". Abstract so tests can drive it.
abstract interface class ConnectivitySource {
  Future<bool> isOnline();
  Stream<bool> get changes;
}

class PlatformConnectivity implements ConnectivitySource {
  PlatformConnectivity([Connectivity? c]) : _c = c ?? Connectivity();
  final Connectivity _c;

  static bool _online(List<ConnectivityResult> r) => r.any((x) => x != ConnectivityResult.none);

  @override
  Future<bool> isOnline() async => _online(await _c.checkConnectivity());

  @override
  Stream<bool> get changes => _c.onConnectivityChanged.map(_online).distinct();
}

class FakeConnectivity implements ConnectivitySource {
  FakeConnectivity([this.online = true]);
  bool online;
  final _ctrl = StreamController<bool>.broadcast();

  void set(bool v) {
    online = v;
    _ctrl.add(v);
  }

  @override
  Future<bool> isOnline() async => online;

  @override
  Stream<bool> get changes => _ctrl.stream;
}

/// App-wide online flag. A radio link is not proof the server is reachable,
/// so features still treat `NETWORK` errors as offline.
class ConnectivityService extends GetxService {
  ConnectivityService(this._source);

  final ConnectivitySource _source;
  final online = true.obs;
  final _back = StreamController<void>.broadcast();
  StreamSubscription<bool>? _sub;

  /// Fires each time the device goes from offline to online.
  Stream<void> get backOnline => _back.stream;

  Future<ConnectivityService> init() async {
    online.value = await _source.isOnline();
    _sub = _source.changes.listen((v) {
      final was = online.value;
      online.value = v;
      if (v && !was) _back.add(null);
    });
    return this;
  }

  @override
  void onClose() {
    unawaited(_sub?.cancel());
    unawaited(_back.close());
    super.onClose();
  }
}
