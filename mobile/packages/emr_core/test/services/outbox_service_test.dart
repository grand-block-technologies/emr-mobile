import 'dart:async';

import 'package:dio/dio.dart';
import 'package:emr_core/emr_core.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_adapter.dart';

void main() {
  late FakeAdapter http;
  late Dio dio;
  late MemoryKeyValueStore store;
  late OutboxService outbox;
  late List<OutboxFailure> failures;
  late List<OutboxDone> done;

  OutboxService build() {
    final o = OutboxService(store: store, dio: () => dio, backoff: const [Duration(seconds: 5)]);
    o.failures.listen(failures.add);
    o.completed.listen(done.add);
    return o;
  }

  setUp(() {
    http = FakeAdapter();
    dio = Dio(BaseOptions(baseUrl: 'http://test', contentType: Headers.jsonContentType))..httpClientAdapter = http;
    store = MemoryKeyValueStore();
    failures = [];
    done = [];
    outbox = build();
  });

  Future<void> settle() async {
    await outbox.flush();
    await pumpEventQueue();
  }

  test('sends items in order with their idempotency key, then empties', () async {
    http.reply('POST /a', 200, {'ok': 1});
    http.reply('POST /b', 200, {'ok': 2});

    final a = await outbox.add(OutboxKind.status, '/a', {'n': 1});
    final b = await outbox.add(OutboxKind.status, '/b', {'n': 2});
    await settle();

    expect(http.requests.map((r) => r.path), ['/a', '/b']);
    expect(http.requests[0].headers['Idempotency-Key'], a.key);
    expect(http.requests[1].headers['Idempotency-Key'], b.key);
    expect(outbox.items, isEmpty);
    expect(await store.keys(), ['meta:seq']);
    expect(done.map((d) => d.item.path), ['/a', '/b']);
    expect(outbox.sync.value.allSent, isTrue);
  });

  test('offline: nothing is lost, order is kept and the same key and body are resent', () async {
    http.offline('POST /a');
    http.reply('POST /a', 200, {});
    http.reply('POST /b', 200, {});

    final a = await outbox.add(OutboxKind.status, '/a', {'status': 'en_route'});
    await outbox.add(OutboxKind.status, '/b', {'status': 'on_scene'});
    await settle();

    expect(outbox.items, hasLength(2), reason: 'both still queued after the offline attempt');
    expect(outbox.sync.value.blocked, isTrue);
    expect(http.calls('POST /b'), isEmpty, reason: '/b must wait for /a');

    outbox.nudge();
    await settle();

    final sentA = http.calls('POST /a');
    expect(sentA.map((r) => r.headers['Idempotency-Key']).toSet(), {a.key});
    final bodiesA = [for (var i = 0; i < http.requests.length; i++) if (http.requests[i].path == '/a') http.bodies[i]];
    expect(bodiesA, [
      {'status': 'en_route'},
      {'status': 'en_route'},
    ]);
    expect(http.requests.last.path, '/b');
    expect(outbox.items, isEmpty);
    expect(failures, isEmpty);
  });

  test('5xx and 429 keep the item for later; 4xx drops it and reports it', () async {
    http.reply('POST /busy', 503, errorBody('DATABASE_UNAVAILABLE'));
    await outbox.add(OutboxKind.status, '/busy', {});
    await settle();
    expect(outbox.items, hasLength(1));
    expect(failures, isEmpty);

    await outbox.clear();
    http.reply('POST /bad', 400, errorBody('STATUS_TIME_INVALID'));
    http.reply('POST /next', 200, {});
    await outbox.add(OutboxKind.status, '/bad', {});
    await outbox.add(OutboxKind.status, '/next', {});
    await settle();

    expect(failures.single.error.code, 'STATUS_TIME_INVALID');
    expect(failures.single.item.path, '/bad');
    expect(http.calls('POST /next'), hasLength(1), reason: 'a refused item must not block the queue');
    expect(outbox.items, isEmpty);
  });

  test('401 that survives the refresh is retried later, not dropped', () async {
    http.reply('POST /a', 401, errorBody('UNAUTHORIZED'));
    await outbox.add(OutboxKind.status, '/a', {});
    await settle();
    expect(outbox.items, hasLength(1));
    expect(failures, isEmpty);
  });

  test('the queue survives an app restart in order and keeps numbering', () async {
    http.fallback = (_, _) => const FakeReply.offline();
    await outbox.add(OutboxKind.status, '/one', {'i': 1});
    await outbox.add(OutboxKind.alert, '/two', {'i': 2});
    await settle();

    final restarted = build();
    await restarted.load();
    expect(restarted.items.map((i) => i.path), ['/one', '/two']);
    expect(restarted.items.first.kind, OutboxKind.status);

    final third = await restarted.add(OutboxKind.status, '/three', {});
    expect(third.seq, 3);
    expect(third.key, isNot(restarted.items.first.key));
  });

  test('a later item can use the server id of an earlier one ({ref:name})', () async {
    http.fallback = (_, _) => const FakeReply.offline();
    await outbox.add(OutboxKind.patient, '/api/v1/patients', {'fullNameAr': 'x', 'sex': 'male'}, resultRef: 'pt1');
    await outbox.add(
      OutboxKind.observation,
      '/api/v1/patients/${OutboxRef.placeholder('pt1')}/observations',
      {'observedAt': 't', 'heartRate': 80, 'note': 'for {ref:pt1}'},
    );
    await settle();
    expect(outbox.items, hasLength(2));

    http.fallback = null;
    http.reply('POST /api/v1/patients', 200, {'id': 'srv-42', 'firstRecordStatus': 'basic'});
    http.reply('POST /api/v1/patients/srv-42/observations', 200, {});
    outbox.nudge();
    await settle();

    expect(http.calls('POST /api/v1/patients/srv-42/observations'), hasLength(1));
    expect(http.bodies.last, {'observedAt': 't', 'heartRate': 80, 'note': 'for srv-42'});
    expect(outbox.refValue('pt1'), 'srv-42');
    expect(outbox.items, isEmpty);
  });

  test('items that depend on a refused item are dropped too', () async {
    http.reply('POST /api/v1/patients', 400, errorBody('VALIDATION_ERROR'));
    await outbox.add(OutboxKind.patient, '/api/v1/patients', {}, resultRef: 'pt1');
    await outbox.add(OutboxKind.observation, '/api/v1/patients/{ref:pt1}/observations', {});
    await settle();

    expect(failures.map((f) => f.error.code), ['VALIDATION_ERROR', 'DEPENDENCY_FAILED']);
    expect(http.requests, hasLength(1));
  });

  test('saved refs survive a restart', () async {
    http.reply('POST /api/v1/patients', 200, {'id': 'srv-7'});
    await outbox.add(OutboxKind.patient, '/api/v1/patients', {}, resultRef: 'pt9');
    await settle();

    final restarted = build();
    await restarted.load();
    expect(restarted.refValue('pt9'), 'srv-7');
  });

  test('concurrent flushes never send an item twice', () async {
    final gate = Completer<void>();
    http.on('POST /slow', (_, _) async {
      await gate.future;
      return const FakeReply(200, {});
    });
    await outbox.add(OutboxKind.status, '/slow', {});
    final f1 = outbox.flush();
    final f2 = outbox.flush();
    gate.complete();
    await Future.wait([f1, f2]);
    await pumpEventQueue();
    expect(http.calls('POST /slow'), hasLength(1));
  });

  group('GPS batching', () {
    List<Map<String, dynamic>> points(int n, [int from = 0]) =>
        List.generate(n, (i) => {'clientPointId': 'p${from + i}', 'recordedAt': 't', 'lon': 1.0, 'lat': 2.0});

    test('offline batches are merged up to 500 points', () async {
      http.fallback = (_, _) => const FakeReply.offline();
      await outbox.addGps(points(300));
      await settle();
      await outbox.addGps(points(300, 300));
      await settle();

      expect(outbox.items.map((i) => (i.body! as List).length), [500, 100]);
      expect(outbox.items.every((i) => i.kind == OutboxKind.gps), isTrue);
    });

    test('a batch the server may have seen is never changed', () async {
      http.reply(OutboxServiceTestRoutes.gps, 503, errorBody('DATABASE_UNAVAILABLE'));
      await outbox.addGps(points(10));
      await settle();
      final first = outbox.items.single;
      expect(first.attempts, 1);

      await outbox.addGps(points(5, 10));
      expect(outbox.items, hasLength(2));
      expect((first.body! as List).length, 10);
    });

    test('a GPS batch is not merged into a non-GPS item', () async {
      http.fallback = (_, _) => const FakeReply.offline();
      await outbox.add(OutboxKind.status, '/s', {});
      await outbox.addGps(points(3));
      await settle();
      expect(outbox.items.map((i) => i.kind), [OutboxKind.status, OutboxKind.gps]);
    });
  });

  test('clear wipes queued patient data and refs', () async {
    http.fallback = (_, _) => const FakeReply.offline();
    await outbox.add(OutboxKind.patient, '/api/v1/patients', {'fullNameAr': 'secret'}, resultRef: 'x');
    await settle();
    await outbox.clear();
    expect(outbox.items, isEmpty);
    expect(store.values, isEmpty);
  });

  test('retries on its own after the backoff delay', () {
    fakeAsync((async) {
      http.offline('POST /a');
      http.reply('POST /a', 200, {});
      unawaited(outbox.add(OutboxKind.status, '/a', {}));
      async.flushMicrotasks();
      expect(outbox.items, hasLength(1));

      async.elapse(const Duration(seconds: 6));
      async.flushMicrotasks();
      expect(outbox.items, isEmpty);
      expect(http.calls('POST /a'), hasLength(2));
    });
  });
}

abstract final class OutboxServiceTestRoutes {
  static const gps = 'POST /api/v1/crew/gps';
}
