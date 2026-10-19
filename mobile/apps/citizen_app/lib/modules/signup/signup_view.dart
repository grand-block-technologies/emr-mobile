import 'dart:async';

import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'signup_controller.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _nid = TextEditingController();
  final _nameAr = TextEditingController();
  final _nameEn = TextEditingController();
  final _pass = TextEditingController();
  final _repeat = TextEditingController();
  SignUpController get c => Get.find<SignUpController>();

  @override
  void dispose() {
    for (final t in [_phone, _code, _nid, _nameAr, _nameEn, _pass, _repeat]) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> _finish() async {
    final ok = await c.finish(
      code: _code.text,
      nationalId: _nid.text,
      fullNameAr: _nameAr.text,
      fullNameEn: _nameEn.text,
      password: _pass.text,
      repeat: _repeat.text,
    );
    if (ok) {
      await Get.offAllNamed<void>(
        AuthRoutes.login,
        arguments: LoginArgs(message: 'signup_done'.tr, username: c.phone, isError: false),
      );
    }
  }

  Widget _loginInstead() => Obx(
        () => c.accountExists.value
            ? Padding(
                padding: const EdgeInsets.only(bottom: Space.lg),
                child: AppButton(
                  key: const Key('signup_login_instead'),
                  label: 'sign_in'.tr,
                  variant: ButtonVariant.secondary,
                  onPressed: () => Get.offAllNamed<void>(AuthRoutes.login, arguments: LoginArgs(username: c.phone)),
                ),
              )
            : const SizedBox.shrink(),
      );

  @override
  Widget build(BuildContext context) => Obx(() {
        if (!c.codeSent) {
          return AuthScaffold(
            title: 'signup_title'.tr,
            body: 'signup_phone_body'.tr,
            showBack: true,
            children: [
              FormErrorBanner(c),
              _loginInstead(),
              LabeledField(
                fieldKey: const Key('signup_phone'),
                label: 'phone'.tr,
                controller: _phone,
                keyboardType: TextInputType.phone,
                ltr: true,
                hint: '0912345678',
                errorText: c.fieldErrors['phone'],
                autofillHints: const [AutofillHints.telephoneNumber],
              ),
              const SizedBox(height: Space.xxl),
              AppButton(key: const Key('signup_send'), label: 'send_code'.tr, busy: c.busy.value, onPressed: () => unawaited(c.start(_phone.text))),
            ],
          );
        }
        return AuthScaffold(
          title: 'signup_title'.tr,
          body: 'signup_details_body'.trParams({'phone': Phone.dialled(c.phone)}),
          children: [
            FormErrorBanner(c),
            _loginInstead(),
            LabeledField(
              fieldKey: const Key('signup_code'),
              label: 'sms_code'.tr,
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              ltr: true,
              errorText: c.fieldErrors['code'],
              autofillHints: const [AutofillHints.oneTimeCode],
            ),
            const SizedBox(height: Space.lg),
            LabeledField(
              fieldKey: const Key('signup_nid'),
              label: 'national_id'.tr,
              controller: _nid,
              keyboardType: TextInputType.number,
              maxLength: 15,
              ltr: true,
              errorText: c.fieldErrors['nationalId'],
            ),
            const SizedBox(height: Space.lg),
            LabeledField(fieldKey: const Key('signup_name_ar'), label: 'full_name_ar'.tr, controller: _nameAr, errorText: c.fieldErrors['fullNameAr']),
            const SizedBox(height: Space.lg),
            LabeledField(label: '${'full_name_en'.tr} (${'optional'.tr})', controller: _nameEn, ltr: true),
            const SizedBox(height: Space.lg),
            PasswordField(
              fieldKey: const Key('signup_pass'),
              label: 'password'.tr,
              controller: _pass,
              errorText: c.fieldErrors['password'],
              helper: 'password_rule'.tr,
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: Space.lg),
            PasswordField(fieldKey: const Key('signup_repeat'), label: 'repeat_password'.tr, controller: _repeat, errorText: c.fieldErrors['repeat']),
            const SizedBox(height: Space.xxl),
            AppButton(key: const Key('signup_finish'), label: 'signup_create'.tr, busy: c.busy.value, onPressed: () => unawaited(_finish())),
            const SizedBox(height: Space.sm),
            AppButton(label: 'signup_change_phone'.tr, variant: ButtonVariant.ghost, onPressed: c.changePhone),
          ],
        );
      });
}
