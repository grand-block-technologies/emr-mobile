import 'package:crew_app/services/pin_service.dart';
import 'package:emr_core/emr_core.dart';
import 'package:flutter_test/flutter_test.dart';

String hex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

void main() {
  test('PBKDF2-HMAC-SHA256 matches the RFC 7914 test vector', () {
    expect(hex(pbkdf2('passwd'.codeUnits, 'salt'.codeUnits, 1)), '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc'.substring(0, 64));
    expect(hex(pbkdf2('password'.codeUnits, 'salt'.codeUnits, 1)), '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b');
    expect(hex(pbkdf2('password'.codeUnits, 'salt'.codeUnits, 2)), 'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43');
  });

  group('PinService', () {
    late MemorySecureStore secure;
    late DateTime now;
    late PinService pins;

    setUp(() {
      secure = MemorySecureStore();
      now = DateTime.utc(2026, 10, 15, 8);
      pins = PinService(secure, now: () => now, iterations: 100);
    });

    test('notSet before anything is remembered', () async {
      expect(await pins.hasVerifier(), isFalse);
      expect(await pins.check('1234'), PinCheck.notSet);
    });

    test('stores only a salted verifier, never the PIN', () async {
      await pins.remember('482915');
      final raw = secure.values[SecureKeys.pinVerifier]!;
      expect(raw.contains('482915'), isFalse);
      expect(await pins.check('482915'), PinCheck.ok);

      final again = PinService(secure, iterations: 100);
      await again.remember('482915');
      expect(secure.values[SecureKeys.pinVerifier], isNot(raw), reason: 'a fresh salt each time');
    });

    test('wrong tries count down and the fifth locks for 15 minutes', () async {
      await pins.remember('1234');
      for (var i = 1; i <= 4; i++) {
        expect(await pins.check('0000'), PinCheck.wrong);
        expect(await pins.failures(), i);
      }
      expect(await pins.check('0000'), PinCheck.locked);
      expect(await pins.check('1234'), PinCheck.locked, reason: 'even the right PIN waits out the lock');
      expect(await pins.lockedUntil(), DateTime.utc(2026, 10, 15, 8, 15));

      now = now.add(const Duration(minutes: 15, seconds: 1));
      expect(await pins.lockedUntil(), isNull);
      expect(await pins.check('1234'), PinCheck.ok);
    });

    test('a correct PIN resets the failure count', () async {
      await pins.remember('1234');
      await pins.check('9999');
      await pins.check('9999');
      expect(await pins.check('1234'), PinCheck.ok);
      expect(await pins.failures(), 0);
    });

    test('the verifier is part of the session wipe keys', () {
      expect(SecureKeys.sessionKeys, contains(SecureKeys.pinVerifier));
    });
  });
}
