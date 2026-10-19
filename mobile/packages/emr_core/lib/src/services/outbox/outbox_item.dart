/// What a queued write is, for the sync banner and for reacting to results.
enum OutboxKind { confirm, status, alert, gps, patient, observation, treatment, other }

/// One queued write, saved to disk as path + JSON body (not as a Retrofit call),
/// sent later through the shared Dio so it gets the same token and refresh handling.
class OutboxItem {
  OutboxItem({
    required this.seq,
    required this.key,
    required this.kind,
    required this.path,
    required this.createdAt,
    this.method = 'POST',
    this.body,
    this.resultRef,
    this.attempts = 0,
  });

  factory OutboxItem.fromJson(Map<String, dynamic> j) => OutboxItem(
        seq: j['seq'] as int,
        key: j['key'] as String,
        kind: OutboxKind.values.firstWhere((k) => k.name == j['kind'], orElse: () => OutboxKind.other),
        method: j['method'] as String? ?? 'POST',
        path: j['path'] as String,
        body: j['body'],
        createdAt: DateTime.parse(j['createdAt'] as String),
        resultRef: j['resultRef'] as String?,
        attempts: j['attempts'] as int? ?? 0,
      );

  /// Monotonic order on this device. Items are sent strictly in this order.
  final int seq;

  /// `Idempotency-Key`: one per user action, identical on every retry.
  final String key;
  final OutboxKind kind;
  final String method;

  /// May contain `{ref:<name>}` placeholders resolved from earlier items' results.
  final String path;

  /// JSON-encodable. String values may contain `{ref:<name>}` placeholders too.
  Object? body;
  final DateTime createdAt;

  /// When set, the `id` in this item's response is saved under this name for later items.
  final String? resultRef;

  /// Send attempts so far. A body may only change while this is 0 (same key, same body rule).
  int attempts;

  Map<String, dynamic> toJson() => {
        'seq': seq,
        'key': key,
        'kind': kind.name,
        'method': method,
        'path': path,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'resultRef': resultRef,
        'attempts': attempts,
      };
}

/// `{ref:name}` placeholder helpers.
abstract final class OutboxRef {
  static final _pattern = RegExp(r'\{ref:([A-Za-z0-9._:-]+)\}');

  static String placeholder(String name) => '{ref:$name}';

  /// Replaces placeholders in [value] (string, list or map, recursively).
  /// `ok` is false when a placeholder has no resolved id.
  static ({bool ok, Object? value}) resolve(Object? value, Map<String, String> refs) {
    var missing = false;
    Object? walk(Object? v) {
      if (v is String) {
        return v.replaceAllMapped(_pattern, (m) {
          final id = refs[m.group(1)];
          if (id == null) missing = true;
          return id ?? m.group(0)!;
        });
      }
      if (v is List) return v.map(walk).toList();
      if (v is Map) return v.map((k, e) => MapEntry(k, walk(e)));
      return v;
    }

    final out = walk(value);
    return (ok: !missing, value: out);
  }
}
