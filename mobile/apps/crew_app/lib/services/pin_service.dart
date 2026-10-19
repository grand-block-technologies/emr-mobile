import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:emr_core/emr_core.dart';
import 'package:get/get.dart';

/// Result of checking a PIN on the phone.
enum PinCheck { ok, wrong, locked, notSet }

/// Offline unlock with the crew PIN. Only a salted PBKDF2-HMAC-SHA256 verifier is stored,
/// never the PIN. Mirrors the server rule: 5 wrong tries lock it for 15 minutes.
class PinService extends GetxService {
  PinService(this._secure, {DateTime Function()? now, this.iterations = 20000}) : _now = now ?? DateTime.now;

  final SecureStore _secure;
  final DateTime Function() _now;
  final int iterations;

  static const maxTries = 5;
  static const lockFor = Duration(minutes: 15);

  Future<Map<String, dynamic>?> _read() async {
    final raw = await _secure.read(SecureKeys.pinVerifier);
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _write(Map<String, dynamic> v) => _secure.write(SecureKeys.pinVerifier, jsonEncode(v));

  Future<bool> hasVerifier() async => (await _read()) != null;

  /// Saves a verifier after the server accepted the PIN (set or verify).
  Future<void> remember(String pin) async {
    final salt = _randomBytes(16);
    await _write({
      'salt': base64Encode(salt),
      'iter': iterations,
      'hash': base64Encode(pbkdf2(utf8.encode(pin), salt, iterations)),
      'fails': 0,
      'lockedUntil': null,
    });
  }

  /// When the local lock ends, or null when not locked.
  Future<DateTime?> lockedUntil() async {
    final v = await _read();
    final until = DateTime.tryParse(v?['lockedUntil'] as String? ?? '');
    return until != null && until.isAfter(_now().toUtc()) ? until : null;
  }

  Future<PinCheck> check(String pin) async {
    final v = await _read();
    if (v == null) return PinCheck.notSet;
    if (await lockedUntil() != null) return PinCheck.locked;
    final salt = base64Decode(v['salt'] as String);
    final expected = base64Decode(v['hash'] as String);
    final actual = pbkdf2(utf8.encode(pin), salt, v['iter'] as int);
    if (_constantTimeEquals(expected, actual)) {
      await _write({...v, 'fails': 0, 'lockedUntil': null});
      return PinCheck.ok;
    }
    final fails = (v['fails'] as int? ?? 0) + 1;
    final locked = fails >= maxTries;
    await _write({
      ...v,
      'fails': locked ? 0 : fails,
      'lockedUntil': locked ? _now().toUtc().add(lockFor).toIso8601String() : null,
    });
    return locked ? PinCheck.locked : PinCheck.wrong;
  }

  Future<int> failures() async => (await _read())?['fails'] as int? ?? 0;

  static Uint8List _randomBytes(int n) {
    final r = Random.secure();
    return Uint8List.fromList(List<int>.generate(n, (_) => r.nextInt(256)));
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

/// PBKDF2-HMAC-SHA256 (RFC 8018), one 32-byte block.
Uint8List pbkdf2(List<int> password, List<int> salt, int iterations) {
  final hmac = Hmac(sha256, password);
  var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
  final out = Uint8List.fromList(u);
  for (var i = 1; i < iterations; i++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < out.length; j++) {
      out[j] ^= u[j];
    }
  }
  return out;
}
