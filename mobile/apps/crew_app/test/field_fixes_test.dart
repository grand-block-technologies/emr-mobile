import 'dart:async';
import 'dart:convert';

import 'package:crew_app/app/crew_routes.dart';
import 'package:crew_app/data/crew_repository.dart';
import 'package:crew_app/modules/home/crew_controller.dart';
import 'package:crew_app/services/pin_service.dart';
import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'crew_app_flow_test.dart' show Booted, boot, driverMe, finish, medicMe, pumpCrew;
import 'helpers/fakes.dart';

Map<String, Object?> shiftWith(List<String> roles) => {
  'shift': {
    'id': 's-1',
    'ambulanceId': 'a-1',
    'plateNumber': 'DEMO-11',
    'crew': [
      for (final (i, r) in roles.indexed)
        {'userId': 'u$i', 'role': r, 'fullNameEn': 'Person $i', 'me': i == 0},
    ],
  },
};

const medicines = [
  {'code': 'ASPIRIN', 'nameAr': 'أسبرين', 'nameEn': 'Aspirin'},
  {'code': 'PARACETAMOL', 'nameAr': 'باراسيتامول', 'nameEn': 'Paracetamol'},
];

/// Opens the app unlocked, on a shift, with a job in [status].
Future<Booted> openJob(
  WidgetTester tester, {
  required Map<String, Object?> me,
  String? status,
  List<String>? roles = const ['driver'],
  bool alerts = true,
}) async {
  final secure = MemorySecureStore();
  await PinService(secure, iterations: 100).remember('1357');
  final b = await boot(
    tester,
    secure: {
      ...secure.values,
      SecureKeys.refreshToken: 'rt',
      SecureKeys.me: jsonEncode({...me, if (!alerts) 'features': <String>[]}),
    },
  );
  b.http.reply('POST /api/v1/auth/refresh', 200, {'accessToken': 'at', 'refreshToken': 'rt'});
  b.http.reply('POST /api/v1/crew/pin/verify', 200, {'verified': true});
  b.http.reply('GET /api/v1/crew/job', 200, status == null ? {'job': null} : jobWith(status));
  b.http.reply('GET /api/v1/crew/shifts/current', 200, roles == null ? {'shift': null} : shiftWith(roles));
  b.http.reply('GET /api/v1/medicines', 200, medicines);
  b.http.reply('POST /api/v1/dispatches/d-1/status', 200, {});
  b.http.reply('POST /api/v1/dispatches/d-1/alerts', 200, {'id': 'al-1'});
  b.http.reply('POST /api/v1/handovers', 200, {'id': 'h-1'});
  b.http.reply('POST /api/v1/patients', 200, {'id': 'pat-1', 'firstRecordStatus': 'not_started'});
  b.http.reply('POST /api/v1/patients/pat-1/observations', 200, {});
  b.http.reply('POST /api/v1/patients/pat-1/treatments', 200, {'id': 1});
  await pumpCrew(tester);
  await tester.enterText(find.byKey(const Key('pin')), '1357');
  await tester.tap(find.byKey(const Key('pin_submit')));
  await tester.pumpAndSettle();
  return b;
}

Future<void> tapKey(WidgetTester tester, Key k) async {
  await tester.ensureVisible(find.byKey(k));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(k));
}

/// The outbox sends in the background; pumping lets its fake HTTP calls finish.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

void main() {
  group('M1 handover', () {
    testWidgets('a paramedic hands the patient over; "Handover sent" shows', (tester) async {
      final b = await openJob(tester, me: medicMe, status: 'at_hospital', roles: ['paramedic', 'driver']);
      expect(find.byKey(const Key('open_handover')), findsOneWidget);

      await tester.tap(find.byKey(const Key('open_handover')));
      await tester.pumpAndSettle();
      expect(find.text('No patient registered'), findsOneWidget, reason: 'add the patient first');

      // Quick path: vitals creates the unknown patient (tested below); here use the repo directly.
      final repo = Get.find<CrewRepository>();
      await repo.registerPatient(
        const PatientBody(temporary: true, temporaryLabel: 'Unknown man', fullNameAr: 'مجهول', sex: 'male'),
        caseId: 'c-1',
      );
      Get.back<void>();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open_handover')));
      await tester.pumpAndSettle();

      final p = (await repo.patients()).single;
      await tester.enterText(find.byKey(Key('handover_summary_${p.ref}')), 'Stable, oxygen on');
      await tester.tap(find.byKey(Key('handover_send_${p.ref}')));
      await settle(tester);

      final body = b.http.bodiesOf('POST /api/v1/handovers').single! as Map;
      expect(body['caseId'], 'c-1');
      expect(body['dispatchId'], 'd-1');
      expect(body['patientId'], 'pat-1', reason: 'the offline {ref:} id resolved to the server id');
      expect(body['summary'], 'Stable, oxygen on');
      expect(b.http.calls('POST /api/v1/handovers').single.headers['Idempotency-Key'], isNotNull);
      expect(find.text('Handover sent'), findsOneWidget);

      // The ER confirms: the job now lists the handover as confirmed.
      b.http.set('GET /api/v1/crew/job', 200, {
        ...jobWith('at_hospital'),
        'handovers': [
          {'id': 'h-1', 'patientId': 'pat-1', 'status': 'confirmed', 'handedAt': '2026-10-20T08:00:00Z', 'receivedAt': '2026-10-20T08:05:00Z'},
        ],
      });
      await tester.pump(const Duration(seconds: 11));
      await settle(tester);
      expect(find.text('Received by the ER'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('a driver alone cannot finish before the handover; with a paramedic the driver only waits', (tester) async {
      await openJob(tester, me: driverMe, status: 'at_hospital', roles: ['driver']);
      final done = tester.widget<FilledButton>(find.descendant(of: find.byKey(const Key('step_completed')), matching: find.byType(FilledButton)));
      expect(done.onPressed, isNull, reason: 'no patient/handover yet');
      expect(find.byKey(const Key('open_handover')), findsOneWidget);
      await finish(tester);

      await openJob(tester, me: driverMe, status: 'at_hospital', roles: ['driver', 'paramedic']);
      expect(find.byKey(const Key('open_handover')), findsNothing, reason: 'the server would answer PARAMEDIC_ON_SHIFT');
      expect(find.byKey(const Key('handover_wait_hint')), findsOneWidget);
      final waiting = tester.widget<FilledButton>(find.descendant(of: find.byKey(const Key('step_completed')), matching: find.byType(FilledButton)));
      expect(waiting.onPressed, isNull, reason: 'the paramedic has not handed over yet');
      await finish(tester);

      // The paramedic's handover shows on the job: the driver can finish.
      final b = await openJob(tester, me: driverMe, status: 'at_hospital', roles: ['driver', 'paramedic']);
      b.http.set('GET /api/v1/crew/job', 200, {
        ...jobWith('at_hospital'),
        'handovers': [
          {'id': 'h-1', 'patientId': 'pat-1', 'fullNameEn': 'Unknown', 'status': 'pending', 'handedAt': '2026-10-20T08:00:00Z'},
        ],
      });
      await tester.pump(const Duration(seconds: 11));
      await settle(tester);
      expect(find.byKey(const Key('handover_sent_hint')), findsOneWidget);
      expect(find.text('The paramedic sent the handover. You can finish the job.'), findsOneWidget);
      final enabled = tester.widget<FilledButton>(find.descendant(of: find.byKey(const Key('step_completed')), matching: find.byType(FilledButton)));
      expect(enabled.onPressed, isNotNull);
      await finish(tester);
    });

    testWidgets('HANDOVER_REQUIRED opens the handover screen for a driver alone, not a toast', (tester) async {
      final b = await openJob(tester, me: driverMe, status: 'at_hospital', roles: ['driver']);
      b.http.set('POST /api/v1/dispatches/d-1/status', 409, err('HANDOVER_REQUIRED', en: 'Send the patient handover before finishing the job.'));
      await Get.find<CrewController>().advance(JobStatus.completed);
      await settle(tester);
      expect(Get.currentRoute, CrewRoutes.handover);
      await finish(tester);
    });

    testWidgets('completed is enabled once every patient has a handover sent', (tester) async {
      await openJob(tester, me: driverMe, status: 'at_hospital', roles: ['driver']);
      final repo = Get.find<CrewRepository>();
      final p = await repo.registerPatient(
        const PatientBody(temporary: true, temporaryLabel: 'U', fullNameAr: 'مجهول', sex: 'male'),
        caseId: 'c-1',
      );
      await repo.sendHandover(p, dispatchId: 'd-1', summary: 'ok');
      await Get.find<CrewController>().refreshHandover();
      await settle(tester);
      final btn = tester.widget<FilledButton>(find.descendant(of: find.byKey(const Key('step_completed')), matching: find.byType(FilledButton)));
      expect(btn.onPressed, isNotNull);
      await finish(tester);
    });
  });

  group('M2 end without transport', () {
    testWidgets('each reason is sent as noTransportReason; refused needs a note', (tester) async {
      for (final r in NoTransportReason.values) {
        final b = await openJob(tester, me: driverMe, status: 'on_scene');
        expect(find.text('End without transport'), findsOneWidget);
        await tester.tap(find.byKey(const Key('step_completed')));
        await tester.pumpAndSettle();
        expect(Get.currentRoute, CrewRoutes.noTransport);
        expect(find.byKey(const Key('reason_treated_at_scene')), findsOneWidget);

        await tester.tap(find.byKey(Key('reason_${r.wire}')));
        await tester.pumpAndSettle();
        if (r.noteRequired) {
          await tester.tap(find.byKey(const Key('no_transport_end')));
          await tester.pumpAndSettle();
          expect(find.text('Write a short note.'), findsOneWidget);
          expect(b.http.calls('POST /api/v1/dispatches/d-1/status'), isEmpty);
          await tester.enterText(find.byKey(const Key('no_transport_note')), 'Patient said no');
        }
        await tester.ensureVisible(find.byKey(const Key('no_transport_end')));
        await tester.tap(find.byKey(const Key('no_transport_end')));
        await tester.pumpAndSettle();
        expect(find.text('End the job?'), findsOneWidget);
        await tester.tap(find.byKey(const Key('complete_confirm')));
        await settle(tester);

        final body = b.http.bodiesOf('POST /api/v1/dispatches/d-1/status').single! as Map;
        expect(body['status'], 'completed');
        expect(body['noTransportReason'], r.wire);
        expect(body.containsKey('note'), r.noteRequired);
        expect(Get.currentRoute, CrewRoutes.home);
        await finish(tester);
      }
    });

    testWidgets('the reason is sent only from on_scene', (tester) async {
      final b = await openJob(tester, me: driverMe, status: 'en_route');
      await Get.find<CrewController>().advance(JobStatus.onScene);
      await settle(tester);
      final body = b.http.bodiesOf('POST /api/v1/dispatches/d-1/status').single! as Map;
      expect(body.containsKey('noTransportReason'), isFalse);
      await finish(tester);
    });

    testWidgets('request history comes from the server and opens offline from the cache', (tester) async {
      final b = await openJob(tester, me: medicMe, roles: ['paramedic', 'driver']);
      b.http.reply('GET /api/v1/crew/jobs', 200, {
        'content': [
          {
            'dispatchId': 'd-9',
            'caseNumber': 'KH-2026-000099',
            'priority': 'P1',
            'complaint': 'Chest pain',
            'status': 'completed',
            'sentAt': '2026-10-19T08:00:00Z',
            'completedAt': '2026-10-19T09:00:00Z',
            'closingReason': 'false_alarm',
            'hospitalEn': 'Riyadh Hospital',
            'plateNumber': 'DEMO-11',
          },
          {'dispatchId': 'd-8', 'caseNumber': 'KH-2026-000098', 'status': 'cancelled', 'sentAt': '2026-10-18T08:00:00Z'},
        ],
        'page': 0,
        'size': 20,
        'hasNext': false,
      });
      await tapKey(tester, const Key('open_history'));
      await settle(tester);
      expect(Get.currentRoute, CrewRoutes.history);
      expect(find.text('KH-2026-000099'), findsOneWidget);
      expect(find.text('False alarm'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
      Get.back<void>();
      await tester.pumpAndSettle();

      b.http.setOffline('GET /api/v1/crew/jobs');
      await tapKey(tester, const Key('open_history'));
      await settle(tester);
      expect(find.text('KH-2026-000099'), findsOneWidget);
      expect(find.text('Offline: the last saved list.'), findsOneWidget);
      await finish(tester);
    });
  });

  group('M3 medicines and refused writes', () {
    testWidgets('a picked medicine is sent as its code', (tester) async {
      final b = await openJob(tester, me: medicMe, status: 'on_scene', roles: ['paramedic', 'driver']);
      final repo = Get.find<CrewRepository>();
      final p = await repo.registerPatient(
        const PatientBody(temporary: true, temporaryLabel: 'U', fullNameAr: 'مجهول', sex: 'male'),
        caseId: 'c-1',
      );
      expect(Get.find<CrewController>().medicines, hasLength(2), reason: 'loaded after unlock');
      unawaited(Get.toNamed<void>(CrewRoutes.patients));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('treatment_${p.ref}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('choice_kind_medicine')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('t_name')), findsNothing, reason: 'free text is replaced by the picker');
      await tester.tap(find.byKey(const Key('t_medicine')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('medicine_search')), 'اسب');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('medicine_PARACETAMOL')), findsNothing);
      await tester.tap(find.byKey(const Key('medicine_ASPIRIN')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('t_save')));
      await tester.tap(find.byKey(const Key('t_save')));
      await settle(tester);
      final body = b.http.bodiesOf('POST /api/v1/patients/pat-1/treatments').single! as Map;
      expect(body['kind'], 'medicine');
      expect(body['name'], 'ASPIRIN');
      await finish(tester);
    });

    testWidgets('a refused write shows in Not sent with the server message, then can be fixed', (tester) async {
      final b = await openJob(tester, me: medicMe, status: 'on_scene', roles: ['paramedic', 'driver']);
      final repo = Get.find<CrewRepository>();
      final outbox = Get.find<OutboxService>();
      final p = await repo.registerPatient(
        const PatientBody(temporary: true, temporaryLabel: 'U', fullNameAr: 'مجهول', sex: 'male'),
        caseId: 'c-1',
      );
      await settle(tester);
      b.http.set('POST /api/v1/patients/pat-1/treatments', 400, err('MEDICINE_INVALID', en: 'Pick a medicine from the list'));
      await repo.recordEntry(p, 'entry_treatment', detail: 'Aspirin 300 mg');
      await repo.addTreatment(
        p,
        const TreatmentBody(givenAt: '2026-10-20T08:24:00Z', caseId: 'c-1', kind: 'medicine', name: 'Aspirin 300 mg'),
      );
      await settle(tester);

      expect(outbox.rejected, hasLength(1));
      expect(outbox.sync.value.allSent, isFalse, reason: 'must not say all sent');
      unawaited(Get.toNamed<void>(CrewRoutes.patients));
      await tester.pumpAndSettle();
      expect(find.text('Not sent'), findsWidgets);
      expect(find.text('Pick a medicine from the list'), findsWidgets);
      expect(find.textContaining('Not saved'), findsOneWidget, reason: 'the timeline line is marked');

      // Fix: pick the right medicine and resend.
      b.http.set('POST /api/v1/patients/pat-1/treatments', 200, {'id': 2});
      await tester.tap(find.byKey(Key('resend_${outbox.rejected.single.item.seq}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('medicine_ASPIRIN')));
      await settle(tester);
      expect((b.http.bodiesOf('POST /api/v1/patients/pat-1/treatments').last! as Map)['name'], 'ASPIRIN');
      expect(outbox.rejected, isEmpty);
      expect(find.textContaining('Not saved'), findsNothing);
      await finish(tester);
    });

    testWidgets('a refused write can be deleted on purpose', (tester) async {
      final b = await openJob(tester, me: medicMe, status: 'on_scene', roles: ['paramedic', 'driver']);
      final outbox = Get.find<OutboxService>();
      b.http.set('POST /api/v1/patients', 400, err('VALIDATION_ERROR'));
      await Get.find<CrewRepository>().registerPatient(
        const PatientBody(temporary: true, temporaryLabel: 'U', fullNameAr: 'مجهول', sex: 'male'),
        caseId: 'c-1',
      );
      await settle(tester);
      expect(outbox.rejected, hasLength(1));
      unawaited(Get.toNamed<void>(CrewRoutes.patients));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('discard_${outbox.rejected.single.item.seq}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('discard_confirm')));
      await tester.pumpAndSettle();
      expect(outbox.rejected, isEmpty);
      await finish(tester);
    });
  });

  group('client notes (paramedic)', () {
    testWidgets('alerts are multi-select and each type is its own alert', (tester) async {
      final b = await openJob(tester, me: medicMe, status: 'on_scene', roles: ['paramedic', 'driver']);
      await tapKey(tester, const Key('alert_stroke'));
      await tapKey(tester, const Key('alert_sepsis'));
      await tester.pumpAndSettle();
      await tapKey(tester, const Key('alert_submit'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('alert_send')));
      await settle(tester);
      expect(
        b.http.bodiesOf('POST /api/v1/dispatches/d-1/alerts').map((e) => (e! as Map)['type']),
        ['stroke', 'sepsis'],
      );
      await finish(tester);
    });

    testWidgets('alerts are hidden when the admin switched the feature off', (tester) async {
      await openJob(tester, me: medicMe, status: 'on_scene', roles: ['paramedic', 'driver'], alerts: false);
      expect(find.byKey(const Key('alert_stroke')), findsNothing);
      await finish(tester);
    });

    testWidgets('"Add vitals" needs no patient form: it asks only the age, registers an unknown patient and opens vitals', (tester) async {
      final b = await openJob(tester, me: medicMe, status: 'on_scene', roles: ['paramedic', 'driver']);
      await tapKey(tester, const Key('quick_vitals'));
      await tester.pumpAndSettle();
      // The server refuses an unknown patient without an estimated age, so it is asked first.
      await tester.tap(find.byKey(const Key('quick_age_ok')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('quick_age')), findsOneWidget, reason: 'an empty age is not accepted');
      await tester.enterText(find.byKey(const Key('quick_age')), '40');
      await tester.tap(find.byKey(const Key('quick_age_ok')));
      await tester.pumpAndSettle();
      expect(Get.currentRoute, CrewRoutes.vitals);
      expect(find.byKey(const Key('vitals_added_note')), findsNothing, reason: 'no note before the first reading');
      await tester.enterText(find.byKey(const Key('v_heartRate')), '112');
      await tapKey(tester, const Key('v_save'));
      await settle(tester);
      expect(b.http.calls('POST /api/v1/patients'), hasLength(1));
      expect((b.http.bodiesOf('POST /api/v1/patients').single! as Map)['estimatedAge'], 40);
      expect((b.http.bodiesOf('POST /api/v1/patients/pat-1/observations').single! as Map)['heartRate'], 112);

      // A second tap reuses the one patient instead of adding another.
      expect(Get.currentRoute, CrewRoutes.home, reason: 'saving goes back to the job');
      await tapKey(tester, const Key('quick_vitals'));
      await tester.pumpAndSettle();
      expect(Get.currentRoute, CrewRoutes.vitals);
      expect(find.byKey(const Key('vitals_added_note')), findsOneWidget, reason: 'the medic is told this adds a new reading');
      expect(b.http.calls('POST /api/v1/patients'), hasLength(1));
      await finish(tester);
    });

    testWidgets('oxygen alone is refused on the phone, not by the server', (tester) async {
      final b = await openJob(tester, me: medicMe, status: 'on_scene', roles: ['paramedic', 'driver']);
      await tapKey(tester, const Key('quick_vitals'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('quick_age')), '40');
      await tester.tap(find.byKey(const Key('quick_age_ok')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(SwitchListTile));
      await tester.tap(find.byType(SwitchListTile));
      await tester.ensureVisible(find.byKey(const Key('v_diastolic')));
      await tester.enterText(find.byKey(const Key('v_diastolic')), '80');
      await tapKey(tester, const Key('v_save'));
      await tester.pumpAndSettle();
      expect(b.http.calls('POST /api/v1/patients/pat-1/observations'), isEmpty);
      expect(Get.currentRoute, CrewRoutes.vitals);
      await finish(tester);
    });
  });

  group('M4', () {
    testWidgets('a paramedic alone is told to wait for a driver', (tester) async {
      await openJob(tester, me: medicMe, roles: ['paramedic']);
      expect(find.byKey(const Key('waiting_driver')), findsOneWidget);
      expect(find.textContaining('Jobs can only be sent with a driver'), findsOneWidget);
      await finish(tester);

      await openJob(tester, me: medicMe, roles: ['paramedic', 'driver']);
      expect(find.byKey(const Key('waiting_driver')), findsNothing);
      await finish(tester);
    });

    testWidgets('a typed shift code must be 6 digits; nothing is sent otherwise', (tester) async {
      final b = await openJob(tester, me: driverMe, roles: null);
      await tester.tap(find.text('Enter the code by hand'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('qr_manual')), '12345');
      await tester.tap(find.byKey(const Key('qr_manual_start')));
      await tester.pumpAndSettle();
      expect(b.http.calls('POST /api/v1/crew/shifts'), isEmpty);
      expect(find.textContaining('Check the number on the ambulance'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('SHIFT_CODE_NOT_FOUND clears the field; a busy ambulance says to join later', (tester) async {
      final b = await openJob(tester, me: driverMe, roles: null);
      b.http.reply('POST /api/v1/crew/shifts', 404, err('SHIFT_CODE_NOT_FOUND'));
      b.http.reply('POST /api/v1/crew/shifts/current/join', 400, err('AMBULANCE_UNAVAILABLE', en: 'The ambulance is on a job'));
      await tester.tap(find.text('Enter the code by hand'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('qr_manual')), '482913');
      await tester.tap(find.byKey(const Key('qr_manual_start')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Check the number on the ambulance'), findsOneWidget);
      expect(tester.widget<TextField>(find.byKey(const Key('qr_manual'))).controller!.text, isEmpty);

      await tester.enterText(find.byKey(const Key('qr_manual')), '482913');
      await tester.tap(find.byKey(const Key('qr_manual_join')));
      await tester.pumpAndSettle();
      expect(find.textContaining('The ambulance is on a job'), findsOneWidget);
      expect(find.textContaining('Join after this job ends'), findsOneWidget);
      await finish(tester);
    });
  });
}
