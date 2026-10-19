import 'package:uuid/uuid.dart';

/// Idempotency keys: one per user action, reused unchanged on every retry.
/// Server rule: `[A-Za-z0-9._:-]`, at most 128 characters.
abstract final class IdempotencyKey {
  static const _uuid = Uuid();
  static final _valid = RegExp(r'^[A-Za-z0-9._:-]{1,128}$');

  static String create() => _uuid.v4();

  static bool isValid(String key) => _valid.hasMatch(key);
}
