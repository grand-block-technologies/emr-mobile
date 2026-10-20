import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_error.dart';
import '../config/app_config.dart';
import '../i18n/locale_service.dart';
import '../services/session_service.dart';
import '../ui/theme/app_colors.dart';
import '../ui/widgets/basics.dart';
import 'auth_controllers.dart';
import 'auth_flow.dart';

/// Sign-in layout: quiet and simple. A small app mark, a large title with one line under it, the
/// form, and a footer pinned to the bottom. Language switch as plain text in the top corner.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.children,
    super.key,
    this.body,
    this.showBack = false,
    this.footer,
  });

  final String title;
  final String? body;
  final List<Widget> children;
  final bool showBack;

  /// Quiet actions pinned to the bottom (create an account, emergency call).
  final List<Widget>? footer;


  @override
  Widget build(BuildContext context) {
    final config = Get.find<AuthFlow>().config;
    final t = Theme.of(context).textTheme;
    final bottom = [...?footer, if (config.showEmergencyCall) const _EmergencyLink()];
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        automaticallyImplyLeading: showBack,
        toolbarHeight: 56,
        actions: const [LanguageToggle(compact: true), SizedBox(width: Space.sm)],
      ),
      // Quiet links stay at the bottom of the screen; the form above scrolls on its own.
      bottomNavigationBar: bottom.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, Space.md),
                child: Column(mainAxisSize: MainAxisSize.min, children: [for (final w in bottom) Center(child: w)]),
              ),
            ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.xxl, Space.lg, Space.xxl, Space.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AppMark(icon: config.brandIcon ?? LucideIcons.ambulance),
                    const SizedBox(height: Space.xxl + Space.sm),
                    Text(title, style: t.headlineSmall!.copyWith(fontSize: 28, height: 1.2)),
                    if (body != null) ...[
                      const SizedBox(height: Space.sm),
                      Text(body!, style: t.bodyLarge!.copyWith(color: AppColors.inkMuted)),
                    ],
                    const SizedBox(height: Space.xxl + Space.sm),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 56 px rounded-square app mark.
class _AppMark extends StatelessWidget {
  const _AppMark({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: AppColors.onBrand, size: 28),
    ),
  );
}

/// Citizen safety exit: help never depends on having an account.
class _EmergencyLink extends StatelessWidget {
  const _EmergencyLink();

  @override
  Widget build(BuildContext context) {
    final number = Get.find<AppConfig>().emergencyNumber;
    return TextButton.icon(
      key: const Key('auth_call_emergency'),
      style: TextButton.styleFrom(foregroundColor: AppColors.danger),
      onPressed: () => unawaited(launchUrl(Uri(scheme: 'tel', path: number))),
      icon: const Icon(LucideIcons.phone, size: 18),
      label: Text('emergency_no_login'.trParams({'n': number})),
    );
  }
}

/// Switches between Arabic and English (shows the other language). [compact] = plain text button.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final locale = Get.find<LocaleService>();
    return Obx(() {
      final toEn = locale.lang == 'ar';
      final label = Text(toEn ? 'english'.tr : 'arabic'.tr);
      void toggle() => locale.set(toEn ? 'en' : 'ar');
      if (compact) {
        return TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.inkMuted),
          onPressed: toggle,
          child: label,
        );
      }
      return TextButton.icon(
        style:
            TextButton.styleFrom(
              backgroundColor: AppColors.brandSoft,
              foregroundColor: AppColors.brandActive,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: Space.lg),
            ).copyWith(
              overlayColor: const WidgetStatePropertyAll(
                AppColors.brandSoftPressed,
              ),
            ),
        onPressed: toggle,
        icon: const Icon(LucideIcons.languages, size: 18),
        label: label,
      );
    });
  }
}

/// Form-level error from a controller, with the reference only on unexpected errors.
class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner(this.form, {super.key});
  final FormStatus form;

  @override
  Widget build(BuildContext context) => Obx(() {
    final e = form.error.value;
    if (e == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: ErrorBanner(
        message: e.message(currentLang()),
        reference: e.isUnexpected ? e.reference : null,
      ),
    );
  });
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.label,
    required this.controller,
    super.key,
    this.errorText,
    this.helper,
    this.onSubmitted,
    this.autofillHints,
    this.fieldKey,
  });
  final String label;
  final TextEditingController controller;
  final String? errorText;
  final String? helper;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final Key? fieldKey;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) => LabeledField(
    fieldKey: widget.fieldKey,
    label: widget.label,
    controller: widget.controller,
    obscureText: _hidden,
    errorText: widget.errorText,
    helper: widget.helper,
    ltr: true,
    autofillHints: widget.autofillHints,
    textInputAction: widget.onSubmitted == null
        ? TextInputAction.next
        : TextInputAction.done,
    onSubmitted: widget.onSubmitted,
    suffix: IconButton(
      tooltip: (_hidden ? 'show_password' : 'hide_password').tr,
      icon: Icon(_hidden ? LucideIcons.eye : LucideIcons.eyeOff, size: 20),
      onPressed: () => setState(() => _hidden = !_hidden),
    ),
  );
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  LoginController get c => Get.find<LoginController>();

  @override
  void initState() {
    super.initState();
    final pre = c.prefillUsername;
    if (pre != null) _user.text = pre;
  }

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _submit() => unawaited(c.submit(_user.text, _pass.text));

  @override
  Widget build(BuildContext context) {
    final flow = Get.find<AuthFlow>();
    return AuthScaffold(
      title: 'login_title'.tr,
      body: 'login_body'.tr,
      footer: [
        if (flow.config.loginFooter != null) flow.config.loginFooter!(context),
      ],
      children: [
        Obx(() {
          final n = c.notice.value;
          if (n == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: Space.lg),
            child: c.noticeIsError.value
                ? ErrorBanner(message: n)
                : Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: StatusChip(
                      label: n,
                      tone: Tone.info,
                      icon: LucideIcons.circleCheck,
                    ),
                  ),
          );
        }),
        FormErrorBanner(c),
        AutofillGroup(
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LabeledField(
                  fieldKey: const Key('login_username'),
                  label: flow.config.usernameLabelKey.tr,
                  controller: _user,
                  errorText: c.fieldErrors['username'],
                  ltr: true,
                  keyboardType: TextInputType.text,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: Space.lg),
                PasswordField(
                  fieldKey: const Key('login_password'),
                  label: 'password'.tr,
                  controller: _pass,
                  errorText: c.fieldErrors['password'],
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _submit(),
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () =>
                        Get.toNamed<void>(AuthRoutes.forgotPassword),
                    child: Text('forgot_password'.tr),
                  ),
                ),
                const SizedBox(height: Space.md),
                AppButton(
                  key: const Key('login_submit'),
                  label: 'sign_in'.tr,
                  busy: c.busy.value,
                  height: 52,
                  icon: Directionality.of(context) == TextDirection.rtl
                      ? LucideIcons.arrowLeft
                      : LucideIcons.arrowRight,
                  iconAfter: true,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SmsCodeView extends StatefulWidget {
  const SmsCodeView({super.key});

  @override
  State<SmsCodeView> createState() => _SmsCodeViewState();
}

class _SmsCodeViewState extends State<SmsCodeView> {
  final _code = TextEditingController();
  final _devPhone = TextEditingController();
  SmsCodeController get c => Get.find<SmsCodeController>();

  @override
  void initState() {
    super.initState();
    final phones = Get.find<AuthFlow>().config.devPhones;
    // Never the username: only a known phone, or the username when that is itself a phone number.
    final u = c.username.trim();
    _devPhone.text = phones[u] ?? (RegExp(r'^\+?\d{8,15}$').hasMatch(u) ? u : '');
  }

  @override
  void dispose() {
    _code.dispose();
    _devPhone.dispose();
    super.dispose();
  }

  void _submit() => unawaited(c.submit(_code.text));

  @override
  Widget build(BuildContext context) {
    final devTools = Get.find<AppConfig>().devTools && !kReleaseMode;
    return AuthScaffold(
      title: 'sms_title'.tr,
      body: 'sms_body'.tr,
      showBack: true,
      children: [
        FormErrorBanner(c),
        Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (c.info.value != null) ...[
                StatusChip(
                  label: c.info.value!,
                  tone: Tone.info,
                  icon: LucideIcons.messageSquare,
                ),
                const SizedBox(height: Space.lg),
              ],
              LabeledField(
                fieldKey: const Key('sms_code'),
                label: 'sms_code'.tr,
                controller: _code,
                errorText: c.fieldErrors['code'],
                keyboardType: TextInputType.number,
                maxLength: 6,
                ltr: true,
                autofillHints: const [AutofillHints.oneTimeCode],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: Space.xxl),
              AppButton(
                key: const Key('sms_submit'),
                label: 'verify'.tr,
                busy: c.busy.value,
                onPressed: _submit,
              ),
              const SizedBox(height: Space.sm),
              AppButton(
                key: const Key('sms_resend'),
                label: c.secondsLeft.value > 0
                    ? 'resend_in'.trParams({'s': '${c.secondsLeft.value}'})
                    : 'resend_code'.tr,
                variant: ButtonVariant.ghost,
                onPressed: c.canResend ? () => unawaited(c.resend()) : null,
              ),
            ],
          ),
        ),
        if (devTools) ...[
          const SizedBox(height: Space.xxl),
          const Divider(),
          const SizedBox(height: Space.lg),
          LabeledField(
            label: 'dev_phone'.tr,
            controller: _devPhone,
            ltr: true,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: Space.sm),
          AppButton(
            key: const Key('sms_dev_fill'),
            label: 'dev_fill_code'.tr,
            variant: ButtonVariant.secondary,
            icon: LucideIcons.bug,
            onPressed: () async {
              final code = await c.devFetchCode(_devPhone.text);
              if (code != null) _code.text = code;
            },
          ),
        ],
      ],
    );
  }
}

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _repeat = TextEditingController();
  ChangePasswordController get c => Get.find<ChangePasswordController>();

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _repeat.dispose();
    super.dispose();
  }

  void _submit() => unawaited(c.submit(_old.text, _new.text, _repeat.text));

  @override
  Widget build(BuildContext context) => AuthScaffold(
    title: 'change_password_title'.tr,
    body: 'change_password_body'.tr,
    children: [
      FormErrorBanner(c),
      Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PasswordField(
              label: 'old_password'.tr,
              controller: _old,
              errorText: c.fieldErrors['oldPassword'],
              autofillHints: const [AutofillHints.password],
            ),
            const SizedBox(height: Space.lg),
            PasswordField(
              label: 'new_password'.tr,
              controller: _new,
              errorText: c.fieldErrors['newPassword'],
              helper: 'password_rule'.tr,
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: Space.lg),
            PasswordField(
              label: 'repeat_password'.tr,
              controller: _repeat,
              errorText: c.fieldErrors['repeat'],
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: Space.xxl),
            AppButton(label: 'save'.tr, busy: c.busy.value, onPressed: _submit),
            const SizedBox(height: Space.sm),
            const SignOutButton(),
          ],
        ),
      ),
    ],
  );
}

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _user = TextEditingController();
  final _code = TextEditingController();
  final _new = TextEditingController();
  final _repeat = TextEditingController();
  ForgotPasswordController get c => Get.find<ForgotPasswordController>();

  @override
  void dispose() {
    for (final t in [_user, _code, _new, _repeat]) {
      t.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    if (c.done.value) {
      return AuthScaffold(
        title: 'reset_title'.tr,
        body: 'reset_done'.tr,
        children: [
          AppButton(
            label: 'sign_in'.tr,
            onPressed: () => Get.offAllNamed<void>(AuthRoutes.login),
          ),
        ],
      );
    }
    if (!c.codeSent) {
      return AuthScaffold(
        title: 'forgot_title'.tr,
        body: 'forgot_body'.tr,
        showBack: true,
        children: [
          FormErrorBanner(c),
          if (c.serverMessage != null) ...[
            ErrorBanner(message: c.serverMessage!),
            const SizedBox(height: Space.lg),
          ],
          LabeledField(
            label: Get.find<AuthFlow>().config.usernameLabelKey.tr,
            controller: _user,
            errorText: c.fieldErrors['username'],
            ltr: true,
          ),
          const SizedBox(height: Space.xxl),
          AppButton(
            label: 'send_code'.tr,
            busy: c.busy.value,
            onPressed: () => unawaited(c.requestCode(_user.text)),
          ),
        ],
      );
    }
    return AuthScaffold(
      title: 'reset_title'.tr,
      body: 'sms_body'.tr,
      showBack: true,
      children: [
        FormErrorBanner(c),
        LabeledField(
          label: 'sms_code'.tr,
          controller: _code,
          errorText: c.fieldErrors['code'],
          keyboardType: TextInputType.number,
          maxLength: 6,
          ltr: true,
          autofillHints: const [AutofillHints.oneTimeCode],
        ),
        const SizedBox(height: Space.lg),
        PasswordField(
          label: 'new_password'.tr,
          controller: _new,
          errorText: c.fieldErrors['newPassword'],
          helper: 'password_rule'.tr,
        ),
        const SizedBox(height: Space.lg),
        PasswordField(
          label: 'repeat_password'.tr,
          controller: _repeat,
          errorText: c.fieldErrors['repeat'],
        ),
        const SizedBox(height: Space.xxl),
        AppButton(
          label: 'save'.tr,
          busy: c.busy.value,
          onPressed: () =>
              unawaited(c.reset(_code.text, _new.text, _repeat.text)),
        ),
      ],
    );
  });
}

class ForceUpdateView extends StatelessWidget {
  const ForceUpdateView({super.key});

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: AuthScaffold(
      title: 'update_title'.tr,
      body: 'update_body'.tr,
      children: const [
        Icon(LucideIcons.download, size: 48, color: AppColors.brand),
      ],
    ),
  );
}

/// Shown while the saved session is restored; decides the first real screen.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(Get.find<AuthFlow>().start()),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Semantics(
        label: 'loading'.tr,
        child: const SizedBox.square(
          dimension: 32,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    ),
  );
}

/// Shows any [ApiError] thrown by [action] as a toast. Handy for one-shot buttons.
Future<void> guard(Future<void> Function() action) async {
  try {
    await action();
  } on Object catch (e) {
    showToast(ApiError.of(e).message(currentLang()));
  }
}

/// "Sign out" with feedback: spinner and no repeat taps while the server logout and the local
/// wipe run. [onPressed] defaults to signing out directly; the crew app passes its own
/// confirm-first handler.
class SignOutButton extends StatelessWidget {
  const SignOutButton({
    super.key,
    this.variant = ButtonVariant.ghost,
    this.icon,
    this.onPressed,
  });
  final ButtonVariant variant;
  final IconData? icon;
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionService>();
    return Obx(
      () => AppButton(
        key: const Key('sign_out'),
        label: 'sign_out'.tr,
        variant: variant,
        icon: icon,
        busy: session.signingOut.value,
        onPressed: () => unawaited((onPressed ?? session.signOut)()),
      ),
    );
  }
}
