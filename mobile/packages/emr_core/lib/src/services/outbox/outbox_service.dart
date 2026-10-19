import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../api/api_error.dart';
import '../../storage/kv_store.dart';
import 'outbox_item.dart';

/// A queued write the server refused for good (4xx). The crew must be told.
class OutboxFailure {
  const OutboxFailure(this.item, this.error);
  final OutboxItem item;
  final ApiError error;
}

/// A queued write the server accepted (or replayed from its idempotency record).
class OutboxDone {
  const OutboxDone(this.item, this.data);
  final OutboxItem item;
  final Object? data;
}

/// Snapshot for the sync banner: "Online · all sent", "Offline · 3 waiting", "Sending 2 of 3".
class SyncState {
  const SyncState({this.pending = 0, this.sendingIndex = 0, this.sendingTotal = 0, this.blocked = false});

  final int pending;

  /// 1-based position of the item in flight, or 0 when idle.
  final int sendingIndex;
  final int sendingTotal;

  /// The last attempt hit a network/5xx/429 error; waiting to retry.
  final bool blocked;

  bool get isSending => sendingIndex > 0;
  bool get allSent => pending == 0;
}

/// Ordered, persistent, idempotent queue for crew writes (NFR-05: nothing lost or doubled).
///
/// * Items are sent strictly in order; a retryable failure stops the queue so order is kept.
/// * Every retry reuses the item's key and body. The body is frozen after the first attempt.
/// * A 4xx is permanent: the item is dropped and reported on [failures].
/// * `{ref:name}` placeholders let a later item use an earlier item's server id.
class OutboxService extends GetxService {
  OutboxService({
    required KeyValueStore store,
    required Dio Function() dio,
    DateTime Function()? now,
    List<Duration>? backoff,
  })  : _store = store,
        _dio = dio,
        _now = now ?? DateTime.now,
        _backoff = backoff ?? const [Duration(seconds: 5), Duration(seconds: 15), Duration(seconds: 30), Duration(seconds: 60)];

  static const _itemPrefix = 'item:';
  static const _refPrefix = 'ref:';
  static const _seqKey = 'meta:seq';
  static const maxGpsBatch = 500;

  final KeyValueStore _store;
  final Dio Function() _dio;
  final DateTime Function() _now;
  final List<Duration> _backoff;
  static const _uuid = Uuid();

  final items = <OutboxItem>[].obs;
  final sync = const SyncState().obs;
  final _failures = StreamController<OutboxFailure>.broadcast();
  final _done = StreamController<OutboxDone>.broadcast();
  final Map<String, String> _refs = {};

  Stream<OutboxFailure> get failures => _failures.stream;
  Stream<OutboxDone> get completed => _done.stream;

  int _seq = 0;
  bool _loaded = false;
  Future<void>? _flushing;
  Timer? _retryTimer;
  int _retryStep = 0;

  /// Reads the queue from disk. Safe to call more than once.
  Future<void> load() async {
    if (_loaded) return;
    final loaded = <OutboxItem>[];
    for (final k in await _store.keys()) {
      final v = await _store.get(k);
      if (k.startsWith(_itemPrefix) && v is Map) {
        loaded.add(OutboxItem.fromJson(Map<String, dynamic>.from(v)));
      } else if (k.startsWith(_refPrefix) && v is String) {
        _refs[k.substring(_refPrefix.length)] = v;
      }
    }
    loaded.sort((a, b) => a.seq.compareTo(b.seq));
    _seq = (await _store.get(_seqKey) as int?) ?? (loaded.isEmpty ? 0 : loaded.last.seq);
    items.assignAll(loaded);
    _loaded = true;
    _publish();
  }

  /// Queues a write and tries to send it. Returns the item (its [OutboxItem.key] is the idempotency key).
  Future<OutboxItem> add(
    OutboxKind kind,
    String path,
    Object? body, {
    String method = 'POST',
    String? resultRef,
  }) async {
    await load();
    final item = OutboxItem(
      seq: ++_seq,
      key: _uuid.v4(),
      kind: kind,
      method: method,
      path: path,
      body: body,
      createdAt: _now().toUtc(),
      resultRef: resultRef,
    );
    await _store.put(_seqKey, _seq);
    await _persist(item);
    items.add(item);
    _publish();
    unawaited(flush());
    return item;
  }

  /// Queues GPS points, appending to the last unsent GPS batch when it has room,
  /// so a day offline does not become thousands of tiny requests.
  Future<void> addGps(List<Map<String, dynamic>> points) async {
    if (points.isEmpty) return;
    await load();
    var rest = points;
    final last = items.isEmpty ? null : items.last;
    if (last != null && last.kind == OutboxKind.gps && last.attempts == 0 && !_isInFlight(last)) {
      final batch = List<Object?>.from(last.body! as List);
      final room = maxGpsBatch - batch.length;
      if (room > 0) {
        batch.addAll(rest.take(room));
        last.body = batch;
        await _persist(last);
        rest = rest.skip(room).toList();
      }
    }
    while (rest.isNotEmpty) {
      await add(OutboxKind.gps, '/api/v1/crew/gps', rest.take(maxGpsBatch).toList());
      rest = rest.skip(maxGpsBatch).toList();
    }
    _publish();
  }

  OutboxItem? _inFlight;
  bool _isInFlight(OutboxItem i) => identical(_inFlight, i);

  /// The server id saved for a `{ref:name}`, once its item has been sent.
  String? refValue(String name) => _refs[name];

  /// Sends queued items in order. Concurrent calls share one run.
  Future<void> flush() => _flushing ??= _run().whenComplete(() => _flushing = null);

  Future<void> _run() async {
    await load();
    _retryTimer?.cancel();
    final total = items.length;
    var index = 0;
    while (items.isNotEmpty) {
      final item = items.first;
      index++;
      _inFlight = item;
      sync.value = SyncState(pending: items.length, sendingIndex: index, sendingTotal: total > index ? total : index);

      final path = OutboxRef.resolve(item.path, _refs);
      final body = OutboxRef.resolve(item.body, _refs);
      if (!path.ok || !body.ok) {
        // The item this one depends on was refused, so this one can never succeed.
        await _drop(item, const ApiError(
          status: 424,
          code: 'DEPENDENCY_FAILED',
          ar: 'لم يُرسل لأن عملية سابقة رُفضت',
          en: 'Not sent because an earlier change was refused',
        ));
        continue;
      }

      item.attempts++;
      await _persist(item);
      try {
        final res = await _dio().request<Object?>(
          path.value! as String,
          data: body.value,
          options: Options(method: item.method, headers: {'Idempotency-Key': item.key}),
        );
        await _complete(item, res.data);
        _retryStep = 0;
      } on DioException catch (e) {
        final err = ApiError.of(e);
        if (e.type == DioExceptionType.connectionError) {
          // Never connected, so the server cannot have seen this body: it may still be extended.
          item.attempts--;
          await _persist(item);
        }
        if (err.isRetryable || err.status == 401) {
          // Offline, server busy, or the session is being refreshed: keep order and retry later.
          _inFlight = null;
          sync.value = SyncState(pending: items.length, blocked: true);
          _scheduleRetry();
          return;
        }
        await _drop(item, err);
      }
    }
    _inFlight = null;
    _publish();
  }

  Future<void> _complete(OutboxItem item, Object? data) async {
    if (item.resultRef != null && data is Map && data['id'] != null) {
      _refs[item.resultRef!] = '${data['id']}';
      await _store.put('$_refPrefix${item.resultRef}', '${data['id']}');
    }
    await _remove(item);
    _done.add(OutboxDone(item, data));
  }

  Future<void> _drop(OutboxItem item, ApiError error) async {
    await _remove(item);
    _failures.add(OutboxFailure(item, error));
  }

  Future<void> _remove(OutboxItem item) async {
    await _store.delete(_keyOf(item));
    items.remove(item);
    if (_isInFlight(item)) _inFlight = null;
  }

  void _scheduleRetry() {
    final delay = _backoff[_retryStep.clamp(0, _backoff.length - 1)];
    _retryStep++;
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () => unawaited(flush()));
  }

  /// Call when connectivity returns or the app resumes: retry at once, reset backoff.
  void nudge() {
    _retryStep = 0;
    if (items.isNotEmpty) unawaited(flush());
  }

  /// Wipes the queue and saved refs (sign-out, lost phone). Patient data must not outlive the session.
  Future<void> clear() async {
    _retryTimer?.cancel();
    items.clear();
    _refs.clear();
    _seq = 0;
    await _store.clear();
    _publish();
  }

  void _publish() => sync.value = SyncState(pending: items.length, blocked: sync.value.blocked && items.isNotEmpty);

  String _keyOf(OutboxItem i) => '$_itemPrefix${i.seq.toString().padLeft(12, '0')}';
  Future<void> _persist(OutboxItem i) => _store.put(_keyOf(i), i.toJson());

  @override
  void onClose() {
    _retryTimer?.cancel();
    unawaited(_failures.close());
    unawaited(_done.close());
    super.onClose();
  }
}
