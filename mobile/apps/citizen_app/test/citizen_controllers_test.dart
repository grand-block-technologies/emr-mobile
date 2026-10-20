import 'package:citizen_app/app/citizen_app.dart';
import 'package:citizen_app/data/citizen_repository.dart';
import 'package:citizen_app/modules/family/family_controllers.dart';
import 'package:citizen_app/modules/requests/requests_controller.dart';
import 'package:citizen_app/modules/signup/signup_controller.dart';
import 'package:citizen_app/modules/sos/sos_controller.dart';
import 'package:citizen_app/services/sos_locator.dart';
import 'package:emr_core/emr_core.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

class FakeLocator implements SosLocator {
  (SosFix?, LocateFailure?) result = (const SosFix(lat: 15.58, lon: 32.55, accuracyM: 12), null);
  int calls = 0;

  @override
  Future<(SosFix?, LocateFailure?)> locate({Duration timeout = const Duration(seconds: 15)}) async {
    calls++;
    return result;
  }
}

class Rig {
  Rig() {
    final session = SessionService(secure: MemorySecureStore(), authApi: () => api.auth);
    api = ApiClient(config: const AppConfig(clientApp: ClientApp.citizen, version: '1', apiBaseUrl: 'http://t'), tokens: session, adapter: http);
    repo = CitizenRepository(api: api, cache: MemoryKeyValueStore(), now: () => DateTime.utc(2026, 10, 15, 9));
  }

  final http = FakeAdapter();
  final locator = FakeLocator();
  final net = ConnectivityService(FakeConnectivity());
  late final ApiClient api;
  late final CitizenRepository repo;

  final opened = <RequestArgs>[];

  SosController sos() => SosController(
        repo: repo,
        locator: locator,
        net: net,
        retryDelays: const [Duration.zero, Duration.zero, Duration.zero],
        openRequest: opened.add,
      );
}

void main() {
  test('normalizeCitizenUsername turns typed phones into +249 and leaves usernames alone', () {
    expect(normalizeCitizenUsername('0912345003'), '+249912345003');
    expect(normalizeCitizenUsername('091 234 5003'), '+249912345003');
    expect(normalizeCitizenUsername('+249912345003'), '+249912345003');
    expect(normalizeCitizenUsername('demo.citizen'), 'demo.citizen');
    expect(normalizeCitizenUsername('12345'), '12345', reason: 'not a phone: sent as typed');
  });

  group('SosController', () {
    late Rig r;
    setUp(() => r = Rig());

    test('sends location + note with an idempotency key', () async {
      r.http.reply('POST /api/v1/citizen/requests', 200, {'id': 'req-1', 'statusCode': 'received'});
      final c = r.sos();
      await c.send(note: '  chest pain  ');

      final req = r.http.calls('POST /api/v1/citizen/requests').single;
      expect(IdempotencyKey.isValid(req.headers['Idempotency-Key'] as String), isTrue);
      expect(r.http.bodies.single, {'lon': 32.55, 'lat': 15.58, 'accuracyM': 12.0, 'note': 'chest pain'});
      expect(c.phase.value, SosPhase.idle);
      expect(c.error.value, isNull);
      expect(c.pendingKey, isNull, reason: 'a finished press forgets its key');
      expect(r.opened.single.id, 'req-1');
      expect(r.opened.single.justSent, isTrue);
    });

    test('network failures retry with the SAME key and body, then succeed', () async {
      r.http.on('POST /api/v1/citizen/requests', (_, _) => const FakeReply.offline());
      r.http.on('POST /api/v1/citizen/requests', (_, _) => const FakeReply(503));
      r.http.reply('POST /api/v1/citizen/requests', 200, {'id': 'req-1'});
      await r.sos().send();

      final calls = r.http.calls('POST /api/v1/citizen/requests');
      expect(calls, hasLength(3));
      expect(calls.map((o) => o.headers['Idempotency-Key']).toSet(), hasLength(1));
      expect(r.locator.calls, 1, reason: 'location is taken once per press');
    });

    test('when it cannot get through: offer 999, keep the key, and the next press reuses it', () async {
      r.http.offlineAll = true;
      final c = r.sos();
      await c.send();
      expect(c.phase.value, SosPhase.failed);
      expect(c.offerCall999.value, isTrue);
      expect(c.error.value!.isNetwork, isTrue);
      final key = c.pendingKey;
      expect(key, isNotNull);

      r.http.offlineAll = false;
      r.http.reply('POST /api/v1/citizen/requests', 200, {'id': 'req-1'});
      await c.send();
      expect(r.http.calls('POST /api/v1/citizen/requests').single.headers['Idempotency-Key'], key);
      expect(r.locator.calls, 1);
    });

    test('too many open requests opens the existing one instead', () async {
      r.http.reply('POST /api/v1/citizen/requests', 429, err('CITIZEN_OPEN_REQUESTS'));
      r.http.reply('GET /api/v1/citizen/requests', 200, {
        'content': [
          {'id': 'old-closed', 'statusCode': 'closed'},
          {'id': 'open-1', 'statusCode': 'ambulance_coming'},
        ],
        'hasNext': false,
      });
      final c = r.sos();
      await c.send();
      expect(r.http.calls('POST /api/v1/citizen/requests'), hasLength(1), reason: '429 is not retried');
      expect(r.http.calls('GET /api/v1/citizen/requests'), hasLength(1));
      expect(c.error.value, isNull);
      expect(c.phase.value, SosPhase.idle);
      expect(r.opened.single.id, 'open-1');
      expect(r.opened.single.justSent, isFalse);
    });

    test('a suspended citizen sees the message and 999', () async {
      r.http.reply('POST /api/v1/citizen/requests', 403, err('CITIZEN_SUSPENDED', en: 'Suspended'));
      final c = r.sos();
      await c.send();
      expect(c.error.value!.code, 'CITIZEN_SUSPENDED');
      expect(c.offerCall999.value, isTrue);
      expect(c.pendingKey, isNull);
    });

    test('no location: nothing is sent and 999 is offered', () async {
      r.locator.result = (null, LocateFailure.denied);
      final c = r.sos();
      await c.send();
      expect(r.http.requests, isEmpty);
      expect(c.locationProblem.value, LocateFailure.denied);
      expect(c.offerCall999.value, isTrue);
    });

    test('a stale (last known) fix is still sent but flagged', () async {
      r.locator.result = (const SosFix(lat: 1, lon: 2, stale: true), null);
      r.http.reply('POST /api/v1/citizen/requests', 200, {'id': 'x'});
      final c = r.sos();
      await c.send();
      expect(c.staleFix.value, isTrue);
      expect(r.http.calls('POST /api/v1/citizen/requests'), hasLength(1));
    });

    test('a note over 2000 characters is refused on the phone', () async {
      final c = r.sos();
      await c.send(note: 'x' * 2001);
      expect(r.http.requests, isEmpty);
      expect(c.error.value!.code, 'NOTE_TOO_LONG');
    });

    test('offline at the moment of the press: 999 is offered at once', () async {
      final net = await ConnectivityService(FakeConnectivity(false)).init();
      r.http.offlineAll = true;
      final c = SosController(repo: r.repo, locator: r.locator, net: net, retryDelays: const [], openRequest: r.opened.add);
      final f = c.send();
      expect(c.offerCall999.value, isTrue);
      await f;
    });
  });

  group('Requests', () {
    late Rig r;
    setUp(() => r = Rig());

    Map<String, Object?> page(List<String> ids, {required bool hasNext, int p = 0}) => {
          'content': [for (final id in ids) {'id': id, 'statusCode': 'received', 'statusEn': 'Received', 'statusAr': 'استلم'}],
          'page': p,
          'size': 2,
          'hasNext': hasNext,
          'totalElements': null,
        };

    test('pages with hasNext and never duplicates rows', () async {
      r.http.on('GET /api/v1/citizen/requests', (o, _) {
        final p = int.parse('${o.queryParameters['page']}');
        return FakeReply(200, p == 0 ? page(['a', 'b'], hasNext: true) : page(['b', 'c'], hasNext: false, p: 1));
      });
      final c = RequestsController(repo: r.repo, pageSize: 2);
      await c.reload();
      expect(c.rows.map((x) => x.id), ['a', 'b']);
      expect(c.hasNext.value, isTrue);
      await c.more();
      expect(c.rows.map((x) => x.id), ['a', 'b', 'c']);
      expect(c.hasNext.value, isFalse);
      await c.more();
      expect(r.http.requests, hasLength(2), reason: 'no request past the last page');
    });

    test('an error with nothing loaded is kept for the error view', () async {
      r.http.offlineAll = true;
      final c = RequestsController(repo: r.repo);
      await c.reload();
      expect(c.error.value!.isNetwork, isTrue);
    });

    test('detail polls every 12 s and stops once closed', () {
      fakeAsync((async) {
        final statuses = ['received', 'ambulance_coming', 'closed'];
        var i = 0;
        r.http.on('GET /api/v1/citizen/requests/req-1', (_, _) {
          final s = statuses[i < statuses.length - 1 ? i++ : i];
          return FakeReply(200, {'statusCode': s, 'statusEn': s, 'statusAr': s});
        });
        final c = RequestDetailController(repo: r.repo, id: 'req-1')..onInit();
        async.elapse(const Duration(milliseconds: 10));
        expect(c.status.value!.code, RequestStatusCode.received);

        async.elapse(const Duration(seconds: 12));
        async.elapse(const Duration(milliseconds: 10));
        expect(c.status.value!.code, RequestStatusCode.ambulanceComing);

        async.elapse(const Duration(seconds: 12));
        async.elapse(const Duration(milliseconds: 10));
        expect(c.status.value!.isClosed, isTrue);
        expect(c.polling, isFalse);

        final calls = r.http.requests.length;
        async.elapse(const Duration(minutes: 2));
        expect(r.http.requests.length, calls, reason: 'no polling after closed');
        c.onClose();
      });
    });
  });

  group('Family and history', () {
    late Rig r;
    setUp(() => r = Rig());

    test('adding a dependant validates, sends, and remembers the pending link', () async {
      r.http.reply('POST /api/v1/citizen/dependants', 200, {'id': 'link-1', 'status': 'pending'});
      final c = FamilyController(repo: r.repo);
      expect(await c.add('12', DependantRelation.child), isFalse);
      expect(await c.add('1234567', null), isFalse);
      expect(c.fieldErrors.keys, ['relation']);
      expect(await c.add(' 1234567 ', DependantRelation.legalGuardian), isTrue);

      expect(r.http.bodies.single, {'childNationalId': '1234567', 'relation': 'legal_guardian'});
      expect((await r.repo.dependants()).single.status, 'pending');
    });

    test('history not verified is its own state, not an error', () async {
      r.http.reply('GET /api/v1/citizen/history', 403, err('CITIZEN_HISTORY_NOT_VERIFIED'));
      final c = HistoryController(repo: r.repo);
      await c.reload();
      expect(c.notVerified.value, isTrue);
      expect(c.error.value, isNull);
    });

    test('history rows load when verified', () async {
      r.http.reply('GET /api/v1/citizen/history', 200, {
        'content': [
          {'startedAt': '2026-10-01T10:00:00Z', 'caseNumber': 'KH-1', 'hospitalNameEn': 'Riyadh'},
        ],
        'hasNext': false,
      });
      final c = HistoryController(repo: r.repo);
      await c.reload();
      expect(c.history.value.visits.content.single.title('en'), 'KH-1', reason: 'an older single-page answer is read as the visits');
    });

    test('history is four pages: visits, diagnoses, check results, conditions', () async {
      Map<String, Object?> page(List<Map<String, Object?>> rows, {bool next = false}) => {'content': rows, 'hasNext': next};
      r.http.reply('GET /api/v1/citizen/history', 200, {
        'patientId': 'p-1',
        'visits': page([
          {'id': 'v1', 'startedAt': '2026-10-01T10:00:00Z', 'endedAt': null, 'endType': null, 'dischargeNote': 'Home'},
        ], next: true),
        'diagnoses': page([
          {'id': 'd1', 'icd10Code': 'S82', 'description': 'Fracture', 'kind': 'final', 'recordedAt': '2026-10-01T10:00:00Z'},
        ]),
        'checkResults': page([
          {'id': 'c1', 'checkCode': 'HB', 'resultValue': '12', 'resultUnit': 'g/dL', 'doneAt': '2026-10-01T10:00:00Z'},
        ]),
        'conditions': page([
          {'id': 'k1', 'kind': 'allergy', 'name': 'Penicillin', 'recordedAt': '2026-10-01T10:00:00Z'},
        ]),
      });
      final c = HistoryController(repo: r.repo);
      await c.reload();
      final h = c.history.value;
      expect(h.patientId, 'p-1');
      expect(h.visits.content, hasLength(1));
      expect(h.diagnoses.content.single.raw['description'], 'Fracture');
      expect(h.checkResults.content.single.raw['resultValue'], '12');
      expect(h.conditions.content.single.raw['kind'], 'allergy');
      expect(c.hasNext, isTrue);
    });

    test('profile falls back to the cached copy offline', () async {
      r.http.reply('GET /api/v1/citizen/me', 200, {'fullNameEn': 'Demo', 'phone': '+249912345003', 'identityStatus': 'phone_verified'});
      final c = ProfileController(repo: r.repo);
      await c.load();
      r.http.offlineAll = true;
      final offline = ProfileController(repo: r.repo);
      await offline.load();
      expect(offline.profile.value!.fullNameEn, 'Demo');
      expect(offline.error.value!.isNetwork, isTrue);
    });
  });

  group('SignUpController', () {
    late Rig r;
    setUp(() => r = Rig());

    test('the Arabic name must have Arabic letters, and the password at least 12 characters', () async {
      final c = SignUpController(repo: r.repo);
      c.challengeId.value = 'ch-1';
      expect(
        await c.finish(code: '123456', nationalId: '1234567', fullNameAr: 'Ahmed Ali', fullNameEn: '', password: 'Pass2026-Long9', repeat: 'Pass2026-Long9'),
        isFalse,
      );
      expect(c.fieldErrors.keys, ['fullNameAr']);
      expect(
        await c.finish(code: '123456', nationalId: '1234567', fullNameAr: 'أحمد علي', fullNameEn: '', password: 'Pass2026x', repeat: 'Pass2026x'),
        isFalse,
      );
      expect(c.fieldErrors.keys, ['password'], reason: '9 characters are refused by the server');
      expect(r.http.requests, isEmpty);
    });

    test('normalises the phone, then finishes with every field', () async {
      r.http.reply('POST /api/v1/citizen/sign-up/start', 200, {'challengeId': 'ch-1', 'expiresAt': '2026-10-15T09:05:00Z'});
      r.http.reply('POST /api/v1/citizen/sign-up/finish', 200, {'id': 'u', 'identityStatus': 'phone_verified', 'linkedPatient': false});
      final c = SignUpController(repo: r.repo);

      await c.start('abc');
      expect(c.fieldErrors.keys, ['phone']);
      await c.start('0912 345 678');
      expect(r.http.bodies.single, {'phone': '+249912345678'});
      expect(c.codeSent, isTrue);

      expect(
        await c.finish(code: '123456', nationalId: '1234567', fullNameAr: 'أحمد', fullNameEn: '', password: 'Pass2026-Long9', repeat: 'nope'),
        isFalse,
      );
      expect(c.fieldErrors.keys, ['repeat']);
      expect(
        await c.finish(code: '123456', nationalId: '1234567', fullNameAr: 'أحمد', fullNameEn: '', password: 'Pass2026-Long9', repeat: 'Pass2026-Long9'),
        isTrue,
      );
      expect(r.http.bodies.last, {'challengeId': 'ch-1', 'code': '123456', 'nationalId': '1234567', 'fullNameAr': 'أحمد', 'password': 'Pass2026-Long9'});
    });

    test('an existing account offers "sign in" instead', () async {
      r.http.reply('POST /api/v1/citizen/sign-up/start', 409, err('CITIZEN_PHONE_ACCOUNT_EXISTS'));
      final c = SignUpController(repo: r.repo);
      await c.start('0912345678');
      expect(c.accountExists.value, isTrue);
      expect(c.codeSent, isFalse);
    });
  });
}
