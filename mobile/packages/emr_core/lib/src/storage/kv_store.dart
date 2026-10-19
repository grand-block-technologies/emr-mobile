import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:hive_ce/hive.dart';

import 'secure_store.dart';

/// JSON key-value store for cached data (job, shift, profile, outbox).
abstract interface class KeyValueStore {
  Future<Object?> get(String key);
  Future<void> put(String key, Object? value);
  Future<void> delete(String key);

  /// Keys in insertion-independent sorted order.
  Future<List<String>> keys();
  Future<void> clear();
}

class MemoryKeyValueStore implements KeyValueStore {
  final Map<String, Object?> values = {};

  @override
  Future<Object?> get(String key) async => values[key] == null ? null : jsonDecode(jsonEncode(values[key]));

  @override
  Future<void> put(String key, Object? value) async => values[key] = jsonDecode(jsonEncode(value));

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<List<String>> keys() async => values.keys.toList()..sort();

  @override
  Future<void> clear() async => values.clear();
}

/// Hive CE box encrypted with AES-256. The key lives in [SecureStore]; values are JSON strings,
/// so no type adapters are needed and the schema can evolve freely.
class HiveKeyValueStore implements KeyValueStore {
  HiveKeyValueStore._(this._box);

  final Box<String> _box;

  /// Call `Hive.init(dir)` (or `Hive.initFlutter`) first.
  static Future<HiveKeyValueStore> open(String name, SecureStore secure) async {
    final cipher = HiveAesCipher(await _key(secure));
    return HiveKeyValueStore._(await Hive.openBox<String>(name, encryptionCipher: cipher));
  }

  static Future<Uint8List> _key(SecureStore secure) async {
    final existing = await secure.read(SecureKeys.cacheKey);
    if (existing != null) return base64Decode(existing);
    final r = Random.secure();
    final key = Uint8List.fromList(List<int>.generate(32, (_) => r.nextInt(256)));
    await secure.write(SecureKeys.cacheKey, base64Encode(key));
    return key;
  }

  @override
  Future<Object?> get(String key) async {
    final s = _box.get(key);
    return s == null ? null : jsonDecode(s);
  }

  @override
  Future<void> put(String key, Object? value) => _box.put(key, jsonEncode(value));

  @override
  Future<void> delete(String key) => _box.delete(key);

  @override
  Future<List<String>> keys() async => _box.keys.cast<String>().toList()..sort();

  @override
  Future<void> clear() async {
    await _box.clear();
    await _box.compact();
  }
}
