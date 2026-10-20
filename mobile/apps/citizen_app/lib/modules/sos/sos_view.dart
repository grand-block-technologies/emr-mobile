import 'dart:async';

import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../services/sos_locator.dart';
import 'sos_controller.dart';

/// The main screen: one large red button.
class SosView extends StatefulWidget {
  const SosView({super.key});

  @override
  State<SosView> createState() => _SosViewState();
}

class _SosViewState extends State<SosView> {
  final _note = TextEditingController();
  SosController get c => Get.find<SosController>();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final number = Get.find<AppConfig>().emergencyNumber;
    return Obx(() {
      final busy = c.busy;
      final label = switch (c.phase.value) {
        SosPhase.locating => 'sos_locating'.tr,
        SosPhase.sending => 'sos_sending'.tr,
        _ => 'sos_button'.tr,
      };
      return ListView(
        padding: const EdgeInsets.fromLTRB(Space.screen, Space.sm, Space.screen, Space.xxl),
        children: [
          Text('sos_title'.tr, style: t.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: Space.sm),
          Text('sos_body'.tr, style: t.bodyLarge!.copyWith(color: AppColors.inkMuted), textAlign: TextAlign.center),
          const SizedBox(height: Space.xl),
          Center(
            child: Semantics(
              button: true,
              label: label,
              excludeSemantics: true,
              onTap: busy ? null : () => unawaited(c.send(note: _note.text)),
              child: _SosButton(label: label, busy: busy, onPressed: () => unawaited(c.send(note: _note.text))),
            ),
          ),
          const SizedBox(height: Space.xl),
          if (c.error.value != null) ...[
            ErrorBanner(message: c.error.value!.message(currentLang()), reference: c.error.value!.isUnexpected ? c.error.value!.reference : null),
            const SizedBox(height: Space.lg),
          ],
          if (c.locationProblem.value != null) ...[
            ErrorBanner(message: 'sos_location_${c.locationProblem.value!.name}'.tr),
            const SizedBox(height: Space.lg),
          ],
          if (c.offerCall999.value) ...[
            AppButton(
              key: const Key('call_999'),
              label: 'call_999'.trParams({'n': number}),
              variant: ButtonVariant.danger,
              icon: LucideIcons.phone,
              height: 52,
              onPressed: () => unawaited(callNumber(number)),
            ),
            const SizedBox(height: Space.sm),
            Text('sos_sms_hint'.tr, style: t.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: Space.lg),
          ],
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: Space.lg),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                leading: const IconTile(LucideIcons.messageSquareText, size: 36, iconSize: 18),
                title: Text('${'sos_note'.tr} (${'optional'.tr})', style: t.labelLarge),
                childrenPadding: const EdgeInsets.only(bottom: Space.lg),
                children: [
                  LabeledField(
                    fieldKey: const Key('sos_note'),
                    label: 'sos_note'.tr,
                    controller: _note,
                    maxLines: 3,
                    maxLength: 2000,
                    hint: 'sos_note_hint'.tr,
                    enabled: !busy,
                  ),
                ],
              ),
            ),
          ),
          if (!c.offerCall999.value) ...[
            const SizedBox(height: Space.lg),
            RowGroup(
              children: [
                ListRow(
                  icon: LucideIcons.phone,
                  tone: Tone.danger,
                  title: 'call_999'.trParams({'n': number}),
                  subtitle: 'call_999_hint'.tr,
                  onTap: () => unawaited(callNumber(number)),
                ),
              ],
            ),
          ],
        ],
      );
    });
  }
}

/// Off in widget tests (an endless animation never lets `pumpAndSettle` settle).
abstract final class SosPulse {
  static bool enabled = true;
}

/// 200 px red button inside two soft rings. The outer ring breathes gently (the one animated
/// element on this screen) and stands still when the system asks for reduced motion or while busy.
class _SosButton extends StatefulWidget {
  const _SosButton({required this.label, required this.busy, required this.onPressed});
  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  State<_SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<_SosButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _SosButton old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final still = !SosPulse.enabled || MediaQuery.disableAnimationsOf(context) || widget.busy;
    if (still) {
      _pulse
        ..stop()
        ..value = 0;
    } else if (!_pulse.isAnimating) {
      unawaited(_pulse.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) => Container(
                width: 260 + 20 * _pulse.value,
                height: 260 + 20 * _pulse.value,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.danger.withValues(alpha: 0.06)),
              ),
            ),
            Container(
              width: 236,
              height: 236,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.danger.withValues(alpha: 0.10)),
            ),
            SizedBox.square(
              dimension: 200,
              child: FilledButton(
                key: const Key('sos_button'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  disabledBackgroundColor: AppColors.danger.withValues(alpha: 0.85),
                  shape: const CircleBorder(),
                  elevation: 6,
                  shadowColor: AppColors.danger.withValues(alpha: 0.5),
                ).copyWith(overlayColor: const WidgetStatePropertyAll(Color(0xFF7D1812))),
                onPressed: widget.busy ? null : widget.onPressed,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.busy)
                      const SizedBox.square(dimension: 40, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    else
                      const Icon(LucideIcons.siren, size: 56, color: Colors.white),
                    const SizedBox(height: Space.md),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, height: 1.25),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
