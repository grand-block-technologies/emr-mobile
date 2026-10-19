import 'dart:convert';

/// Reads `exp` from a JWT without verifying it (the server verifies; we only schedule refreshes).
DateTime? jwtExpiry(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
    final exp = payload is Map ? payload['exp'] : null;
    return exp is num ? DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true) : null;
  } on FormatException {
    return null;
  }
}
