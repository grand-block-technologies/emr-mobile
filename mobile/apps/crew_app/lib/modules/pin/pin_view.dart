import 'dart:async';

import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'pin_controller.dart';

class PinView extends StatefulWidget {
  const PinView({super.key});

  @override
  State<PinView> createState() => _PinViewState();
}

class _PinViewState extends State<PinView> {
  final _pin = TextEditingController();
  final _repeat = TextEditingController();
  PinController get c => Get.find<PinController>();

  @override
  void dispose() {
    _pin.dispose();
    _repeat.dispose();
    super.dispose();
  }

  void _submit() => unawaited(c.submit(_pin.text, repeat: _repeat.text));

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        child: Obx(() {
          final setup = c.mode == PinMode.setup;
          final setting = setup && !c.haveExisting.value;
          return AuthScaffold(
            title: (setup ? 'pin_setup_title' : 'pin_unlock_title').tr,
            body: (setup ? 'pin_setup_body' : 'pin_unlock_body').tr,
            children: [
              FormErrorBanner(c),
              if (c.message.value != null) ...[ErrorBanner(message: c.message.value!), const SizedBox(height: Space.lg)],
              if (setup) ...[
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: false, label: Text('pin_new'.tr)),
                    ButtonSegment(value: true, label: Text('pin_have'.tr)),
                  ],
                  selected: {c.haveExisting.value},
                  onSelectionChanged: (v) => c.haveExisting.value = v.first,
                ),
                const SizedBox(height: Space.xxl),
              ],
              LabeledField(
                fieldKey: const Key('pin'),
                label: 'pin'.tr,
                controller: _pin,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                ltr: true,
                errorText: c.fieldErrors['pin'],
                helper: setting ? 'pin_rule'.tr : null,
                textInputAction: setting ? TextInputAction.next : TextInputAction.done,
                onSubmitted: setting ? null : (_) => _submit(),
              ),
              if (setting) ...[
                const SizedBox(height: Space.lg),
                LabeledField(
                  fieldKey: const Key('pin_repeat'),
                  label: 'pin_repeat'.tr,
                  controller: _repeat,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  ltr: true,
                  errorText: c.fieldErrors['repeat'],
                  onSubmitted: (_) => _submit(),
                ),
              ],
              const SizedBox(height: Space.xxl),
              AppButton(
                key: const Key('pin_submit'),
                label: (setting ? 'save' : 'pin_unlock').tr,
                icon: setting ? null : LucideIcons.lockOpen,
                busy: c.busy.value,
                onPressed: _submit,
              ),
              const SizedBox(height: Space.sm),
              const SignOutButton(),
            ],
          );
        }),
      );
}
