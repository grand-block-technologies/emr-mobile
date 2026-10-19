import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Small secrets: tokens, device id, PIN verifier, the cache encryption key.
abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Keychain (iOS) / Keystore-backed storage (Android).
class FlutterSecureStore implements SecureStore {
  FlutterSecureStore([FlutterSecureStorage? storage])
      : _s = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
            );

  final FlutterSecureStorage _s;

  @override
  Future<String?> read(String key) => _s.read(key: key);

  @override
  Future<void> write(String key, String value) => _s.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _s.delete(key: key);
}

/// In-memory store for tests and previews.
class MemorySecureStore implements SecureStore {
  MemorySecureStore([Map<String, String>? seed]) : values = {...?seed};

  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// Keys used across the app, in one place so a wipe cannot miss one.
abstract final class SecureKeys {
  /// Survives logout and wipes: the account is bound to this install.
  static const deviceId = 'device_id';
  static const refreshToken = 'refresh_token';
  static const me = 'me_json';
  static const pinVerifier = 'pin_verifier';
  static const cacheKey = 'cache_aes_key';

  /// Everything a sign-out removes. [deviceId] and [cacheKey] stay (the cache itself is cleared).
  static const sessionKeys = [refreshToken, me, pinVerifier];
}
