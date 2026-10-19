import 'package:emr_core/emr_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_adapter.dart';

/// Payloads recorded from the live backend on 2026-10-15.
const liveJob = {
  'dispatchId': '00000000-0000-0000-00de-000000000310',
  'caseId': '00000000-0000-0000-00de-000000000c03',
  'status': 'leaving_scene',
  'caseNumber': 'KH-2026-000003',
  'priority': 'P2',
  'complaint': 'Motorbike accident, leg injury',
  'directions': null,
  'lon': 32.556,
  'lat': 15.581,
  'pinRadiusM': 300,
  'landmarkAr': null,
  'landmarkEn': null,
  'destinationHospitalId': '00000000-0000-0000-00de-000000000e01',
  'hospitalAr': 'مستشفى الرياض التجريبي',
  'hospitalEn': 'Riyadh Demo Hospital',
};

const liveRequests = {
  'content': [
    {
      'id': 'aafc93ab-c9fc-4b60-99d7-fa534402cced',
      'startedAt': '2026-10-13T08:39:46.763941Z',
      'statusCode': 'received',
      'statusAr': 'تم استلام طلبك، سيتصل بك مركز البلاغات',
      'statusEn': 'Request received; the call centre will call you',
      'updatedAt': '2026-10-13T09:20:11.979075Z',
    },
    {
      'id': '3a58bf22-136a-4e38-80d5-858cf5b78147',
      'startedAt': '2026-10-13T08:39:42.204668Z',
      'statusCode': 'closed',
      'statusAr': 'تم إغلاق الطلب',
      'statusEn': 'Request closed',
      'updatedAt': '2026-10-13T08:40:12.343178Z',
    },
  ],
  'page': 0,
  'size': 3,
  'hasNext': false,
  'totalElements': null,
};

void main() {
  group('Shift', () {
    test('parses the current-shift view with crew details', () {
      final current = CurrentShift.fromJson({
        'shift': {
          'id': 's-1',
          'ambulanceId': 'a-1',
          'plateNumber': 'DEMO-11',
          'hospitalNameAr': 'مستشفى الرياض التجريبي',
          'hospitalNameEn': 'Riyadh Demo Hospital',
          'startedAt': '2026-10-18T08:02:11Z',
          'crew': [
            {'fullNameEn': 'Driver One', 'role': 'driver', 'me': false},
            {'fullNameEn': 'Medic One', 'role': 'paramedic', 'me': true},
          ],
        },
      });

      expect(current.shift!.plateNumber, 'DEMO-11');
      expect(current.shift!.hospital('en'), 'Riyadh Demo Hospital');
      expect(current.shift!.crew[1].me, isTrue);
      expect(current.shift!.crew.first.name('en'), 'Driver One');
    });
  });

  group('Job', () {
    test('parses the live job payload', () {
      final j = Job.fromJson(liveJob);
      expect(j.hasJob, isTrue);
      expect(j.jobStatus, JobStatus.leavingScene);
      expect(j.pinRadiusM, 300);
      expect(j.hospital('en'), 'Riyadh Demo Hospital');
      expect(j.hospital('ar'), 'مستشفى الرياض التجريبي');
      expect(j.landmark('ar'), isNull);
    });

    test('{"job": null} means no job', () {
      expect(Job.fromJson({'job': null}).hasJob, isFalse);
    });

    test(
      'withStatus keeps every other field and survives a JSON round trip',
      () {
        final j = Job.fromJson(liveJob).withStatus(JobStatus.atHospital);
        expect(j.status, 'at_hospital');
        expect(Job.fromJson(j.toJson()).caseNumber, 'KH-2026-000003');
      },
    );

    test('integer coordinates from the server still parse as doubles', () {
      final j = Job.fromJson({...liveJob, 'lon': 32, 'lat': 15});
      expect(j.lon, 32.0);
    });

    test('parses and retains the crew job timeline', () {
      final j = Job.fromJson({
        ...liveJob,
        'caseCreatedAt': '2026-10-15T07:50:00Z',
        'sentAt': '2026-10-15T08:00:00Z',
        'confirmDeadlineAt': '2026-10-15T08:02:00Z',
        'confirmedAt': null,
        'statusTime': '2026-10-15T08:00:00Z',
        'serverTime': '2026-10-15T08:00:30Z',
      });

      expect(j.caseCreatedAt, DateTime.utc(2026, 10, 15, 7, 50));
      expect(j.sentAt, DateTime.utc(2026, 10, 15, 8));
      expect(j.confirmDeadlineAt, DateTime.utc(2026, 10, 15, 8, 2));
      expect(j.confirmedAt, isNull);
      expect(j.statusTime, DateTime.utc(2026, 10, 15, 8));
      expect(j.serverTime, DateTime.utc(2026, 10, 15, 8, 0, 30));
      expect(Job.fromJson(j.toJson()).confirmDeadlineAt, j.confirmDeadlineAt);
    });
  });

  group('JobStatus', () {
    test('follows the server order', () {
      expect(JobStatus.sent.primaryNext, JobStatus.confirmed);
      expect(JobStatus.confirmed.primaryNext, JobStatus.enRoute);
      expect(JobStatus.enRoute.primaryNext, JobStatus.onScene);
      expect(JobStatus.onScene.primaryNext, JobStatus.leavingScene);
      expect(JobStatus.leavingScene.primaryNext, JobStatus.atHospital);
      expect(JobStatus.atHospital.primaryNext, JobStatus.completed);
      expect(JobStatus.completed.primaryNext, isNull);
    });

    test('allows completing at the scene but nothing else out of order', () {
      expect(JobStatus.onScene.canMoveTo(JobStatus.completed), isTrue);
      expect(JobStatus.enRoute.canMoveTo(JobStatus.atHospital), isFalse);
      expect(JobStatus.atHospital.canMoveTo(JobStatus.onScene), isFalse);
      expect(JobStatus.sent.canMoveTo(JobStatus.enRoute), isFalse);
    });

    test('maps wire values both ways', () {
      for (final s in JobStatus.values) {
        expect(JobStatus.fromWire(s.wire), s);
      }
      expect(JobStatus.fromWire('nonsense'), isNull);
    });
  });

  group('auth models', () {
    test('LoginResult sms_code step has no tokens', () {
      final r = LoginResult.fromJson({
        'step': 'sms_code',
        'challengeId': '26afb6f1-f9d5-425c-be48-ef7487cb8900',
        'expiresAt': '2026-10-15T07:24:18.363448566Z',
        'accessToken': null,
        'refreshToken': null,
        'mustChangePassword': null,
      });
      expect(r.signedIn, isFalse);
      expect(r.tokens, isNull);
      expect(r.expiresAt!.isUtc, isTrue);
    });

    test('LoginResult signed_in step carries tokens', () {
      final r = LoginResult.fromJson({
        'step': 'signed_in',
        'accessToken': 'a',
        'refreshToken': 'r',
        'mustChangePassword': true,
      });
      expect(r.tokens!.refreshToken, 'r');
      expect(r.tokens!.mustChangePassword, isTrue);
    });

    test('Me round-trips through JSON (cached for offline start)', () {
      final me = Me.fromJson({
        'id': '00000000-0000-0000-00de-0000000000d8',
        'username': 'demo.driver1',
        'fullNameAr': 'سائق الرياض',
        'fullNameEn': 'Driver Riyadh',
        'role': 'DRIVER',
        'preferredLanguage': 'ar',
        'scopes': [
          {
            'type': 'hospital',
            'stateId': null,
            'hospitalId': 'h1',
            'scopeType': 'hospital',
          },
        ],
        'stateCodes': ['KH'],
        'mustChangePassword': false,
      });
      final again = Me.fromJson(me.toJson());
      expect(again.isDriver, isTrue);
      expect(again.isCrew, isTrue);
      expect(again.scopes.single.hospitalId, 'h1');
      expect(again.displayName('en'), 'Driver Riyadh');
    });

    test('Me tolerates missing lists', () {
      final me = Me.fromJson({'id': 'x', 'username': 'u'});
      expect(me.scopes, isEmpty);
      expect(me.mustChangePassword, isFalse);
      expect(me.displayName('ar'), 'u');
    });

    test('LoginBody always says deviceType mobile', () {
      final j = const LoginBody(
        username: 'u',
        password: 'p',
        clientApp: 'crew_app',
        deviceId: 'd',
        appVersion: '1',
      ).toJson();
      expect(j['deviceType'], 'mobile');
    });
  });

  group('request bodies omit nulls', () {
    test('ObservationBody', () {
      const b = ObservationBody(
        observedAt: '2026-10-15T07:00:00Z',
        heartRate: 80,
      );
      expect(b.toJson(), {
        'observedAt': '2026-10-15T07:00:00Z',
        'heartRate': 80,
      });
      expect(b.hasAnyValue, isTrue);
      expect(const ObservationBody(observedAt: 'x').hasAnyValue, isFalse);
    });

    test('PatientBody for an unknown person', () {
      const b = PatientBody(
        fullNameAr: 'مجهول',
        sex: 'unknown',
        temporary: true,
        temporaryLabel: 'Unknown 1',
        estimatedAge: 40,
      );
      expect(
        b.toJson().keys,
        containsAll([
          'fullNameAr',
          'sex',
          'temporary',
          'temporaryLabel',
          'estimatedAge',
        ]),
      );
      expect(b.toJson().containsKey('nationalId'), isFalse);
    });

    test('SosBody', () {
      expect(const SosBody(lon: 32.5, lat: 15.5).toJson(), {
        'lon': 32.5,
        'lat': 15.5,
      });
    });
  });

  group('citizen models', () {
    test('parses the live requests page with null totalElements', () {
      final p = ApiPage<RequestRow>.fromJson(
        liveRequests,
        (j) => RequestRow.fromJson(j! as Map<String, dynamic>),
      );
      expect(p.content, hasLength(2));
      expect(p.totalElements, isNull);
      expect(p.hasNext, isFalse);
      expect(p.content.first.isOpen, isTrue);
      expect(p.content.last.isOpen, isFalse);
      expect(
        p.content.first.status('en'),
        'Request received; the call centre will call you',
      );
    });

    test('unknown status codes do not crash', () {
      expect(
        RequestStatusCode.fromWire('brand_new'),
        RequestStatusCode.unknown,
      );
      expect(IdentityStatus.fromWire(null), IdentityStatus.unknown);
    });

    test('HistoryRow reads common keys defensively', () {
      final h = HistoryRow.fromJson({
        'startedAt': '2026-10-01T10:00:00Z',
        'caseNumber': 'KH-1',
        'hospitalNameEn': 'Riyadh',
      });
      expect(h.at, DateTime.utc(2026, 10, 1, 10));
      expect(h.title('en'), 'KH-1');
      expect(h.subtitle('en'), 'Riyadh');
      expect(HistoryRow.fromJson('not a map').raw, isEmpty);
    });
  });

  group('Retrofit wiring', () {
    late FakeAdapter http;
    late ApiClient api;

    setUp(() {
      http = FakeAdapter();
      api = ApiClient(
        config: const AppConfig(
          clientApp: ClientApp.citizen,
          version: '1.0.0',
          apiBaseUrl: 'http://test',
        ),
        tokens: _NoTokens(),
        adapter: http,
      );
    });

    test('SOS sends the Idempotency-Key header', () async {
      http.reply('POST /api/v1/citizen/requests', 200, {
        'id': 'r1',
        'statusCode': 'received',
      });
      final r = await api.citizen.sos(const SosBody(lon: 1, lat: 2), 'key-1');
      expect(r.id, 'r1');
      expect(http.requests.single.headers['Idempotency-Key'], 'key-1');
      expect(http.bodies.single, {'lon': 1.0, 'lat': 2.0});
    });

    test('history passes patientId only when set', () async {
      http.reply('GET /api/v1/citizen/history', 200, {
        'content': <Object>[],
        'page': 0,
        'size': 10,
        'hasNext': false,
      });
      await api.citizen.history(0, 10);
      await api.citizen.history(0, 10, patientId: 'p1');
      expect(
        http.requests.first.queryParameters.containsKey('patientId'),
        isFalse,
      );
      expect(http.requests.last.queryParameters['patientId'], 'p1');
    });

    test('crew job with no job', () async {
      http.reply('GET /api/v1/crew/job', 200, {'job': null});
      expect((await api.crew.job()).hasJob, isFalse);
    });
  });
}

class _NoTokens implements AuthTokenSource {
  @override
  Future<RefreshOutcome>? get pendingRefresh => null;
  @override
  String? get accessToken => null;
  @override
  Future<RefreshOutcome> refreshAccessToken() async =>
      const RefreshUnreachable();
  @override
  void onSessionError(ApiError error) {}
}
