import 'dart:async';

import 'package:crew_app/data/crew_repository.dart';
import 'package:crew_app/modules/home/crew_controller.dart';
import 'package:crew_app/modules/patient/patient_controller.dart';
import 'package:crew_app/services/gps_service.dart';
import 'package:crew_app/services/live_service.dart';
import 'package:dio/dio.dart';
import 'package:emr_core/emr_core.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  group('CrewEvent.parse', () {
    test('accepts known types and ignores everything else', () {
      expect(
        CrewEvent.parse(
          '{"type":"job.new","dispatchId":"d","userId":"u","time":"t"}',
        )!.dispatchId,
        'd',
      );
      expect(
        CrewEvent.parse('{"type":"job.cancelled"}')!.type,
        'job.cancelled',
      );
      expect(CrewEvent.parse('{"type":"job.renamed"}'), isNull);
      expect(CrewEvent.parse('not json'), isNull);
      expect(CrewEvent.parse(null), isNull);
      expect(CrewEvent.parse('[1,2]'), isNull);
    });

    test('backoff is 1, 2, 4 … capped at 30 s', () {
      expect(
        [for (var i = 0; i < 7; i++) liveBackoff(i).inSeconds],
        [1, 2, 4, 8, 16, 30, 30],
      );
    });
  });

  group('LiveService', () {
    late FakeAdapter http;
    late SessionService session;
    late ApiClient api;
    late FakeStomp stomp;
    late LiveService live;

    setUp(() async {
      http = FakeAdapter();
      final secure = MemorySecureStore({SecureKeys.refreshToken: 'rt'});
      session = SessionService(secure: secure, authApi: () => api.auth);
      api = ApiClient(
        config: const AppConfig(
          clientApp: ClientApp.crew,
          version: '1',
          apiBaseUrl: 'http://t',
        ),
        tokens: session,
        adapter: http,
      );
      await session.start(
        const LoginTokens(accessToken: 'at-1', refreshToken: 'rt'),
      );
      stomp = FakeStomp();
      live = LiveService(connector: stomp, session: session, url: 'ws://t/ws');
    });

    test('connects with the access token and forwards known events', () async {
      final got = <String>[];
      live.events.listen((e) => got.add(e.type));
      live.start();
      stomp.connected();
      stomp.event({'type': 'job.new', 'dispatchId': 'd'});
      stomp.event({'type': 'mystery'});
      await pumpEventQueue();

      expect(stomp.tokens, ['at-1']);
      expect(live.connected.value, isTrue);
      expect(got, ['live.connected', 'job.new']);
      live.stop();
    });

    test(
      'ERROR UNAUTHORIZED refreshes and reconnects with the new token',
      () async {
        http.reply('POST /api/v1/auth/refresh', 200, {'accessToken': 'at-2'});
        live.start();
        stomp.error('UNAUTHORIZED');
        await pumpEventQueue(times: 50);
        expect(stomp.tokens, ['at-1', 'at-2']);
        expect(stomp.closed, greaterThanOrEqualTo(1));
        live.stop();
      },
    );

    test('a proactive token refresh reconnects the socket', () async {
      http.reply('POST /api/v1/auth/refresh', 200, {'accessToken': 'at-3'});
      live.start();
      await session.refreshAccessToken();
      await pumpEventQueue();
      expect(stomp.tokens.last, 'at-3');
      live.stop();
    });

    test('a dropped socket reconnects with backoff', () {
      fakeAsync((async) {
        live.start();
        stomp.drop();
        async.elapse(const Duration(milliseconds: 900));
        expect(stomp.tokens, hasLength(1));
        async.elapse(const Duration(milliseconds: 200));
        expect(stomp.tokens, hasLength(2));
        stomp.drop();
        async.elapse(const Duration(seconds: 2, milliseconds: 100));
        expect(stomp.tokens, hasLength(3));
        live.stop();
        stomp.drop();
        async.elapse(const Duration(minutes: 1));
        expect(stomp.tokens, hasLength(3), reason: 'no reconnect after stop');
      });
    });
  });

  group('GpsService', () {
    late OutboxService outbox;
    late FakeLocation loc;
    late GpsService gps;
    late FakeAdapter http;

    setUp(() {
      http = FakeAdapter()..offlineAll = true;
      final dio = Dio(
        BaseOptions(baseUrl: 'http://t', contentType: Headers.jsonContentType),
      )..httpClientAdapter = http;
      outbox = OutboxService(
        store: MemoryKeyValueStore(),
        dio: () => dio,
        backoff: const [Duration(hours: 1)],
      );
      loc = FakeLocation();
      gps = GpsService(source: loc, outbox: outbox);
    });

    test('buffers fixes and queues them every 15 s on a job', () {
      fakeAsync((async) {
        unawaited(gps.start(onJob: true));
        async.flushMicrotasks();
        loc.emit(15.5, 32.5, DateTime.utc(2026, 10, 15, 8, 0, 1));
        loc.emit(15.6, 32.6, DateTime.utc(2026, 10, 15, 8, 0, 2));
        async.flushMicrotasks();
        expect(outbox.items, isEmpty);

        async.elapse(const Duration(seconds: 15));
        async.flushMicrotasks();
        final batch = outbox.items.single.body! as List;
        expect(batch, hasLength(2));
        final p = batch.first as Map;
        expect(p['recordedAt'], '2026-10-15T08:00:01Z');
        expect(p['speedKmh'], 36.0);
        expect(p['clientPointId'], isNot((batch.last as Map)['clientPointId']));
        expect(gps.last.value!.lat, 15.6);
        unawaited(gps.stop());
        async.flushMicrotasks();
      });
    });

    test('idle cadence is 60 s', () {
      fakeAsync((async) {
        unawaited(gps.start(onJob: false));
        async.flushMicrotasks();
        loc.emit(15.5, 32.5, DateTime.utc(2026, 10, 15, 8));
        async.elapse(const Duration(seconds: 59));
        expect(outbox.items, isEmpty);
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();
        expect(outbox.items, hasLength(1));
        unawaited(gps.stop());
        async.flushMicrotasks();
      });
    });

    test('no permission: nothing runs and the flag is down', () async {
      loc.allowed = false;
      await gps.start(onJob: true);
      expect(gps.running, isFalse);
      expect(gps.permitted.value, isFalse);
    });

    test('drops inaccurate and implausibly future fixes', () {
      final now = DateTime.utc(2026, 10, 15, 8);
      gps = GpsService(source: loc, outbox: outbox, now: () => now);
      fakeAsync((async) {
        unawaited(gps.start(onJob: true));
        async.flushMicrotasks();
        loc.emit(15.5, 32.5, now, accuracyM: 101);
        loc.emit(15.6, 32.6, now.add(const Duration(minutes: 5, seconds: 1)));
        async.elapse(const Duration(seconds: 15));
        async.flushMicrotasks();
        expect(outbox.items, isEmpty);
        unawaited(gps.stop());
        async.flushMicrotasks();
      });
    });

    test('stop flushes what is buffered', () async {
      await gps.start(onJob: true);
      loc.emit(1, 2, DateTime.utc(2026));
      await pumpEventQueue();
      await gps.stop();
      expect(outbox.items, hasLength(1));
    });
  });

  group('PatientController (offline paramedic)', () {
    late FakeAdapter http;
    late OutboxService outbox;
    late CrewRepository repo;
    late PatientController c;
    late CrewController crew;

    setUp(() async {
      http = FakeAdapter()..offlineAll = true;
      final session = SessionService(
        secure: MemorySecureStore(),
        authApi: () => throw UnimplementedError(),
      );
      final api = ApiClient(
        config: const AppConfig(
          clientApp: ClientApp.crew,
          version: '1',
          apiBaseUrl: 'http://t',
        ),
        tokens: session,
        adapter: http,
      );
      outbox = OutboxService(
        store: MemoryKeyValueStore(),
        dio: () => api.dio,
        backoff: const [Duration(hours: 1)],
      );
      final now = DateTime.utc(2026, 10, 15, 9, 30);
      repo = CrewRepository(
        api: api,
        outbox: outbox,
        cache: MemoryKeyValueStore(),
        now: () => now,
      );
      crew = CrewController(
        repo: repo,
        outbox: outbox,
        live: LiveService(
          connector: FakeStomp(),
          session: session,
          url: 'ws://t',
        ),
        gps: GpsService(source: FakeLocation(), outbox: outbox),
      );
      crew.job.value = Job.fromJson(jobWith('on_scene'));
      c = PatientController(repo: repo, crew: crew, outbox: outbox, now: () => now);
      await c.load();
    });

    test(
      'register → vitals → treatment all queue offline and chain by reference',
      () async {
        expect(
          await c.register(
            unknown: true,
            fullNameAr: '',
            sex: 'male',
            temporaryLabel: 'Unknown man 1',
            estimatedAge: 40,
          ),
          isTrue,
        );
        expect(
          await c.addVitals({
            'heartRate': 110,
            'systolic': 120,
            'diastolic': 80,
          }, consciousness: 'V'),
          isTrue,
        );
        expect(
          await c.addTreatment(
            kind: 'medicine',
            name: 'Paracetamol',
            dose: '1 g',
            route: 'oral',
          ),
          isTrue,
        );
        await pumpEventQueue();

        final items = outbox.items;
        expect(items.map((i) => i.kind), [
          OutboxKind.patient,
          OutboxKind.observation,
          OutboxKind.treatment,
        ]);
        expect(items[0].body, {
          'fullNameAr': 'Unknown man 1',
          'sex': 'male',
          'temporary': true,
          'temporaryLabel': 'Unknown man 1',
          'estimatedAge': 40,
        });
        expect(
          items[1].path,
          '/api/v1/patients/{ref:${items[0].resultRef}}/observations',
        );
        expect(items[1].body, {
          'observedAt': '2026-10-15T09:30:00Z',
          'caseId': 'c-1',
          'heartRate': 110,
          'systolic': 120,
          'diastolic': 80,
          'consciousness': 'V',
        });
        expect((items[2].body! as Map)['givenAt'], '2026-10-15T09:30:00Z');
        expect(c.patients.single.entries.map((e) => e.label), [
          'entry_vitals',
          'entry_treatment',
        ]);

        // Back online: the observation is sent to the id the server gave the patient.
        http.offlineAll = false;
        http.reply('POST /api/v1/patients', 200, {
          'id': 'srv-p1',
          'firstRecordStatus': 'basic',
        });
        http.reply('POST /api/v1/patients/srv-p1/observations', 200, {});
        http.reply('POST /api/v1/patients/srv-p1/treatments', 200, {});
        outbox.nudge();
        await outbox.flush();
        expect(outbox.items, isEmpty);
        expect(
          http.calls('POST /api/v1/patients/srv-p1/observations'),
          hasLength(1),
        );
        expect(
          http.calls('POST /api/v1/patients/srv-p1/treatments'),
          hasLength(1),
        );
      },
    );

    test(
      'known person needs a valid national ID; phone is normalised',
      () async {
        expect(
          await c.register(
            unknown: false,
            fullNameAr: 'أحمد',
            sex: 'male',
            nationalId: '12',
          ),
          isFalse,
        );
        expect(c.fieldErrors.keys, contains('nationalId'));
        expect(
          await c.register(
            unknown: false,
            fullNameAr: 'أحمد',
            sex: 'male',
            nationalId: '1234567',
            phone: '0912345678',
          ),
          isTrue,
        );
        await pumpEventQueue();
        expect((outbox.items.single.body! as Map)['phone'], '+249912345678');
      },
    );

    test('vitals outside the hard limits are refused on the phone', () async {
      await c.register(
        unknown: true,
        fullNameAr: '',
        sex: 'female',
        temporaryLabel: 'X',
        estimatedAge: 30,
      );
      expect(await c.addVitals({'heartRate': 400}), isFalse);
      expect(c.fieldErrors.keys, ['heartRate']);
      expect(await c.addVitals({'systolic': 80, 'diastolic': 90}), isFalse);
      expect(c.fieldErrors.keys, ['diastolic']);
      expect(await c.addVitals({}), isFalse, reason: 'at least one value');
      expect(outbox.items, hasLength(1));
    });

    test('unusual values are flagged for confirmation', () {
      expect(c.unusual({'spo2': 85, 'heartRate': 80}), ['spo2']);
    });

    test('treatment needs kind and name', () async {
      await c.register(
        unknown: true,
        fullNameAr: '',
        sex: 'female',
        temporaryLabel: 'X',
        estimatedAge: 30,
      );
      expect(await c.addTreatment(kind: '', name: ''), isFalse);
      expect(c.fieldErrors.keys, containsAll(['kind', 'name']));
    });
  });
}
