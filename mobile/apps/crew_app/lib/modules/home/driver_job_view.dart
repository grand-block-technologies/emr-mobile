import 'dart:async';

import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/crew_routes.dart';
import '../job/job_widgets.dart';
import 'crew_controller.dart';
import 'job_shared.dart';

/// Uber-style driver interface: full screen navigation map with floating information cards and controls.
class DriverFullScreenJobView extends StatelessWidget {
  const DriverFullScreenJobView({super.key, required this.controller, required this.job});

  final CrewController controller;
  final Job job;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final j = controller.job.value;
      final status = j.jobStatus;
      final p = Priority.fromCode(j.priority);

      return Scaffold(
        body: Stack(
          children: [
            // 1. Full-screen map (base layer)
            Positioned.fill(
              child: JobMap(
                job: j,
                isFullScreen: true,
                showDirectionsButton: false,
              ),
            ),

            // 2. Floating top header and job info card
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.md,
                    vertical: Space.xs,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FloatingTopBar(onShift: controller.onShift),
                      if (controller.cancelledNotice.value) ...[
                        const SizedBox(height: Space.xs),
                        Notice(
                          text: cancelledText(controller),
                          onClose: controller.dismissCancelled,
                        ),
                      ],
                      const SizedBox(height: Space.xs),
                      _FloatingJobCard(job: j, status: status, priority: p),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Floating bottom action card & navigation button
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.md,
                    0,
                    Space.md,
                    Space.md,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (j.hasLocation)
                        Align(
                          alignment:
                              Directionality.of(context) == TextDirection.rtl
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: Space.sm),
                            child: FilledButton.icon(
                              key: const Key('directions'),
                              style:
                                  FilledButton.styleFrom(
                                    backgroundColor: AppColors.surface,
                                    foregroundColor: AppColors.brand,
                                    elevation: 4,
                                    shadowColor: AppColors.ink.withValues(
                                      alpha: 0.3,
                                    ),
                                    shape: const StadiumBorder(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Space.lg,
                                      vertical: Space.md,
                                    ),
                                  ).copyWith(
                                    overlayColor: const WidgetStatePropertyAll(
                                      AppColors.brandSoft,
                                    ),
                                  ),
                              onPressed: () =>
                                  unawaited(openDirections(j.lat!, j.lon!)),
                              icon: const Icon(
                                LucideIcons.navigation,
                                size: 20,
                              ),
                              label: Text(
                                'directions'.tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      _FloatingBottomCard(
                        controller: controller,
                        status: status,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _FloatingTopBar extends StatelessWidget {
  const _FloatingTopBar({required this.onShift});
  final bool onShift;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Status + sync pill ──────────────────────────────────────
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Space.cardRadius),
              boxShadow: cardShadow,
              border: Border.all(color: AppColors.line),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: Space.md,
              vertical: Space.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: onShift
                        ? const Color(0xFF257538)
                        : AppColors.inkMuted,
                  ),
                ),
                const SizedBox(width: Space.sm),
                Flexible(
                  child: Text(
                    (onShift ? 'on_shift' : 'off_shift').tr,
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: Space.sm),
                const FittedBox(fit: BoxFit.scaleDown, child: LiveSyncChip()),
              ],
            ),
          ),
        ),

        const SizedBox(width: Space.sm),

        // ── Settings button ─────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            boxShadow: cardShadow,
            border: Border.all(color: AppColors.line),
          ),
          child: IconButton(
            key: const Key('open_settings'),
            tooltip: 'settings'.tr,
            icon: const Icon(LucideIcons.settings, size: 22),
            onPressed: () => Get.toNamed<void>(CrewRoutes.settings),
          ),
        ),
      ],
    );
  }
}

class _FloatingJobCard extends StatefulWidget {
  const _FloatingJobCard({
    required this.job,
    required this.status,
    required this.priority,
  });

  final Job job;
  final JobStatus? status;
  final Priority? priority;

  @override
  State<_FloatingJobCard> createState() => _FloatingJobCardState();
}

class _FloatingJobCardState extends State<_FloatingJobCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final j = widget.job;
    final p = widget.priority;
    final status = widget.status;
    final lang = currentLang();
    final t = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Space.cardRadius),
        boxShadow: cardShadow,
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (p?.fill != null) Container(height: 4, color: p!.fill),
          Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: Space.sm,
                        runSpacing: Space.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (p != null) PriorityPill(p),
                          JobStatusChip(status),
                          if (j.caseNumber != null)
                            LtrText(
                              j.caseNumber!,
                              style: t.labelMedium!.copyWith(
                                color: AppColors.inkMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: (_expanded ? 'close' : 'details').tr,
                      onPressed: () => setState(() => _expanded = !_expanded),
                      icon: Icon(
                        _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                        size: 22,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
                if (j.complaint != null) ...[
                  const SizedBox(height: Space.sm),
                  Text(
                    j.complaint!,
                    style: t.titleMedium!.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: _expanded ? 3 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Time row below complaint
                JobTimeBadges(job: j),
                if (_expanded) ...[
                  if (j.hospital(lang) != null ||
                      j.landmark(lang) != null ||
                      j.directions != null) ...[
                    const SizedBox(height: Space.sm),
                    const Divider(height: 1),
                    const SizedBox(height: Space.sm),
                  ],
                  if (j.hospital(lang) != null) ...[
                    InfoRow(
                      icon: LucideIcons.hospital,
                      label: 'destination'.tr,
                      text: j.hospital(lang)!,
                    ),
                    const SizedBox(height: Space.xs),
                  ],
                  if (j.landmark(lang) != null) ...[
                    InfoRow(
                      icon: LucideIcons.landmark,
                      label: 'landmark'.tr,
                      text: j.landmark(lang)!,
                    ),
                    const SizedBox(height: Space.xs),
                  ],
                  if (j.directions != null)
                    InfoRow(
                      icon: LucideIcons.signpost,
                      label: 'directions_note'.tr,
                      text: j.directions!,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingBottomCard extends StatelessWidget {
  const _FloatingBottomCard({required this.controller, required this.status});

  final CrewController controller;
  final JobStatus? status;

  @override
  Widget build(BuildContext context) => Obx(() => _build(context));

  Widget _build(BuildContext context) {
    if (status == null || status!.isClosed) return const SizedBox.shrink();

    Widget actionWidget;
    if (status == JobStatus.sent) {
      actionWidget = SwipeToConfirm(
        key: const Key('swipe_accept_inline'),
        label: 'swipe_to_accept'.tr,
        onConfirmed: () => unawaited(controller.confirm()),
      );
    } else {
      final steps = status!.next
          .where((s) => s != JobStatus.confirmed)
          .toList();
      actionWidget = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (status == JobStatus.leavingScene ||
              status == JobStatus.atHospital) ...[
            HandoverCard(
              canHandOver: controller.canHandOver,
              missing: controller.handoverMissing.value,
              handovers: controller.job.value.handovers,
              onOpen: () => Get.toNamed<void>(CrewRoutes.handover),
            ),
            const SizedBox(height: Space.sm),
          ],
          for (final next in steps) ...[
            if (next != steps.first) const SizedBox(height: Space.xs),
            AppButton(
              key: Key('step_${next.wire}'),
              label: stepLabel(status!, next),
              height: next == status!.primaryNext ? 56 : Space.minTarget,
              variant: next == status!.primaryNext
                  ? ButtonVariant.primary
                  : ButtonVariant.ghost,
              icon: next == status!.primaryNext
                  ? (Directionality.of(context) == TextDirection.rtl
                        ? LucideIcons.circleArrowLeft
                        : LucideIcons.circleArrowRight)
                  : null,
              onPressed: stepBlocked(controller, status!, next)
                  ? null
                  : () => unawaited(confirmJobStep(controller, next)),
            ),
          ],
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Space.cardRadius),
        boxShadow: cardShadow,
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.all(Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          actionWidget,
          const SizedBox(height: Space.xs),
          Freshness(
            at: controller.lastFetched.value,
            error: controller.error.value,
          ),
        ],
      ),
    );
  }
}
