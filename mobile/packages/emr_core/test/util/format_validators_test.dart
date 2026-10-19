import 'package:emr_core/emr_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  group('Phone', () {
    test('normalises the ways people type a Sudan mobile number', () {
      for (final input in ['0912345003', '912345003', '+249912345003', '249912345003', '00249912345003', '091 234 5003', '091-234-5003']) {
        expect(Phone.toE164(input), '+249912345003', reason: input);
      }
    });

    test('rejects numbers that are not Sudan mobiles', () {
      for (final input in ['', '12345', '0812345003', '+971501234567', '09123450031']) {
        expect(Phone.toE164(input), isNull, reason: input);
      }
    });

    test('shows the dialled form and masks for waiting lists', () {
      expect(Phone.dialled('+249999964082'), '0999964082');
      expect(Phone.dialled('+971501234567'), '+971501234567');
      expect(Phone.masked('+249999990102'), '+249 ••••••102');
    });
  });

  group('SudanTime', () {
    test('shows UTC+2', () {
      expect(SudanTime.clock(DateTime.utc(2026, 10, 15, 22, 5)), '00:05');
      expect(SudanTime.local(DateTime.utc(2026, 10, 15, 7)).hour, 9);
    });

    test('age buckets', () {
      final now = DateTime.utc(2026, 10, 15, 12);
      expect(SudanTime.age(now.subtract(const Duration(seconds: 20)), now), (value: 20, unit: 's'));
      expect(SudanTime.age(now.subtract(const Duration(minutes: 3)), now), (value: 3, unit: 'm'));
      expect(SudanTime.age(now.subtract(const Duration(hours: 4)), now), (value: 4, unit: 'h'));
      expect(SudanTime.age(now.subtract(const Duration(days: 2)), now), (value: 2, unit: 'd'));
      expect(SudanTime.age(now.add(const Duration(seconds: 5)), now).value, 0, reason: 'clock skew never goes negative');
    });

    test('dates use Latin digits in Arabic; "when" drops the date for today', () {
      final t = DateTime.utc(2026, 10, 13, 8, 39);
      expect(SudanTime.dateTime(t, 'ar'), '13 أكتوبر 2026 · 10:39');
      expect(SudanTime.dateTime(t, 'en'), '13 Oct 2026 · 10:39');
      expect(SudanTime.when(t, DateTime.utc(2026, 10, 13, 20), 'en'), '10:39');
      expect(SudanTime.when(t, DateTime.utc(2026, 10, 15, 8), 'en'), '13 Oct 2026 · 10:39');
      expect(latinDigits('٠١٢٣٤٥٦٧٨٩ ۰۹'), '0123456789 09');
    });

    test('isoUtc has second precision and Z', () {
      expect(isoUtc(DateTime.utc(2026, 10, 13, 5, 44, 48, 123)), '2026-10-13T05:44:48Z');
      expect(isoUtc(DateTime.utc(2026, 10, 13, 5, 44, 48).toLocal()), '2026-10-13T05:44:48Z');
    });
  });

  group('Validators', () {
    test('password policy: 8–72, a letter and a digit', () {
      expect(Validators.password('abc12345'), isNull);
      expect(Validators.password('كلمةسر123'), isNull, reason: 'Arabic letters count as letters');
      expect(Validators.password('short1'), 'v_password_length');
      expect(Validators.password('a1${'x' * 71}'), 'v_password_length');
      expect(Validators.password('onlyletters'), 'v_password_mix');
      expect(Validators.password('12345678'), 'v_password_mix');
      expect(Validators.password(''), 'v_required');
    });

    test('codes, ids and pins', () {
      expect(Validators.smsCode('123456'), isNull);
      expect(Validators.smsCode('12345'), 'v_sms_code');
      expect(Validators.smsCode('12345a'), 'v_sms_code');
      expect(Validators.nationalId('123456'), isNull);
      expect(Validators.nationalId('123456789012345'), isNull);
      expect(Validators.nationalId('12345'), 'v_national_id');
      expect(Validators.nationalId('1234567890123456'), 'v_national_id');
      expect(Validators.pin('1234'), isNull);
      expect(Validators.pin('12345678'), isNull);
      expect(Validators.pin('123'), 'v_pin');
      expect(Validators.pin('123456789'), 'v_pin');
      expect(Validators.sudanPhone('0912345678'), isNull);
      expect(Validators.sudanPhone('123'), 'v_phone');
      expect(Validators.maxLength('x' * 2001, 2000), 'v_too_long');
    });
  });

  group('Vitals', () {
    test('hard limits match the API', () {
      expect(Vitals.errors({'heartRate': 19}), {'heartRate': 'v_out_of_range'});
      expect(Vitals.errors({'heartRate': 250, 'spo2': 40, 'temperatureC': 45, 'painScore': 0}), isEmpty);
      expect(Vitals.errors({'spo2': 101}), {'spo2': 'v_out_of_range'});
      expect(Vitals.errors({'bloodGlucoseMmol': 0.4}), {'bloodGlucoseMmol': 'v_out_of_range'});
    });

    test('diastolic must be below systolic', () {
      expect(Vitals.errors({'systolic': 120, 'diastolic': 80}), isEmpty);
      expect(Vitals.errors({'systolic': 80, 'diastolic': 80}), {'diastolic': 'v_diastolic_below_systolic'});
      expect(Vitals.errors({'systolic': 120}), isEmpty, reason: 'one value alone is allowed');
    });

    test('unusual but allowed values need a confirm', () {
      expect(Vitals.unusual({'heartRate': 140, 'spo2': 88, 'respRate': 16}), unorderedEquals(['heartRate', 'spo2']));
      expect(Vitals.unusual({'heartRate': 300}), isEmpty, reason: 'out of range is an error, not a confirm');
      expect(Vitals.unusual({'heartRate': null}), isEmpty);
    });
  });

  group('Translations', () {
    test('Arabic and English have exactly the same keys', () {
      final k = AppTranslations().keys;
      expect(k['ar']!.keys.toSet().difference(k['en']!.keys.toSet()), isEmpty);
      expect(k['en']!.keys.toSet().difference(k['ar']!.keys.toSet()), isEmpty);
    });

    test('every validator key has a translation', () {
      final en = AppTranslations().keys['en']!;
      for (final key in ['v_required', 'v_password_length', 'v_password_mix', 'v_sms_code', 'v_national_id', 'v_pin', 'v_phone', 'v_too_long', 'v_out_of_range', 'v_diastolic_below_systolic']) {
        expect(en.containsKey(key), isTrue, reason: key);
      }
    });

    test('app keys override core keys', () {
      final t = AppTranslations(extra: {
        'en': {'retry': 'Try again'},
      });
      expect(t.keys['en']!['retry'], 'Try again');
      expect(t.keys['ar']!['retry'], 'إعادة المحاولة');
    });
  });

  group('Priority', () {
    test('maps codes and keeps P3 dark text for contrast', () {
      expect(Priority.fromCode('P1'), Priority.p1);
      expect(Priority.fromCode('P9'), isNull);
      expect(Priority.p3.text.toARGB32(), 0xFF0C1114);
    });
  });
}
