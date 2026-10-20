import 'dart:async';

import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../app/crew_routes.dart';
import 'crew_controller.dart';

/// A server-cancelled job. Patient writes still queued for it will be refused (403).
String cancelledText(CrewController c) => c.cancelledUnsent.value > 0
    ? '${'job_cancelled'.tr}\n${'job_cancelled_unsent'.trParams({'n': '${c.cancelledUnsent.value}'})}'
    : 'job_cancelled'.tr;

class Notice extends StatelessWidget {
  const Notice({super.key, required this.text, required this.onClose});
  final String text;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.only(start: Space.md),
    decoration: BoxDecoration(
      color: AppColors.warningSurface,
      borderRadius: BorderRadius.circular(Space.cardRadius),
    ),
    child: Row(
      children: [
        const Icon(LucideIcons.circleAlert, size: 20, color: AppColors.warning),
        const SizedBox(width: Space.sm),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.warning,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        IconButton(
          tooltip: 'close'.tr,
          icon: const Icon(LucideIcons.x, size: 20),
          onPressed: onClose,
        ),
      ],
    ),
  );
}

/// "Updated 2 min ago" or the last error.
class Freshness extends StatelessWidget {
  const Freshness({super.key, required this.at, required this.error});
  final DateTime? at;
  final ApiError? error;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme.bodySmall;
    if (error != null) {
      return Text(
        error!.message(currentLang()),
        style: t!.copyWith(color: AppColors.danger),
        textAlign: TextAlign.center,
      );
    }
    if (at == null) return const SizedBox.shrink();
    final a = SudanTime.age(at!, DateTime.now());
    return Text(
      '${'updated_ago'.tr} ${'age_${a.unit}'.trParams({'n': '${a.value}'})}',
      style: t,
      textAlign: TextAlign.center,
    );
  }
}

/// Ending at the scene needs a reason, so it opens its own screen. Everything else is one tap.
Future<void> confirmJobStep(CrewController c, JobStatus next) async {
  if (next == JobStatus.completed &&
      c.job.value.jobStatus == JobStatus.onScene) {
    await Get.toNamed<void>(CrewRoutes.noTransport);
    return;
  }
  await c.advance(next);
}

/// "Job completed" waits until the handover is sent by whoever must send it.
bool stepBlocked(CrewController c, JobStatus status, JobStatus next) =>
    status == JobStatus.atHospital &&
    next == JobStatus.completed &&
    c.handoverMissing.value;

/// Two small time badges: how long ago the job was sent, and how long in the current status.
/// Only shows fields the server actually returned. Updates every 60 s.
class JobTimeBadges extends StatefulWidget {
  const JobTimeBadges({super.key, required this.job});
  final Job job;

  @override
  State<JobTimeBadges> createState() => _JobTimeBadgesState();
}

class _JobTimeBadgesState extends State<JobTimeBadges> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // `timeago` registers English by default; Arabic must be opted in.
    timeago.setLocaleMessages('ar', timeago.ArMessages());
    _tick = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String _age(DateTime utc) {
    final offset = Get.isRegistered<CrewController>()
        ? Get.find<CrewController>().serverClockOffset
        : Duration.zero;
    final now = DateTime.now().toUtc().add(offset);
    return timeago.format(utc, clock: now, locale: currentLang());
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.job;
    final hasSent = j.sentAt != null;
    final hasStatusTime = j.statusTime != null && j.jobStatus != JobStatus.sent;
    if (!hasSent && !hasStatusTime) return const SizedBox.shrink();

    final t = Theme.of(
      context,
    ).textTheme.labelSmall!.copyWith(color: AppColors.inkMuted);
    return Padding(
      padding: const EdgeInsets.only(top: Space.xs),
      child: Wrap(
        spacing: Space.md,
        runSpacing: 2,
        children: [
          if (hasSent)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.clock,
                  size: 12,
                  color: AppColors.inkMuted,
                ),
                const SizedBox(width: 4),
                Text('sent_ago'.trParams({'t': _age(j.sentAt!)}), style: t),
              ],
            ),
          if (hasStatusTime)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.timer,
                  size: 12,
                  color: AppColors.inkMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  'status_since'.trParams({'t': _age(j.statusTime!)}),
                  style: t,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
