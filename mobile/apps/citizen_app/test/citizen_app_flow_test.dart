import 'dart:io';

import 'package:citizen_app/app/citizen_app.dart';
import 'package:citizen_app/app/citizen_routes.dart';
import 'package:citizen_app/app/citizen_translations.dart';
import 'package:citizen_app/modules/sos/sos_view.dart';
import 'package:citizen_app/services/sos_locator.dart';
import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'helpers/fakes.dart';

class FixedLocator implements SosLocator {
  @override
  Future<(SosFix?, LocateFailure?)> locate({Duration timeout = const Duration(seconds: 15)}) async =>
      (const SosFix(lat: 15.58, lon: 32.55, accuracyM: 9), null);
}

const citizenMe = {
  'id': 'c1',
  'username': '+249912345003',
  'fullNameAr': 'مواطن تجريبي',
  'fullNameEn': 'Demo Citizen',
  'role': 'CITIZEN',
  'preferredLanguage': 'ar',
  'scopes': <Object>[],
  'stateCodes': <Object>[],
  'mustChangePassword': false,
};

Future<FakeAdapter> boot(WidgetTester tester) async {
  Get.reset();
  Get.testMode = true;
  SosPulse.enabled = false;
  final http = FakeAdapter();
  await bootstrapCore(
    config: const AppConfig(clientApp: ClientApp.citizen, version: '1.0.0', apiBaseUrl: 'http://t'),
    flow: citizenFlowConfig(),
    overrides: CoreOverrides(
      secure: MemorySecureStore(),
      connectivity: FakeConnectivity(),
      adapter: http,
      outboxStore: MemoryKeyValueStore(),
      cacheStore: MemoryKeyValueStore(),
    ),
  );
  registerCitizenServices(locator: FixedLocator());
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(EmrApp(title: 't', pages: citizenPages(), translations: citizenTranslations));
  await tester.pumpAndSettle();
  return http;
}

Future<void> finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await Get.deleteAll(force: true);
  await tester.pump(const Duration(minutes: 1));
}

void main() {
  testWidgets('phone login (Arabic, RTL) → SOS → request screen with the server status', (tester) async {
    final http = await boot(tester);
    http.reply('POST /api/v1/auth/login', 200, {'step': 'signed_in', 'accessToken': 'at', 'refreshToken': 'rt'});
    http.reply('GET /api/v1/me', 200, citizenMe);
    http.reply('GET /api/v1/citizen/me', 200, {'fullNameAr': 'مواطن تجريبي', 'phone': '+249912345003', 'identityStatus': 'phone_verified'});
    http.reply('GET /api/v1/citizen/requests', 200, {'content': <Object>[], 'hasNext': false});
    http.reply('POST /api/v1/citizen/requests', 200, {'id': 'req-9', 'statusCode': 'received'});
    http.reply('GET /api/v1/citizen/requests/req-9', 200, {
      'statusCode': 'received',
      'statusAr': 'تم استلام طلبك، سيتصل بك مركز البلاغات',
      'statusEn': 'Request received; the call centre will call you',
      'updatedAt': '2026-10-15T07:00:00Z',
    });

    expect(find.text('اسم المستخدم أو رقم الهاتف'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byKey(const Key('login_username')))), TextDirection.rtl);

    await tester.enterText(find.byKey(const Key('login_username')), '0912345003');
    await tester.enterText(find.byKey(const Key('login_password')), 'Demo-Pass-2026');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    expect((http.bodies.first! as Map)['username'], '+249912345003');
    expect((http.bodies.first! as Map)['clientApp'], 'citizen_app');
    expect(Get.currentRoute, CitizenRoutes.home);
    expect(find.text('طلب إسعاف'), findsOneWidget);

    await tester.tap(find.text('ماذا حدث؟ (اختياري)'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('sos_note')), 'سقط رجل');
    await tester.ensureVisible(find.byKey(const Key('sos_button')));
    await tester.tap(find.byKey(const Key('sos_button')));
    await tester.pumpAndSettle();

    final sos = http.calls('POST /api/v1/citizen/requests').single;
    expect((http.bodiesOf('POST /api/v1/citizen/requests').single! as Map)['note'], 'سقط رجل');
    expect(sos.headers['Idempotency-Key'], isNotNull);
    expect(Get.currentRoute, CitizenRoutes.request);
    expect(find.text('أبقِ هاتفك متاحًا، سيتصل بك مركز البلاغات.'), findsOneWidget);
    expect(find.byKey(const Key('request_status')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('request_status'))).data, 'تم استلام طلبك، سيتصل بك مركز البلاغات');
    await finish(tester);
  });

  testWidgets('sign-up: phone → details → back to login with the phone filled in', (tester) async {
    final http = await boot(tester);
    http.reply('POST /api/v1/citizen/sign-up/start', 200, {'challengeId': 'ch-1'});
    http.reply('POST /api/v1/citizen/sign-up/finish', 200, {'id': 'u', 'identityStatus': 'phone_verified'});

    await tester.tap(find.byKey(const Key('signup_link')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('signup_phone')), '0912345678');
    await tester.tap(find.byKey(const Key('signup_send')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('signup_code')), '123456');
    await tester.enterText(find.byKey(const Key('signup_nid')), '1234567');
    await tester.enterText(find.byKey(const Key('signup_name_ar')), 'أحمد علي');
    await tester.enterText(find.byKey(const Key('signup_pass')), 'Pass2026x');
    await tester.enterText(find.byKey(const Key('signup_repeat')), 'Pass2026x');
    await tester.ensureVisible(find.byKey(const Key('signup_finish')));
    await tester.tap(find.byKey(const Key('signup_finish')));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AuthRoutes.login);
    expect(find.text('تم إنشاء الحساب. سجّل الدخول برقم هاتفك.'), findsOneWidget);
    expect(find.text('+249912345678'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('add-family sheet has the white surface (not transparent) and validates', (tester) async {
    final http = await boot(tester);
    http.reply('POST /api/v1/auth/login', 200, {'step': 'signed_in', 'accessToken': 'at', 'refreshToken': 'rt'});
    http.reply('GET /api/v1/me', 200, {...citizenMe, 'preferredLanguage': 'en'});
    http.reply('GET /api/v1/citizen/me', 200, {'fullNameEn': 'Demo', 'phone': '+249912345003', 'identityStatus': 'phone_verified'});
    http.reply('GET /api/v1/citizen/requests', 200, {'content': <Object>[], 'hasNext': false});
    await tester.enterText(find.byKey(const Key('login_username')), 'demo.citizen');
    await tester.enterText(find.byKey(const Key('login_password')), 'Demo-Pass-2026');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tab_family')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('family_add')));
    await tester.pumpAndSettle();

    final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(sheet.backgroundColor, AppColors.surface);
    await tester.tap(find.byKey(const Key('family_save')));
    await tester.pumpAndSettle();
    expect(find.text('The national ID is 6 to 15 digits.'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('a crew account in the citizen app is told to use the other app', (tester) async {
    final http = await boot(tester);
    http.reply('POST /api/v1/auth/login', 403, err('WRONG_CLIENT_APP', ar: 'استخدم التطبيق المخصص لدورك.', en: 'Use the app assigned to your role.'));
    await tester.enterText(find.byKey(const Key('login_username')), 'demo.driver1');
    await tester.enterText(find.byKey(const Key('login_password')), 'Demo-Pass-2026');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();
    expect(find.text('استخدم التطبيق المخصص لدورك.'), findsOneWidget);
    await finish(tester);
  });

  group('translations', () {
    final merged = AppTranslations(extra: citizenTranslations).keys;

    test('Arabic and English citizen keys match', () {
      expect(citizenTranslations['ar']!.keys.toSet(), citizenTranslations['en']!.keys.toSet());
    });

    test('every literal key used in lib/ is translated', () {
      final pattern = RegExp(r"'([a-z0-9_]+)'\.(tr|trParams)\b");
      final missing = <String>{};
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        for (final m in pattern.allMatches(f.readAsStringSync())) {
          for (final lang in ['ar', 'en']) {
            if (!merged[lang]!.containsKey(m.group(1))) missing.add('$lang:${m.group(1)} (${f.path})');
          }
        }
      }
      expect(missing, isEmpty);
    });

    test('every dynamic key family is translated', () {
      final keys = [
        for (final c in RequestStatusCode.values.where((c) => c != RequestStatusCode.unknown)) 'rs_${c.wire}',
        for (final r in DependantRelation.values) 'relation_${r.wire}',
        for (final f in LocateFailure.values) 'sos_location_${f.name}',
        'link_pending',
        'link_verified',
        for (final i in ['phone_verified', 'id_card_verified', 'suspended', 'unknown']) 'identity_$i',
        for (final s in ['history_step_1', 'history_step_2', 'history_step_3']) s,
      ];
      for (final lang in ['ar', 'en']) {
        expect(keys.where((k) => !merged[lang]!.containsKey(k)), isEmpty, reason: lang);
      }
    });
  });
}
