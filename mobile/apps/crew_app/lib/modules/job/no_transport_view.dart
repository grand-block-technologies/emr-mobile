import 'dart:async';

import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/crew_routes.dart';
import '../home/crew_controller.dart';

IconData _reasonIcon(NoTransportReason r) => switch (r) {
  NoTransportReason.treatedAtScene => LucideIcons.heartHandshake,
  NoTransportReason.refused => LucideIcons.ban,
  NoTransportReason.diedAtScene => LucideIcons.heartCrack,
  NoTransportReason.patientNotFound => LucideIcons.userX,
  NoTransportReason.cancelledByCaller => LucideIcons.phoneOff,
  NoTransportReason.falseAlarm => LucideIcons.triangleAlert,
};

/// End a job at the scene: the backend needs the reason the patient was not taken.
class NoTransportView extends StatefulWidget {
  const NoTransportView({super.key});

  @override
  State<NoTransportView> createState() => _NoTransportViewState();
}

class _NoTransportViewState extends State<NoTransportView> {
  final _note = TextEditingController();
  NoTransportReason? _reason;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _end() async {
    final r = _reason;
    if (r == null) {
      setState(() => _error = 'no_transport_pick'.tr);
      return;
    }
    if (r.noteRequired && _note.text.trim().isEmpty) {
      setState(() => _error = 'no_transport_note_required'.tr);
      return;
    }
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text('no_transport_confirm_title'.tr),
        content: Text(
          'no_transport_confirm_body'.trParams({'reason': 'reason_${r.wire}'.tr}),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            key: const Key('complete_confirm'),
            onPressed: () => Get.back(result: true),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
    if (!(ok ?? false)) return;
    await Get.find<CrewController>().advance(
      JobStatus.completed,
      noTransportReason: r,
      note: _note.text,
    );
    Get.until((route) => route.settings.name == CrewRoutes.home || route.isFirst);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('end_without_transport'.tr)),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.all(Space.screen),
        children: [
          Text(
            'no_transport_body'.tr,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: Space.lg),
          for (final r in NoTransportReason.values) ...[
            _ReasonButton(
              reason: r,
              selected: _reason == r,
              onTap: () => setState(() {
                _reason = r;
                _error = null;
              }),
            ),
            const SizedBox(height: Space.sm),
          ],
          const SizedBox(height: Space.md),
          LabeledField(
            fieldKey: const Key('no_transport_note'),
            label: _reason?.noteRequired ?? false
                ? 'note'.tr
                : '${'note'.tr} (${'optional'.tr})',
            controller: _note,
            maxLines: 3,
            maxLength: 2000,
          ),
          if (_error != null) ...[
            const SizedBox(height: Space.sm),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: Space.xl),
          AppButton(
            key: const Key('no_transport_end'),
            label: 'end_without_transport'.tr,
            icon: LucideIcons.circleCheck,
            height: 56,
            onPressed: () => unawaited(_end()),
          ),
        ],
      ),
    ),
  );
}

class _ReasonButton extends StatelessWidget {
  const _ReasonButton({required this.reason, required this.selected, required this.onTap});
  final NoTransportReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.brandSoft : AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Space.cardRadius),
      side: BorderSide(color: selected ? AppColors.brand : AppColors.line, width: selected ? 2 : 1),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: Key('reason_${reason.wire}'),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
          child: Row(
            children: [
              Icon(_reasonIcon(reason), color: selected ? AppColors.brand : AppColors.inkMuted),
              const SizedBox(width: Space.md),
              Expanded(
                child: Text(
                  'reason_${reason.wire}'.tr,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
              ),
              if (selected) const Icon(LucideIcons.circleCheck, color: AppColors.brand),
            ],
          ),
        ),
      ),
    ),
  );
}
