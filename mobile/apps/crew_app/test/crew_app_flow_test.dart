import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crew_app/app/crew_app.dart';
import 'package:crew_app/app/crew_routes.dart';
import 'package:crew_app/app/crew_translations.dart';
import 'package:crew_app/modules/home/crew_controller.dart';
import 'package:crew_app/modules/job/job_widgets.dart';
import 'package:crew_app/services/pin_service.dart';
import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'helpers/fakes.dart';

const driverMe = {
  'id': 'u8',
  'username': 'demo.driver1',
  'fullNameAr': 'سائق الرياض',
  'fullNameEn': 'Driver Riyadh',
  'role': 'DRIVER',
  'preferredLanguage': 'en',
  'scopes': <Object>[],
  'stateCodes': ['KH'],
  'mustChangePassword': false,
};

const medicMe = {
  'id': 'u9',
  'username': 'demo.medic1',
  'fullNameAr': 'مسعف الرياض',
  'fullNameEn': 'Medic Riyadh',
  'role': 'PARAMEDIC',
  'features': ['feature.crew_alerts'],
  'preferredLanguage': 'en',
  'scopes': <Object>[],
  'stateCodes': ['KH'],
  'mustChangePassword': false,
};

class Booted {
  Booted(this.http, this.secure, this.stomp, this.location);
  final FakeAdapter http;
  final MemorySecureStore secure;
  final FakeStomp stomp;
  final FakeLocation location;
}

Future<Booted> boot(WidgetTester tester, {Map<String, String>? secure, bool online = true}) async {
  Get.reset();
  Get.testMode = true;
  JobMap.showTiles = false;
  final b = Booted(FakeAdapter(), MemorySecureStore(secure), FakeStomp(), FakeLocation());
  await bootstrapCore(
    config: const AppConfig(clientApp: ClientApp.crew, version: '1.0.0', apiBaseUrl: 'http://t'),
    flow: crewFlowConfig(),
    withOutbox: true,
    overrides: CoreOverrides(
      secure: b.secure,
      connectivity: FakeConnectivity(online),
      adapter: b.http,
      outboxStore: MemoryKeyValueStore(),
      cacheStore: MemoryKeyValueStore(),
    ),
  );
  registerCrewServices(location: b.location, stomp: b.stomp);
  return b;
}

Future<void> pumpCrew(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(EmrApp(title: 't', pages: crewPages(), translations: crewTranslations));
  await tester.pumpAndSettle();
}

Future<void> finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await Get.deleteAll(force: true);
  await tester.pump(const Duration(minutes: 1));
}

void main() {
  testWidgets('fresh login → set PIN → start shift → new job alarm → swipe → steps', (tester) async {
    final b = await boot(tester);
    b.http.reply('POST /api/v1/auth/login', 200, {'step': 'signed_in', 'accessToken': 'at', 'refreshToken': 'rt'});
    b.http.reply('GET /api/v1/me', 200, driverMe);
    b.http.reply('PUT /api/v1/crew/pin', 200, {'saved': true});
    b.http.reply('POST /api/v1/crew/shifts', 200, {'id': 's-1', 'ambulanceId': 'a-1'});
    // A tiny stateful server: the job reflects what the crew has sent.
    String? serverStatus;
    b.http.on('GET /api/v1/crew/job', (_, _) => FakeReply(200, serverStatus == null ? {'job': null} : jobWith(serverStatus!)));
    b.http.on('POST /api/v1/dispatches/d-1/confirm', (_, _) {
      serverStatus = 'confirmed';
      return const FakeReply(200, {});
    });
    b.http.on('POST /api/v1/dispatches/d-1/status', (_, body) {
      serverStatus = (body! as Map)['status'] as String;
      return const FakeReply(200, {});
    });
    await pumpCrew(tester);

    await tester.enterText(find.byKey(const Key('login_username')), 'demo.driver1');
    await tester.enterText(find.byKey(const Key('login_password')), 'Demo-Pass-2026');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    // No PIN on this phone yet → setup.
    expect(Get.currentRoute, CrewRoutes.pinSetup);
    await tester.enterText(find.byKey(const Key('pin')), '2468');
    await tester.enterText(find.byKey(const Key('pin_repeat')), '2468');
    await tester.tap(find.byKey(const Key('pin_submit')));
    await tester.pumpAndSettle();
    expect(b.http.bodiesOf('PUT /api/v1/crew/pin').single, {'pin': '2468'});
    expect(await Get.find<PinService>().hasVerifier(), isTrue);
    expect(Get.currentRoute, CrewRoutes.home);
    expect(find.text('Start your shift'), findsOneWidget);

    // Start the shift with the code typed by hand.
    await tester.tap(find.text('Enter the code by hand'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('qr_manual')), '482913');
    await tester.tap(find.byKey(const Key('qr_manual_start')));
    await tester.pumpAndSettle();
    // The "shift started" screen shows for two seconds, then the waiting screen.
    expect(find.text('Shift started'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Waiting for a job'), findsOneWidget);
    expect(find.text('On shift'), findsOneWidget);

    // A job arrives on the live queue → full-screen alarm.
    serverStatus = 'sent';
    b.stomp.event({'type': 'job.new', 'dispatchId': 'd-1'});
    await tester.pumpAndSettle();
    expect(find.text('New job'), findsOneWidget);
    expect(find.text('Motorbike accident, leg injury'), findsOneWidget);
    expect(find.text('Near the big mosque'), findsOneWidget);

    await tester.drag(find.byKey(const Key('swipe_thumb')), const Offset(1000, 0));
    await tester.pumpAndSettle();
    expect(b.http.calls('POST /api/v1/dispatches/d-1/confirm'), hasLength(1));
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('KH-2026-000003'), findsOneWidget);

    await tester.tap(find.byKey(const Key('step_en_route')));
    await tester.pumpAndSettle();
    expect(find.text('On the way'), findsOneWidget);
    await tester.tap(find.byKey(const Key('step_on_scene')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('step_leaving_scene')), findsOneWidget);
    expect(find.byKey(const Key('step_completed')), findsOneWidget, reason: 'treated-at-scene option');
    expect(
      b.http.bodiesOf('POST /api/v1/dispatches/d-1/status').map((e) => (e! as Map)['status']),
      ['en_route', 'on_scene'],
    );

    await finish(tester);
  });

  testWidgets('restored session offline asks for the PIN and unlocks with the local verifier', (tester) async {
    final secure = MemorySecureStore();
    await PinService(secure, iterations: 100).remember('1357');
    final b = await boot(
      tester,
      online: false,
      secure: {
        ...secure.values,
        SecureKeys.refreshToken: 'rt',
        SecureKeys.me: jsonEncode({...medicMe, 'role': 'DRIVER'}),
      },
    );
    b.http.offlineAll = true;
    await pumpCrew(tester);

    expect(Get.currentRoute, CrewRoutes.pinUnlock);
    await tester.enterText(find.byKey(const Key('pin')), '0000');
    await tester.tap(find.byKey(const Key('pin_submit')));
    await tester.pumpAndSettle();
    expect(find.text('Wrong PIN. 4 tries left.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('pin')), '1357');
    await tester.tap(find.byKey(const Key('pin_submit')));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, CrewRoutes.home);
    expect(find.byKey(const Key('open_patients')), findsNothing, reason: 'drivers do not get patient care');
    await finish(tester);
  });

  testWidgets('drivers with an active job see map and steps but NOT hospital alert or patient care', (tester) async {
    final secure = MemorySecureStore();
    await PinService(secure, iterations: 100).remember('1357');
    final b = await boot(
      tester,
      secure: {
        ...secure.values,
        SecureKeys.refreshToken: 'rt',
        SecureKeys.me: jsonEncode({...medicMe, 'role': 'DRIVER'}),
      },
    );
    b.http.reply('POST /api/v1/auth/refresh', 200, {'accessToken': 'at', 'refreshToken': 'rt'});
    b.http.reply('POST /api/v1/crew/pin/verify', 200, {'verified': true});
    b.http.reply('GET /api/v1/crew/job', 200, jobWith('en_route'));
    // The app asks for the current shift when unlocking; without one the crew is off shift.
    b.http.reply('GET /api/v1/crew/shifts/current', 200, {
      'shift': {'id': 's-1', 'ambulanceId': 'a-1', 'plateNumber': 'DEMO-11', 'crew': <Object>[]},
    });
    await pumpCrew(tester);

    await tester.enterText(find.byKey(const Key('pin')), '1357');
    await tester.tap(find.byKey(const Key('pin_submit')));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, CrewRoutes.home);
    expect(find.text('On the way'), findsOneWidget);
    expect(find.byKey(const Key('step_on_scene')), findsOneWidget);
    expect(find.text('Alert the hospital before arrival'), findsNothing);
    expect(find.byKey(const Key('alert_stroke')), findsNothing);
    expect(find.byKey(const Key('open_patients')), findsNothing);
    await finish(tester);
  });

  testWidgets('server down (5xx) falls back to the phone verifier to unlock', (tester) async {
    final secure = MemorySecureStore();
    await PinService(secure, iterations: 100).remember('1357');
    final b = await boot(tester, secure: {...secure.values, SecureKeys.refreshToken: 'rt', SecureKeys.me: jsonEncode(medicMe)});
    b.http.fallback = (_, _) => const FakeReply(530, '<html>origin down</html>');
    await pumpCrew(tester);
    await tester.enterText(find.byKey(const Key('pin')), '1357');
    await tester.tap(find.byKey(const Key('pin_submit')));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, CrewRoutes.home);
    await finish(tester);
  });

  testWidgets('a locked app cannot open crew screens', (tester) async {
    await boot(tester);
    await pumpCrew(tester);
    unawaited(Get.toNamed<void>(CrewRoutes.settings));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, CrewRoutes.pinUnlock);
    await finish(tester);
  });

  testWidgets('signing out with unsent changes warns how many will be lost', (tester) async {
    final secure = MemorySecureStore();
    await PinService(secure, iterations: 100).remember('1357');
    final b = await boot(tester, secure: {...secure.values, SecureKeys.refreshToken: 'rt', SecureKeys.me: jsonEncode(medicMe)});
    b.http.fallback = (_, _) => const FakeReply.offline();
    await pumpCrew(tester);
    await tester.enterText(find.byKey(const Key('pin')), '1357');
    await tester.tap(find.byKey(const Key('pin_submit')));
    await tester.pumpAndSettle();

    final outbox = Get.find<OutboxService>();
    await outbox.add(OutboxKind.status, '/api/v1/dispatches/x/status', {'status': 'en_route'});
    await outbox.add(OutboxKind.status, '/api/v1/dispatches/x/status', {'status': 'on_scene'});
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open_settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sign_out')));
    await tester.pumpAndSettle();
    expect(find.textContaining('2 changes have not been sent'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(Get.find<SessionService>().isSignedIn, isTrue);
    expect(Get.find<CrewController>().onShift, isFalse);
    await finish(tester);
  });

  group('translations', () {
    final merged = AppTranslations(extra: crewTranslations).keys;

    test('Arabic and English crew keys match', () {
      expect(crewTranslations['ar']!.keys.toSet(), crewTranslations['en']!.keys.toSet());
    });

    test('every literal key used in lib/ is translated', () {
      final pattern = RegExp(r"'([a-z0-9_]+)'\.(tr|trParams)\b");
      final missing = <String>{};
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        for (final m in pattern.allMatches(f.readAsStringSync())) {
          final key = m.group(1)!;
          for (final lang in ['ar', 'en']) {
            if (!merged[lang]!.containsKey(key)) missing.add('$lang:$key (${f.path})');
          }
        }
      }
      expect(missing, isEmpty);
    });

    test('every dynamic key family is translated', () {
      final keys = [
        for (final s in JobStatus.values) 'status_${s.wire}',
        for (final s in JobStatus.values.where((s) => s.index >= JobStatus.enRoute.index)) 'step_${s.wire}',
        for (final a in AlertType.values) 'alert_${a.wire}',
        for (final f in Vitals.byField.keys) 'vital_$f',
        for (final c in Vitals.consciousness) 'avpu_$c',
        for (final k in ['medicine', 'procedure', 'oxygen', 'fluid', 'other']) 'kind_$k',
        for (final r in ['oral', 'iv', 'im', 'sc', 'inhaled', 'topical', 'rectal', 'other']) 'route_$r',
        for (final s in ['male', 'female', 'unknown']) 'sex_$s',
        'role_DRIVER',
        'role_PARAMEDIC',
        'status_unknown',
        'entry_vitals',
        'entry_treatment',
      ];
      for (final lang in ['ar', 'en']) {
        expect(keys.where((k) => !merged[lang]!.containsKey(k)), isEmpty, reason: lang);
      }
    });
  });
}
