import 'format.dart';

/// Client-side checks mirroring the server rules, so most mistakes never leave the phone.
/// Each returns a translation key on failure, or null when valid.
abstract final class Validators {
  static String? required(String? v) => (v == null || v.trim().isEmpty) ? 'v_required' : null;

  /// 8–72 characters with at least one letter and one digit.
  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'v_required';
    if (v.length < 8 || v.length > 72) return 'v_password_length';
    if (!RegExp(r'[A-Za-z؀-ۿ]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) return 'v_password_mix';
    return null;
  }

  static String? smsCode(String? v) => RegExp(r'^\d{6}$').hasMatch(v ?? '') ? null : 'v_sms_code';

  /// National ID: 6–15 digits.
  static String? nationalId(String? v) => RegExp(r'^\d{6,15}$').hasMatch(v?.trim() ?? '') ? null : 'v_national_id';

  /// Crew PIN: 4–8 digits.
  static String? pin(String? v) => RegExp(r'^\d{4,8}$').hasMatch(v ?? '') ? null : 'v_pin';

  static String? sudanPhone(String? v) => Phone.toE164(v ?? '') == null ? 'v_phone' : null;

  static String? maxLength(String? v, int max) => (v ?? '').length > max ? 'v_too_long' : null;
}

/// Hard limits (the server rejects outside them with `400 DATABASE_RULE`) and the normal
/// adult range (outside it the paramedic must confirm the value, AMS-03).
class VitalRange {
  const VitalRange(this.min, this.max, this.normalMin, this.normalMax);

  final num min;
  final num max;
  final num normalMin;
  final num normalMax;

  bool allowed(num v) => v >= min && v <= max;
  bool unusual(num v) => v < normalMin || v > normalMax;
}

abstract final class Vitals {
  static const heartRate = VitalRange(20, 250, 50, 120);
  static const respRate = VitalRange(2, 80, 10, 24);
  static const spo2 = VitalRange(40, 100, 92, 100);
  static const systolic = VitalRange(40, 300, 90, 180);
  static const diastolic = VitalRange(20, 200, 50, 110);
  static const temperatureC = VitalRange(25, 45, 35.5, 38.5);
  static const bloodGlucoseMmol = VitalRange(0.5, 60, 3.5, 11);
  static const painScore = VitalRange(0, 10, 0, 10);

  static const consciousness = ['A', 'C', 'V', 'P', 'U'];

  static const byField = {
    'heartRate': heartRate,
    'respRate': respRate,
    'spo2': spo2,
    'systolic': systolic,
    'diastolic': diastolic,
    'temperatureC': temperatureC,
    'bloodGlucoseMmol': bloodGlucoseMmol,
    'painScore': painScore,
  };

  /// Validates a full entry. Returns field → translation key for hard errors.
  static Map<String, String> errors(Map<String, num?> values) {
    final out = <String, String>{};
    values.forEach((field, v) {
      final r = byField[field];
      if (v != null && r != null && !r.allowed(v)) out[field] = 'v_out_of_range';
    });
    final s = values['systolic'];
    final d = values['diastolic'];
    if (s != null && d != null && d >= s && !out.containsKey('diastolic')) out['diastolic'] = 'v_diastolic_below_systolic';
    return out;
  }

  /// Fields with a plausible but unusual value that the paramedic must confirm.
  static List<String> unusual(Map<String, num?> values) => [
        for (final e in values.entries)
          if (e.value != null && byField[e.key] != null && byField[e.key]!.allowed(e.value!) && byField[e.key]!.unusual(e.value!))
            e.key,
      ];
}
