import 'package:crew_app/data/crew_repository.dart';
import 'package:crew_app/modules/home/crew_controller.dart';
import 'package:crew_app/services/gps_service.dart';
import 'package:crew_app/services/live_service.dart';
import 'package:emr_core/emr_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

class Rig {
  Rig({bool Function()? canUpdateStatus}) {
    session = SessionService(secure: secure, authApi: () => api.auth);
    api = ApiClient(
      config: const AppConfig(
        clientApp: ClientApp.crew,
        version: '1.0.0',
        apiBaseUrl: 'http://test',
      ),
      tokens: session,
      adapter: http,
    );
    outbox = OutboxService(
      store: MemoryKeyValueStore(),
      dio: () => api.dio,
      backoff: const [Duration(hours: 1)],
    );
    repo = CrewRepository(
      api: api,
      outbox: outbox,
      cache: cache,
      now: () => clock,
    );
    live = LiveService(connector: stomp, session: session, url: 'ws://test');
    gps = GpsService(source: location, outbox: outbox);
    crew = CrewController(
      repo: repo,
      outbox: outbox,
      live: live,
      gps: gps,
      canUpdateStatus: canUpdateStatus,
      now: () => clock,
      pollEvery: const Duration(hours: 1),
    );
  }

  final http = FakeAdapter();
  final secure = MemorySecureStore();
  final cache = MemoryKeyValueStore();
  final stomp = FakeStomp();
  final location = FakeLocation();
  late final SessionService session;
  late final ApiClient api;
  late final OutboxService outbox;
  late final CrewRepository repo;
  late final LiveService live;
  late final GpsService gps;
  late final CrewController crew;
  DateTime clock = DateTime.utc(2026, 10, 15, 8);

  Future<void> signedIn() =>
      session.start(const LoginTokens(accessToken: 'at', refreshToken: 'rt'));

  Future<void> settle() async {
    await outbox.flush();
    await pumpEventQueue(times: 200);
    await crew.refresh();
    await pumpEventQueue(times: 200);
  }

  void dispose() {
    crew.onClose();
    live.onClose();
    gps.onClose();
    outbox.onClose();
    session.onClose();
  }
}

void main() {
  group('mergeJob', () {
    final j = Job.fromJson(jobWith('on_scene'));

    test('server wins when nothing is pending', () {
      expect(
        mergeJob(
          local: j,
          server: j.withStatus(JobStatus.enRoute),
          pending: false,
        ).jobStatus,
        JobStatus.enRoute,
      );
    });

    test('a queued step is not rolled back by a stale server copy', () {
      expect(
        mergeJob(
          local: j,
          server: j.withStatus(JobStatus.enRoute),
          pending: true,
        ).jobStatus,
        JobStatus.onScene,
      );
    });

    test('the server may move ahead of us', () {
      expect(
        mergeJob(
          local: j,
          server: j.withStatus(JobStatus.atHospital),
          pending: true,
        ).jobStatus,
        JobStatus.atHospital,
      );
    });

    test('a different dispatch always replaces the local job', () {
      final other = Job.fromJson(jobWith('sent', id: 'd-2'));
      expect(
        mergeJob(local: j, server: other, pending: true).dispatchId,
        'd-2',
      );
    });

    test(
      'a job completed locally stays gone while the completion is queued',
      () {
        expect(
          mergeJob(
            local: j,
            server: j,
            pending: true,
            completedLocally: 'd-1',
          ).hasJob,
          isFalse,
        );
      },
    );

    test('isNewJob', () {
      expect(isNewJob(Job.none, j), isTrue);
      expect(isNewJob(j, j.withStatus(JobStatus.atHospital)), isFalse);
      expect(isNewJob(j, Job.none), isFalse);
    });
  });

  group('CrewController', () {
    late Rig r;

    setUp(() async {
      r = Rig();
      await r.signedIn();
    });

    tearDown(() => r.dispose());

    test(
      'starting a shift caches it, starts live updates and GPS, then reads the job',
      () async {
        r.http.reply('POST /api/v1/crew/shifts', 200, {
          'id': 's-1',
          'ambulanceId': 'a-1',
        });
        r.http.reply('GET /api/v1/crew/job', 200, {'job': null});

        await r.crew.startShift('  qr-token  ');
        await r.settle();

        expect(r.http.bodiesOf('POST /api/v1/crew/shifts').single, {
          'qrToken': 'qr-token',
        });
        expect((await r.repo.cachedShift())!.ambulanceId, 'a-1');
        expect(r.stomp.tokens, ['at']);
        expect(r.gps.running, isTrue);
        expect(r.crew.hasJob, isFalse);
        expect(r.crew.lastFetched.value, isNotNull);
      },
    );

    test('joining uses the join endpoint', () async {
      r.http.reply('POST /api/v1/crew/shifts/current/join', 200, {
        'id': 's-1',
        'ambulanceId': 'a-1',
      });
      r.http.reply('GET /api/v1/crew/job', 200, {'job': null});
      await r.crew.startShift('qr', join: true);
      expect(
        r.http.calls('POST /api/v1/crew/shifts/current/join'),
        hasLength(1),
      );
    });

    test('manual ambulance code sends code, never qrToken', () async {
      r.http.reply('POST /api/v1/crew/shifts', 200, {'id': 's-1'});
      r.http.reply('GET /api/v1/crew/job', 200, {'job': null});

      await r.crew.startShift('000000', code: true);

      expect(r.http.bodiesOf('POST /api/v1/crew/shifts').single, {
        'code': '000000',
      });
    });

    test('manual join sends code to the join endpoint', () async {
      r.http.reply('POST /api/v1/crew/shifts/current/join', 200, {'id': 's-1'});
      r.http.reply('GET /api/v1/crew/job', 200, {'job': null});

      await r.crew.startShift('000000', join: true, code: true);

      expect(r.http.bodiesOf('POST /api/v1/crew/shifts/current/join').single, {
        'code': '000000',
      });
    });

    test('an unknown QR is a 404 the screen can show', () async {
      r.http.reply(
        'POST /api/v1/crew/shifts',
        404,
        err('NOT_FOUND', en: 'The requested resource was not found.'),
      );
      await expectLater(r.crew.startShift('nope'), throwsA(anything));
      expect(r.crew.onShift, isFalse);
    });

    test('SHIFT_ALREADY_ACTIVE restores the shift and loads its job', () async {
      r.http.reply(
        'POST /api/v1/crew/shifts',
        400,
        err('SHIFT_ALREADY_ACTIVE'),
      );
      r.http.reply('GET /api/v1/crew/shifts/current', 200, {
        'shift': {'id': 's-1', 'plateNumber': 'DEMO-11'},
      });
      r.http.reply('GET /api/v1/crew/job', 200, {'job': null});

      await r.crew.startShift('qr');
      await pumpEventQueue(times: 20);

      expect(r.crew.onShift, isTrue);
      expect(await r.repo.cachedShift(), isNotNull);
      expect(r.gps.running, isTrue);
      expect(r.http.calls('GET /api/v1/crew/job'), hasLength(1));
    });

    test(
      'a new job raises the alert; a live event triggers the read',
      () async {
        r.http.reply('POST /api/v1/crew/shifts', 200, {'id': 's-1'});
        r.http.reply('GET /api/v1/crew/job', 200, {'job': null});
        await r.crew.startShift('qr');
        await r.settle();
        expect(r.crew.alerting.value, isFalse);

        r.http.reply('GET /api/v1/crew/job', 200, liveJob);
        r.stomp.event({
          'type': 'job.new',
          'dispatchId': 'd-1',
          'userId': 'u',
          'time': 't',
        });
        await r.settle();

        expect(r.crew.job.value.dispatchId, 'd-1');
        expect(r.crew.alerting.value, isTrue);
        expect(
          (await r.repo.cachedJob()).caseNumber,
          'KH-2026-000003',
          reason: 'cached for offline',
        );
      },
    );

    test(
      'confirm and steps are queued with the button time, in order, each with its own key',
      () async {
        r.http.reply('POST /api/v1/crew/shifts', 200, {'id': 's-1'});
        r.http.reply('GET /api/v1/crew/job', 200, liveJob);
        r.http.reply('POST /api/v1/dispatches/d-1/confirm', 200, {});
        r.http.reply('POST /api/v1/dispatches/d-1/status', 200, {});
        await r.crew.startShift('qr');
        await r.settle();

        await r.crew.confirm();
        expect(r.crew.alerting.value, isFalse);
        expect(r.crew.job.value.jobStatus, JobStatus.confirmed);

        r.clock = DateTime.utc(2026, 10, 15, 8, 2, 30);
        await r.crew.advance(JobStatus.enRoute);
        r.clock = DateTime.utc(2026, 10, 15, 8, 9);
        await r.crew.advance(JobStatus.onScene);
        await r.settle();

        expect(
          r.http.calls('POST /api/v1/dispatches/d-1/confirm'),
          hasLength(1),
        );
        expect(r.http.bodiesOf('POST /api/v1/dispatches/d-1/status'), [
          {'status': 'en_route', 'statusTime': '2026-10-15T08:02:30Z'},
          {'status': 'on_scene', 'statusTime': '2026-10-15T08:09:00Z'},
        ]);
        final keys = [
          ...r.http.calls('POST /api/v1/dispatches/d-1/confirm'),
          ...r.http.calls('POST /api/v1/dispatches/d-1/status'),
        ].map((o) => o.headers['Idempotency-Key']).toSet();
        expect(keys, hasLength(3));
      },
    );

    test('out-of-order steps are ignored on the phone', () async {
      r.http.reply('POST /api/v1/crew/shifts', 200, {'id': 's-1'});
      r.http.reply('GET /api/v1/crew/job', 200, jobWith('confirmed'));
      await r.crew.startShift('qr');
      await r.settle();

      await r.crew.advance(JobStatus.atHospital);
      await r.crew.advance(JobStatus.confirmed);
      expect(r.crew.job.value.jobStatus, JobStatus.confirmed);
      expect(r.outbox.items, isEmpty);
    });

    test('a paramedic cannot confirm or update job status', () async {
      final paramedic = Rig(canUpdateStatus: () => false);
      await paramedic.signedIn();
      paramedic.http.reply('POST /api/v1/crew/shifts', 200, {'id': 's-1'});
      paramedic.http.reply('GET /api/v1/crew/job', 200, jobWith('sent'));
      await paramedic.crew.startShift('qr');
      await paramedic.settle();

      await paramedic.crew.confirm();
      await paramedic.crew.advance(JobStatus.enRoute);

      expect(paramedic.crew.job.value.jobStatus, JobStatus.sent);
      expect(paramedic.outbox.items, isEmpty);
      paramedic.dispose();
    });

    test(
      'offline: steps stay on screen, are not rolled back, and go out in order when back',
      () async {
        r.http.reply('POST /api/v1/crew/shifts', 200, {'id': 's-1'});
        r.http.reply('GET /api/v1/crew/job', 200, jobWith('confirmed'));
        await r.crew.startShift('qr');
        await r.settle();

        r.http.offlineAll = true;
        r.clock = DateTime.utc(2026, 10, 15, 8, 5);
        await r.crew.advance(JobStatus.enRoute);
        r.clock = DateTime.utc(2026, 10, 15, 8, 12);
        await r.crew.advance(JobStatus.onScene);
        await r.settle();
        await r.crew.refresh();
        expect(r.crew.job.value.jobStatus, JobStatus.onScene);
        expect(r.crew.error.value!.isNetwork, isTrue);
        expect(r.outbox.items, hasLength(2));

        // Back online; the server has not applied our steps yet when we first read it.
        r.http.offlineAll = false;
        r.http.reply('POST /api/v1/dispatches/d-1/status', 200, {});
        r.http.reply('GET /api/v1/crew/job', 200, jobWith('confirmed'));
        final pendingSnapshot = r.repo.hasPendingSteps('d-1');
        expect(pendingSnapshot, isTrue);
        await r.crew.refresh();
        expect(
          r.crew.job.value.jobStatus,
          JobStatus.onScene,
          reason: 'stale server copy does not roll back',
        );

        r.outbox.nudge();
        await r.settle();
        expect(
          r.http
              .bodiesOf('POST /api/v1/dispatches/d-1/status')
              .map((b) => (b! as Map)['status']),
          ['en_route', 'on_scene'],
        );
        expect(r.outbox.items, isEmpty);
      },
    );

    test(
      'a refused step (STATUS_TIME_INVALID) re-reads the job from the server',
      () async {
        r.http.reply('POST /api/v1/crew/shifts', 200, {'id': 's-1'});
        r.http.reply('GET /api/v1/crew/job', 200, jobWith('confirmed'));
        await r.crew.startShift('qr');
        await r.settle();

        r.http.reply(
          'POST /api/v1/dispatches/d-1/status',
          400,
          err('STATUS_TIME_INVALID'),
        );
        final readsBefore = r.http.calls('GET /api/v1/crew/job').length;
        await r.crew.advance(JobStatus.enRoute);
        await r.settle();
        await pumpEventQueue();

        expect(
          r.http.calls('GET /api/v1/crew/job').length,
          greaterThan(readsBefore),
        );
        expect(
          r.crew.job.value.jobStatus,
          JobStatus.confirmed,
          reason: 'server truth after the refusal',
        );
      },
    );

    test('a job the server took away shows the cancelled notice', () async {
      r.http.reply('POST /api/v1/crew/shifts', 200, {'id': 's-1'});
      r.http.reply('GET /api/v1/crew/job', 200, jobWith('en_route'));
      await r.crew.startShift('qr');
      await r.settle();

      r.http.reply('GET /api/v1/crew/job', 200, {'job': null});
      r.stomp.event({'type': 'job.cancelled', 'dispatchId': 'd-1'});
      await r.settle();

      expect(r.crew.hasJob, isFalse);
      expect(r.crew.cancelledNotice.value, isTrue);
      expect((await r.repo.cachedJob()).hasJob, isFalse);
    });

    test('completing does not look like a cancellation', () async {
      r.http.reply('POST /api/v1/crew/shifts', 200, {'id': 's-1'});
      r.http.reply('GET /api/v1/crew/job', 200, jobWith('at_hospital'));
      r.http.reply('POST /api/v1/dispatches/d-1/status', 200, {});
      await r.crew.startShift('qr');
      await r.settle();

      r.http.reply('GET /api/v1/crew/job', 200, {'job': null});
      await r.crew.advance(JobStatus.completed);
      await r.settle();
      await r.crew.refresh();

      expect(r.crew.hasJob, isFalse);
      expect(r.crew.cancelledNotice.value, isFalse);
    });

    test('pre-arrival alert goes through the outbox with a key', () async {
      r.http.reply('POST /api/v1/crew/shifts', 200, {'id': 's-1'});
      r.http.reply('GET /api/v1/crew/job', 200, jobWith('en_route'));
      r.http.reply('POST /api/v1/dispatches/d-1/alerts', 200, {
        'id': 'al-1',
        'type': 'stroke',
      });
      await r.crew.startShift('qr');
      await r.settle();

      await r.crew.raiseAlert(AlertType.cardiacArrest, note: '  ');
      await r.settle();

      expect(r.http.bodiesOf('POST /api/v1/dispatches/d-1/alerts').single, {
        'type': 'cardiac_arrest',
      });
      expect(
        r.http
            .calls('POST /api/v1/dispatches/d-1/alerts')
            .single
            .headers['Idempotency-Key'],
        isNotNull,
      );
    });

    test(
      'ending a shift with an open job reports SHIFT_HAS_JOB and keeps the shift',
      () async {
        r.http.reply('POST /api/v1/crew/shifts', 200, {'id': 's-1'});
        r.http.reply('GET /api/v1/crew/job', 200, jobWith('en_route'));
        r.http.reply(
          'POST /api/v1/crew/shifts/current/end',
          409,
          err('SHIFT_HAS_JOB'),
        );
        await r.crew.startShift('qr');
        await r.settle();

        Object? thrown;
        try {
          await r.crew.endShift();
        } on Object catch (e) {
          thrown = e;
        }
        expect(ApiError.of(thrown!).code, 'SHIFT_HAS_JOB');
        expect(r.crew.onShift, isTrue);
      },
    );

    test(
      'ending a shift stops live, GPS and forgets the cached shift',
      () async {
        r.http.reply('POST /api/v1/crew/shifts', 200, {'id': 's-1'});
        r.http.reply('GET /api/v1/crew/job', 200, {'job': null});
        r.http.reply('POST /api/v1/crew/shifts/current/end', 200, {
          'shiftId': 's-1',
          'ended': true,
        });
        await r.crew.startShift('qr');
        await r.settle();

        await r.crew.endShift();
        expect(r.crew.onShift, isFalse);
        expect(r.gps.running, isFalse);
        expect(r.stomp.closed, 1);
        expect(await r.repo.cachedShift(), isNull);
      },
    );

    test('init reads the current shift on the server (new phone)', () async {
      r.http.reply('GET /api/v1/crew/shifts/current', 200, {
        'shift': {'id': 's-1', 'plateNumber': 'DEMO-11'},
      });
      r.http.reply('GET /api/v1/crew/job', 200, jobWith('leaving_scene'));
      await r.crew.init();
      await r.settle();
      expect(r.crew.onShift, isTrue);
      expect(r.crew.job.value.jobStatus, JobStatus.leavingScene);
      expect(r.crew.alerting.value, isFalse);
      expect(await r.repo.cachedShift(), isNotNull);
      expect(r.stomp.tokens, isNotEmpty, reason: 'live updates started');
    });

    test('init with no cached shift and no job stays off shift', () async {
      r.http.reply('GET /api/v1/crew/shifts/current', 200, {'shift': null});
      await r.crew.init();
      expect(r.crew.onShift, isFalse);
    });

    test(
      'init restores shift and job from the cache with no network',
      () async {
        await r.cache.put('crew.shift', {'id': 's-1', 'ambulanceId': 'a-1'});
        await r.cache.put('crew.job', jobWith('sent'));
        r.http.offlineAll = true;

        await r.crew.init();
        await r.settle();

        expect(r.crew.onShift, isTrue);
        expect(r.crew.job.value.caseNumber, 'KH-2026-000003');
        expect(
          r.crew.alerting.value,
          isTrue,
          reason: 'an unconfirmed job still alarms after a restart',
        );
      },
    );
  });
}
