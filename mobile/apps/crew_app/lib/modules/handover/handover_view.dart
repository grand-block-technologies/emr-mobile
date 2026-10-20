import 'dart:async';

import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/crew_routes.dart';
import '../../data/crew_repository.dart';
import '../home/crew_controller.dart';
import '../patient/patient_controller.dart';

/// Hand the patient over to the ER. The job cannot be completed without it (`HANDOVER_REQUIRED`).
/// Shown to the paramedic, and to the driver when no paramedic is on the shift.
class HandoverView extends StatefulWidget {
  const HandoverView({super.key});

  @override
  State<HandoverView> createState() => _HandoverViewState();
}

class _HandoverViewState extends State<HandoverView> {
  final _ctl = <String, TextEditingController>{};
  final _busy = <String>{};

  PatientController get c => Get.find<PatientController>();

  @override
  void initState() {
    super.initState();
    unawaited(c.load());
  }

  @override
  void dispose() {
    for (final t in _ctl.values) {
      t.dispose();
    }
    super.dispose();
  }

  TextEditingController _field(LocalPatient p) =>
      _ctl.putIfAbsent(p.ref, () => TextEditingController(text: c.handoverPrefill(p)));

  Future<void> _send(LocalPatient p) async {
    final text = _field(p).text;
    if (text.trim().isEmpty) {
      showToast('handover_summary_required'.tr);
      return;
    }
    setState(() => _busy.add(p.ref));
    try {
      if (await c.sendHandover(p, text)) {
        unawaited(Get.find<CrewController>().refreshHandover());
        showToast('handover_queued'.tr);
      }
    } finally {
      if (mounted) setState(() => _busy.remove(p.ref));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('handover_title'.tr), bottom: const SyncBar()),
      body: SafeArea(
        top: false,
        child: Obx(() {
          if (c.caseId == null) return const NoAccessView();
          final job = Get.find<CrewController>().job.value;
          final repo = Get.find<CrewRepository>();
          final mineIds = {for (final p in c.patients) repo.patientPathId(p)};
          // Handovers the server has for this job but for patients not registered on this phone.
          final others = job.handovers.where((h) => !mineIds.contains(h.patientId)).toList();
          if (c.patients.isEmpty && others.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(Space.screen),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EmptyView(
                    icon: LucideIcons.user,
                    title: 'handover_no_patient_title'.tr,
                    body: 'handover_no_patient_body'.tr,
                  ),
                  const SizedBox(height: Space.lg),
                  AppButton(
                    key: const Key('handover_add_patient'),
                    label: 'patient_add'.tr,
                    icon: LucideIcons.userPlus,
                    onPressed: () => Get.toNamed<void>(CrewRoutes.patientNew),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(Space.screen),
            children: [
              Text(
                'handover_body'.tr,
                style: t.bodyLarge!.copyWith(color: AppColors.inkMuted),
              ),
              const SizedBox(height: Space.lg),
              for (final p in c.patients) ...[
                _card(p, t, job.handoverFor(repo.patientPathId(p))),
                const SizedBox(height: Space.lg),
              ],
              if (others.isNotEmpty) ...[
                SectionHeader('handover_other_phone'.tr),
                for (final h in others) ...[
                  AppCard(
                    child: Row(
                      children: [
                        Expanded(child: Text(h.name(currentLang()), style: t.titleMedium)),
                        _ServerChip(h),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.md),
                ],
              ],
            ],
          );
        }),
      ),
    );
  }

  Widget _card(LocalPatient p, TextTheme t, JobHandover? server) {
    final done = p.handedOver || server != null;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(p.displayName, style: t.titleMedium)),
              if (server != null)
                _ServerChip(server)
              else if (p.handover == HandoverState.sent)
                StatusChip(
                  label: 'handover_sent'.tr,
                  tone: Tone.done,
                  icon: LucideIcons.circleCheck,
                )
              else if (p.handover == HandoverState.queued)
                StatusChip(
                  label: 'handover_waiting'.tr,
                  tone: Tone.warning,
                  icon: LucideIcons.clock,
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          LabeledField(
            fieldKey: Key('handover_summary_${p.ref}'),
            label: 'handover_summary'.tr,
            controller: _field(p),
            maxLines: 8,
            maxLength: HandoverBody.maxSummary,
            enabled: !done,
          ),
          if (!done) ...[
            const SizedBox(height: Space.md),
            AppButton(
              key: Key('handover_send_${p.ref}'),
              label: 'handover_send'.tr,
              icon: LucideIcons.send,
              busy: _busy.contains(p.ref),
              onPressed: () => unawaited(_send(p)),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Handover sent" until the ER confirms, then "Received by the ER".
class _ServerChip extends StatelessWidget {
  const _ServerChip(this.h);
  final JobHandover h;

  @override
  Widget build(BuildContext context) => h.received
      ? StatusChip(
          key: const Key('handover_received_chip'),
          label: 'handover_received_er'.tr,
          tone: Tone.done,
          icon: LucideIcons.circleCheck,
        )
      : StatusChip(
          label: 'handover_sent'.tr,
          tone: Tone.info,
          icon: LucideIcons.send,
        );
}
