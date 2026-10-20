import 'package:intl/intl.dart';

/// Phones are stored and sent as `+249` + 9 digits (BR-11) and shown the way they are dialled.
abstract final class Phone {
  static final _digits = RegExp(r'\D');

  /// Normalises user input to E.164 (`+2499XXXXXXXX`). Accepts `09…`, `9…`, `2499…`, `+2499…`,
  /// with spaces or dashes. Returns null when it is not a Sudan mobile number.
  static String? toE164(String input) {
    var d = input.replaceAll(_digits, '');
    if (d.startsWith('00249')) d = d.substring(5);
    if (d.startsWith('249')) d = d.substring(3);
    if (d.startsWith('0')) d = d.substring(1);
    if (d.length != 9 || !(d.startsWith('9') || d.startsWith('1'))) return null;
    return '+249$d';
  }

  /// `+249999964082` → `0999964082`.
  static String dialled(String e164) => e164.startsWith('+249') ? '0${e164.substring(4)}' : e164;

  /// `+249 ••••••102` for lists where the person is not being handled.
  static String masked(String e164) =>
      e164.length < 3 ? e164 : '+249 ••••••${e164.substring(e164.length - 3)}';
}

/// Times are UTC on the wire and shown in Sudan time, UTC+2 (BR-10). Sudan has no DST.
abstract final class SudanTime {
  static const offset = Duration(hours: 2);

  static DateTime local(DateTime t) => t.toUtc().add(offset);

  /// `14:05` (24 h, always Latin digits so it reads the same inside Arabic text).
  static String clock(DateTime t) => DateFormat('HH:mm', 'en').format(local(t));

  /// `15 Oct 2026 · 14:05` / `15 أكتوبر 2026 · 14:05`. Digits are always Latin so dates read the
  /// same as clocks and case numbers (the Arabic locale would otherwise use Arabic-Indic digits).
  ///
  /// In Arabic the whole string is one right-to-left isolate, so it reads `20 أكتوبر 2026 · 14:52`
  /// even when the surrounding widget forces left-to-right (case numbers and clocks do that).
  static String dateTime(DateTime t, String lang) {
    final text = '${latinDigits(DateFormat('d MMM yyyy', lang == 'ar' ? 'ar' : 'en').format(local(t)))} · ${clock(t)}';
    return lang == 'ar' ? '\u2067$text\u2069' : text;
  }

  /// Clock only when [t] is today in Sudan, otherwise date and clock.
  static String when(DateTime t, DateTime now, String lang) {
    final a = local(t), b = local(now);
    return a.year == b.year && a.month == b.month && a.day == b.day ? clock(t) : dateTime(t, lang);
  }

  /// Short relative age for "updated 3 min ago". [now] is injectable for tests.
  static ({int value, String unit}) age(DateTime t, DateTime now) {
    final d = now.toUtc().difference(t.toUtc());
    if (d.inMinutes < 1) return (value: d.inSeconds.clamp(0, 59), unit: 's');
    if (d.inHours < 1) return (value: d.inMinutes, unit: 'm');
    if (d.inDays < 1) return (value: d.inHours, unit: 'h');
    return (value: d.inDays, unit: 'd');
  }
}

/// ISO-8601 UTC with second precision and a `Z`, as the server expects.
String isoUtc(DateTime t) => '${t.toUtc().toIso8601String().split('.').first}Z';

/// Arabic-Indic (٠–٩) and Persian (۰–۹) digits → 0–9.
String latinDigits(String s) => s.replaceAllMapped(RegExp('[\u0660-\u0669\u06F0-\u06F9]'), (m) {
      final c = m.group(0)!.codeUnitAt(0);
      return String.fromCharCode(0x30 + (c >= 0x06F0 ? c - 0x06F0 : c - 0x0660));
    });
