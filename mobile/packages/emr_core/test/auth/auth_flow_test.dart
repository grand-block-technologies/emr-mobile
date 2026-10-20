import 'dart:async';
import 'dart:convert';

import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../helpers/boot.dart';
import '../helpers/fake_adapter.dart';

void main() {
  tearDown(Get.reset);

  Future<void> login(WidgetTester tester, {String user = 'demo.driver1', String pass = 'Demo-Pass-2026'}) async {
    await tester.enterText(find.byKey(const Key('login_username')), user);
    await tester.enterText(find.byKey(const Key('login_password')), pass);
    await tester.ensureVisible(find.byKey(const Key('login_submit')));
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();
  }

  Future<void> enterCode(WidgetTester tester, String code) async {
    await tester.enterText(find.byKey(const Key('sms_code')), code);
    await tester.ensureVisible(find.byKey(const Key('sms_submit')));
    await tester.tap(find.byKey(const Key('sms_submit')));
    await tester.pumpAndSettle();
  }

  testWidgets('password → SMS code → home; sends app/device fields; applies the user language', (tester) async {
    final core = await bootCore(secureSeed: {SecureKeys.deviceId: 'dev-123'});
    core.http.reply('POST /api/v1/auth/login', 200, {'step': 'sms_code', 'challengeId': 'ch-1', 'expiresAt': '2026-10-15T08:00:00Z'});
    core.http.reply('POST /api/v1/auth/verify', 200, {'accessToken': 'at', 'refreshToken': 'rt', 'mustChangePassword': false});
    core.http.reply('GET /api/v1/me', 200, driverMe);

    await pumpEmrApp(tester);
    expect(find.text('تسجيل الدخول'), findsWidgets, reason: 'Arabic is the default before login');

    await login(tester);
    expect(core.http.bodies.first, {
      'username': 'demo.driver1',
      'password': 'Demo-Pass-2026',
      'deviceType': 'mobile',
      'clientApp': 'crew_app',
      'deviceId': 'dev-123',
      'appVersion': '1.0.0',
    });

    await enterCode(tester, '123456');
    expect(core.http.bodies[1], {'challengeId': 'ch-1', 'code': '123456'});
    expect(find.text('HOME'), findsOneWidget);
    expect(core.secure.values[SecureKeys.refreshToken], 'rt');
    expect(Get.locale!.languageCode, 'en', reason: 'preferredLanguage from /me');
    expect((jsonDecode(core.secure.values[SecureKeys.me]!) as Map<String, dynamic>)['username'], 'demo.driver1');
  });

  testWidgets('a signed_in login skips the SMS screen', (tester) async {
    final core = await bootCore();
    core.http.reply('POST /api/v1/auth/login', 200, {'step': 'signed_in', 'accessToken': 'at', 'refreshToken': 'rt', 'mustChangePassword': false});
    core.http.reply('GET /api/v1/me', 200, driverMe);
    await pumpEmrApp(tester);
    await login(tester);
    expect(find.text('HOME'), findsOneWidget);
    expect(core.http.calls('POST /api/v1/auth/verify'), isEmpty);
  });

  testWidgets('empty fields are caught before any request', (tester) async {
    final core = await bootCore();
    await pumpEmrApp(tester);
    await tester.ensureVisible(find.byKey(const Key('login_submit')));
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();
    expect(find.text('هذا الحقل مطلوب.'), findsNWidgets(2));
    expect(core.http.requests, isEmpty);
  });

  testWidgets('field errors follow a language switch (no stale Arabic after switching)', (tester) async {
    await bootCore();
    await pumpEmrApp(tester);
    await tester.ensureVisible(find.byKey(const Key('login_submit')));
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();
    expect(find.text('هذا الحقل مطلوب.'), findsNWidgets(2));

    // Same call the toggle makes (a tap would reassemble mid-pump, which the test binding forbids).
    unawaited(Get.find<LocaleService>().set('en'));
    await tester.pumpAndSettle();
    expect(find.text('هذا الحقل مطلوب.'), findsNothing);
    expect(find.text('This field is required.'), findsNWidgets(2));
  });

  testWidgets('a wrong password shows the server message in Arabic', (tester) async {
    final core = await bootCore();
    core.http.reply(
      'POST /api/v1/auth/login',
      401,
      errorBody('INVALID_CREDENTIALS', ar: 'اسم المستخدم أو كلمة المرور غير صحيحة.', en: 'The username or password is incorrect.'),
    );
    await pumpEmrApp(tester);
    await login(tester, pass: 'wrong');
    expect(find.text('اسم المستخدم أو كلمة المرور غير صحيحة.'), findsOneWidget);
    expect(find.textContaining('ref-'), findsNothing, reason: 'no reference on an expected error');
  });

  testWidgets('server field errors appear under the field', (tester) async {
    final core = await bootCore();
    core.http.reply('POST /api/v1/auth/login', 400, errorBody('VALIDATION_ERROR', fields: [
      {'field': 'username', 'code': 'INVALID', 'message_ar': 'اسم غير صالح', 'message_en': 'Bad username'},
    ]));
    await pumpEmrApp(tester);
    await login(tester);
    expect(find.text('اسم غير صالح'), findsOneWidget);
  });

  testWidgets('APP_UPDATE_REQUIRED opens the force-update screen', (tester) async {
    final core = await bootCore();
    core.http.reply('POST /api/v1/auth/login', 426, errorBody('APP_UPDATE_REQUIRED'));
    await pumpEmrApp(tester);
    await login(tester);
    expect(Get.currentRoute, AuthRoutes.forceUpdate);
    expect(find.text('يلزم تحديث التطبيق'), findsOneWidget);
  });

  testWidgets('a wrong code keeps the user on the SMS screen with the message', (tester) async {
    final core = await bootCore();
    core.http.reply('POST /api/v1/auth/login', 200, {'step': 'sms_code', 'challengeId': 'ch-1'});
    core.http.reply('POST /api/v1/auth/verify', 400, errorBody('INVALID_CODE', ar: 'الرمز غير صحيح', en: 'Wrong code'));
    await pumpEmrApp(tester);
    await login(tester);
    await enterCode(tester, '000000');
    expect(find.text('الرمز غير صحيح'), findsOneWidget);
    expect(Get.currentRoute, AuthRoutes.smsCode);

    await enterCode(tester, '12');
    expect(find.text('أدخل الرمز المكوّن من 6 أرقام.'), findsOneWidget);
    expect(core.http.calls('POST /api/v1/auth/verify'), hasLength(1), reason: 'short code never sent');
  });

  testWidgets('resend waits 60 s, swaps the challenge, and stops after 3', (tester) async {
    final core = await bootCore();
    core.http.reply('POST /api/v1/auth/login', 200, {'step': 'sms_code', 'challengeId': 'ch-1'});
    core.http.reply('POST /api/v1/auth/resend', 200, {'challengeId': 'ch-2'});
    core.http.reply('POST /api/v1/auth/verify', 200, {'accessToken': 'at', 'refreshToken': 'rt'});
    core.http.reply('GET /api/v1/me', 200, driverMe);
    await pumpEmrApp(tester);
    await login(tester);

    final c = Get.find<SmsCodeController>();
    expect(c.canResend, isFalse);
    expect(find.textContaining('60'), findsOneWidget);

    for (var i = 1; i <= 3; i++) {
      await tester.pump(const Duration(seconds: 61));
      expect(c.canResend, isTrue);
      await tester.tap(find.byKey(const Key('sms_resend')));
      await tester.pumpAndSettle();
      expect(c.resends.value, i);
    }
    await tester.pump(const Duration(seconds: 61));
    expect(c.canResend, isFalse, reason: 'at most 3 resends');
    expect(core.http.bodies.whereType<Map<String, dynamic>>().where((b) => b.containsKey('challengeId') && b.length == 1).length, 3);

    await enterCode(tester, '123456');
    expect(core.http.bodies.last, isNot(contains('code')), reason: 'last call is GET /me');
    expect(core.http.calls('POST /api/v1/auth/verify').length, 1);
    final verifyIndex = core.http.requests.indexWhere((r) => r.path == '/api/v1/auth/verify');
    expect(core.http.bodies[verifyIndex], {'challengeId': 'ch-2', 'code': '123456'});
  });

  testWidgets('mustChangePassword forces the change-password screen, then home', (tester) async {
    final core = await bootCore();
    core.http.reply('POST /api/v1/auth/login', 200, {'step': 'sms_code', 'challengeId': 'ch-1'});
    core.http.reply('POST /api/v1/auth/verify', 200, {'accessToken': 'at', 'refreshToken': 'rt', 'mustChangePassword': true});
    core.http.reply('POST /api/v1/auth/change-password', 204);
    core.http.reply('GET /api/v1/me', 200, driverMe);
    await pumpEmrApp(tester);
    await login(tester);
    await enterCode(tester, '123456');
    expect(Get.currentRoute, AuthRoutes.changePassword);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Demo-Pass-2026');
    await tester.enterText(fields.at(1), 'NewPass2026-Long9');
    await tester.enterText(fields.at(2), 'Different2026');
    await tester.ensureVisible(find.text('حفظ'));
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    expect(find.text('كلمتا المرور غير متطابقتين.'), findsOneWidget);
    expect(core.http.calls('POST /api/v1/auth/change-password'), isEmpty);

    await tester.enterText(fields.at(2), 'NewPass2026-Long9');
    await tester.ensureVisible(find.text('حفظ'));
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    expect(core.http.calls('POST /api/v1/auth/change-password'), hasLength(1));
    expect(find.text('HOME'), findsOneWidget);
    expect(core.session.status.value, SessionStatus.signedIn);
  });

  testWidgets('a role this app does not serve is signed out with "use the other app"', (tester) async {
    final core = await bootCore();
    core.http.reply('POST /api/v1/auth/login', 200, {'step': 'signed_in', 'accessToken': 'at', 'refreshToken': 'rt'});
    core.http.reply('GET /api/v1/me', 200, {...driverMe, 'role': 'CITIZEN', 'preferredLanguage': 'ar'});
    core.http.reply('POST /api/v1/auth/logout', 204);
    await pumpEmrApp(tester);
    await login(tester);
    expect(Get.currentRoute, AuthRoutes.login);
    expect(find.text('استخدم التطبيق المخصص لدورك.'), findsOneWidget);
    expect(core.secure.values.containsKey(SecureKeys.refreshToken), isFalse);
  });

  testWidgets('a saved session opens home offline from the cached profile', (tester) async {
    final core = await bootCore(online: false, secureSeed: {
      SecureKeys.refreshToken: 'rt',
      SecureKeys.me: jsonEncode(driverMe),
    });
    core.http.fallback = (_, _) => const FakeReply.offline();
    await pumpEmrApp(tester);
    expect(find.text('HOME'), findsOneWidget);
    expect(core.session.isSignedIn, isTrue);
    await Get.deleteAll(force: true); // stops the 30 s refresh retry timer
  });

  testWidgets('DEVICE_BLOCKED mid-session returns to login with the server message', (tester) async {
    final core = await bootCore(secureSeed: {SecureKeys.refreshToken: 'rt', SecureKeys.me: jsonEncode(driverMe)});
    core.http.reply('POST /api/v1/auth/refresh', 200, {'accessToken': 'at'});
    await pumpEmrApp(tester);
    expect(find.text('HOME'), findsOneWidget);

    core.http.reply('GET /api/v1/crew/job', 401, errorBody('DEVICE_BLOCKED', ar: 'تم حظر الجهاز', en: 'This device is blocked'));
    Object? thrown;
    unawaited(Get.find<ApiClient>().crew.job().then<void>((_) {}, onError: (Object e) => thrown = e));
    await tester.pumpAndSettle();
    expect(ApiError.of(thrown!).code, 'DEVICE_BLOCKED');

    expect(Get.currentRoute, AuthRoutes.login);
    expect(find.text('This device is blocked'), findsOneWidget, reason: 'language from the cached profile is English');
    expect(core.secure.values.containsKey(SecureKeys.me), isFalse);
  });

  testWidgets('forgot password: username → code + new password → done', (tester) async {
    final core = await bootCore();
    core.http.reply('POST /api/v1/auth/forgot-password', 202, {'challengeId': 'ch-9', 'expiresAt': '2026-10-15T08:00:00Z'});
    core.http.reply('POST /api/v1/auth/reset-password', 204);
    await pumpEmrApp(tester);
    await tester.tap(find.text('نسيت كلمة المرور؟'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'demo.driver1');
    await tester.ensureVisible(find.text('إرسال الرمز'));
    await tester.tap(find.text('إرسال الرمز'));
    await tester.pumpAndSettle();
    expect(core.http.bodies.last, {'username': 'demo.driver1', 'clientApp': 'crew_app'});

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '654321');
    await tester.enterText(fields.at(1), 'NewPass2026-Long9');
    await tester.enterText(fields.at(2), 'NewPass2026-Long9');
    await tester.ensureVisible(find.text('حفظ'));
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    expect(core.http.bodies.last, {'challengeId': 'ch-9', 'code': '654321', 'newPassword': 'NewPass2026-Long9'});
    expect(find.text('تم تعيين كلمة المرور. سجّل الدخول الآن.'), findsOneWidget);
  });

  testWidgets('dev tools fill the SMS code from /dev/sms/latest', (tester) async {
    final core = await bootCore(devTools: true);
    core.http.reply('POST /api/v1/auth/login', 200, {'step': 'sms_code', 'challengeId': 'ch-1'});
    core.http.reply('GET /dev/sms/latest', 200, {'code': '777888'});
    await pumpEmrApp(tester);
    await login(tester);
    await tester.ensureVisible(find.byKey(const Key('sms_dev_fill')));
    await tester.tap(find.byKey(const Key('sms_dev_fill')));
    await tester.pumpAndSettle();

    final req = core.http.calls('GET /dev/sms/latest').single;
    expect(req.queryParameters['phone'], '+249999990108');
    expect(req.headers.containsKey('Authorization'), isFalse);
    expect(find.text('777888'), findsOneWidget);
    Get.find<SmsCodeController>().onClose();
  });
}
