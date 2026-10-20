import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/citizen_routes.dart';
import '../../services/sos_locator.dart';
import '../sos/sos_controller.dart';
import 'requests_controller.dart';

/// Tone and icon for a citizen-facing status code.
(Tone, IconData) requestTone(RequestStatusCode c) => switch (c) {
  RequestStatusCode.received ||
  RequestStatusCode.findingHospital => (Tone.info, LucideIcons.phoneIncoming),
  RequestStatusCode.hospitalAccepted => (Tone.info, LucideIcons.hospital),
  RequestStatusCode.ambulanceComing ||
  RequestStatusCode.toHospital => (Tone.transit, LucideIcons.ambulance),
  RequestStatusCode.ambulanceArrived => (Tone.scene, LucideIcons.mapPin),
  RequestStatusCode.closed => (Tone.done, LucideIcons.circleCheck),
  RequestStatusCode.unknown => (Tone.neutral, LucideIcons.circleHelp),
};

class RequestsTab extends StatelessWidget {
  const RequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<RequestsController>();
    return Obx(() {
      if (c.loading.value && c.rows.isEmpty) return const LoadingView();
      if (c.error.value != null && c.rows.isEmpty) {
        return ErrorView(error: c.error.value!, onRetry: c.reload);
      }
      if (c.rows.isEmpty) {
        return EmptyView(
          icon: LucideIcons.clipboardList,
          title: 'no_requests_title'.tr,
          body: 'no_requests_body'.tr,
        );
      }
      final lang = currentLang();
      return RefreshIndicator(
        onRefresh: c.reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            Space.sm,
            Space.screen,
            Space.xxl,
          ),
          children: [
            RowGroup(
              children: [
                for (final r in c.rows)
                  Builder(
                    builder: (_) {
                      final (tone, icon) = requestTone(r.code);
                      return ListRow(
                        key: Key('request_${r.id}'),
                        icon: icon,
                        tone: tone,
                        title: r.status(lang),
                        subtitle: r.startedAt == null
                            ? null
                            : SudanTime.dateTime(r.startedAt!, lang),
                        onTap: () => Get.toNamed<void>(
                          CitizenRoutes.request,
                          arguments: RequestArgs(r.id),
                        ),
                      );
                    },
                  ),
              ],
            ),
            if (c.hasNext.value) ...[
              const SizedBox(height: Space.lg),
              AppButton(
                label: 'load_more'.tr,
                variant: ButtonVariant.secondary,
                busy: c.loadingMore.value,
                onPressed: c.more,
              ),
            ],
          ],
        ),
      );
    });
  }
}

class RequestDetailView extends StatelessWidget {
  const RequestDetailView({super.key});

  static const steps = [
    RequestStatusCode.received,
    RequestStatusCode.findingHospital,
    RequestStatusCode.hospitalAccepted,
    RequestStatusCode.ambulanceComing,
    RequestStatusCode.ambulanceArrived,
    RequestStatusCode.toHospital,
    RequestStatusCode.closed,
  ];

  static const closedSteps = [
    RequestStatusCode.received,
    RequestStatusCode.closed,
  ];

  @override
  Widget build(BuildContext context) {
    final c = Get.find<RequestDetailController>();
    final args = Get.arguments is RequestArgs
        ? Get.arguments as RequestArgs
        : null;
    final t = Theme.of(context).textTheme;
    final number = Get.find<AppConfig>().emergencyNumber;
    return Scaffold(
      appBar: AppBar(title: Text('request_title'.tr)),
      body: Obx(() {
        final s = c.status.value;
        if (s == null && c.error.value != null) {
          return ErrorView(error: c.error.value!, onRetry: c.load);
        }
        if (s == null) return const LoadingView(cards: 1);
        final lang = currentLang();
        final (tone, icon) = requestTone(s.code);
        // A closed request shows the steps it really reached (`reachedSteps`), so a request
        // treated at the scene never ticks "On the way to the hospital".
        final reached = <RequestStatusCode>{
          for (final r in s.reachedSteps)
            if (r.status != RequestStatusCode.unknown) r.status,
        }.toList();
        final shown = !s.isClosed
            ? steps
            : reached.isNotEmpty
            ? [
                ...reached.where((r) => r != RequestStatusCode.closed),
                RequestStatusCode.closed,
              ]
            : closedSteps;
        final current = shown.indexOf(s.code);
        return RefreshIndicator(
          onRefresh: c.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(Space.screen),
            children: [
              if ((args?.justSent ?? false) && !s.isClosed) ...[
                Container(
                  padding: const EdgeInsets.all(Space.lg),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(Space.cardRadius),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.phoneCall,
                        color: AppColors.brandActive,
                      ),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: Text(
                          'keep_phone_free'.tr,
                          style: t.bodyLarge!.copyWith(
                            color: AppColors.brandActive,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.lg),
              ],
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconTile(icon, tone: tone, size: 56, iconSize: 28),
                    const SizedBox(height: Space.lg),
                    Text(
                      s.status(lang),
                      key: const Key('request_status'),
                      style: t.headlineSmall,
                    ),
                    if (s.isClosed && s.closing(lang) != null) ...[
                      const SizedBox(height: Space.sm),
                      Text(
                        s.closing(lang)!,
                        key: const Key('closing_reason'),
                        style: t.bodyLarge,
                      ),
                    ],
                    if (s.hospital(lang) != null) ...[
                      const SizedBox(height: Space.lg),
                      InfoRow(
                        icon: LucideIcons.hospital,
                        label: 'hospital'.tr,
                        text: s.hospital(lang)!,
                      ),
                    ],
                    if (s.updatedAt != null) ...[
                      const SizedBox(height: Space.sm),
                      Text(
                        '${'updated_ago'.tr} ${SudanTime.when(s.updatedAt!, DateTime.now(), lang)}',
                        style: t.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: Space.betweenCards),
              if (current >= 0) ...[
                SectionHeader('progress'.tr),
                AppCard(
                  child: StepTimeline(
                    steps: [for (final st in shown) 'rs_${st.wire}'.tr],
                    current: current,
                  ),
                ),
              ],
              const SizedBox(height: Space.betweenCards),
              if (!s.isClosed)
                AppButton(
                  label: 'call_999'.trParams({'n': number}),
                  variant: ButtonVariant.secondary,
                  icon: LucideIcons.phone,
                  onPressed: () => callNumber(number),
                ),
            ],
          ),
        );
      }),
    );
  }
}
