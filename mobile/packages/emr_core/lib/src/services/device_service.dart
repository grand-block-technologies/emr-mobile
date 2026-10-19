import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../storage/secure_store.dart';

/// Stable `deviceId` per install. The account is bound to it, and an admin or the
/// hospital ER can block it if the phone is lost. It survives sign-out.
class DeviceService extends GetxService {
  DeviceService(this._secure);

  final SecureStore _secure;
  String? _id;

  Future<String> id() async {
    if (_id != null) return _id!;
    var v = await _secure.read(SecureKeys.deviceId);
    if (v == null) {
      v = const Uuid().v4();
      await _secure.write(SecureKeys.deviceId, v);
    }
    return _id = v;
  }
}
