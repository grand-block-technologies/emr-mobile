import 'dart:async';

import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/crew_routes.dart';
import '../../services/offline_map/offline_map_service.dart';
import '../../services/offline_map/tile_math.dart';
import 'crew_controller.dart';

class CrewSettingsView extends StatelessWidget {
  const CrewSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CrewController>();
    final session = Get.find<SessionService>();
    final outbox = Get.find<OutboxService>();
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            Space.sm,
            Space.screen,
            Space.xxl,
          ),
          children: [
            Obx(() {
              final me = session.me.value;
              final name = me?.displayName(currentLang()) ?? '';
              return AppCard(
                child: Row(
                  children: [
                    AvatarInitials(name),
                    const SizedBox(width: Space.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: t.titleMedium),
                          const SizedBox(height: 2),
                          LtrText(me?.username ?? '', style: t.bodySmall),
                          if (me?.role != null) ...[
                            const SizedBox(height: Space.sm),
                            StatusChip(
                              label: 'role_${me!.role}'.tr,
                              tone: Tone.neutral,
                              icon: LucideIcons.idCard,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: Space.betweenCards),
            SectionHeader('data_on_phone'.tr),
            RowGroup(
              children: [
                ListRow(
                  icon: LucideIcons.cloud,
                  title: 'sync_status'.tr,
                  detail: const LiveSyncChip(),
                  showChevron: false,
                ),
                ListRow(
                  icon: LucideIcons.refreshCw,
                  title: 'send_now'.tr,
                  onTap: outbox.nudge,
                  showChevron: false,
                ),
              ],
            ),
            if (Get.isRegistered<OfflineMapService>()) ...[
              const SizedBox(height: Space.betweenCards),
              SectionHeader('offline_map'.tr),
              const OfflineMapCard(),
            ],
            const SizedBox(height: Space.betweenCards),
            SectionHeader('preferences'.tr),
            RowGroup(
              children: [
                ListRow(
                  icon: LucideIcons.languages,
                  title: 'language'.tr,
                  trailing: const LanguageToggle(),
                  showChevron: false,
                ),
              ],
            ),
            const SizedBox(height: Space.betweenCards),
            Obx(
              () => c.onShift
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: Space.sm),
                      child: AppButton(
                        key: const Key('end_shift'),
                        label: 'end_shift'.tr,
                        variant: ButtonVariant.secondary,
                        icon: LucideIcons.logOut,
                        onPressed: () => unawaited(_endShift(c)),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            SignOutButton(onPressed: () => _signOut(session, outbox)),
          ],
        ),
      ),
    );
  }

  Future<void> _endShift(CrewController c) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text('end_shift'.tr),
        content: Text('end_shift_body'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            key: const Key('end_shift_confirm'),
            onPressed: () => Get.back(result: true),
            child: Text('end_shift'.tr),
          ),
        ],
      ),
    );
    if (!(ok ?? false)) return;
    try {
      await c.endShift();
      Get.back<void>();
    } on Object catch (e) {
      final error = ApiError.of(e);
      if (error.code != 'SHIFT_HAS_JOB') {
        showToast(error.message(currentLang()));
        return;
      }
      final openJob = await Get.dialog<bool>(
        AlertDialog(
          title: Text('end_shift'.tr),
          content: Text('finish_job_first'.tr),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('cancel'.tr),
            ),
            FilledButton(
              onPressed: () => Get.back(result: true),
              child: Text('open_job'.tr),
            ),
          ],
        ),
      );
      if (openJob ?? false) {
        await Get.offAllNamed<void>(CrewRoutes.home);
      }
    }
  }

  /// Signing out wipes the queue, so unsent changes are lost: say so first.
  Future<void> _signOut(SessionService session, OutboxService outbox) async {
    final pending = outbox.items.length;
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text('sign_out'.tr),
        content: Text(
          pending == 0
              ? 'sign_out_body'.tr
              : 'sign_out_pending'.trParams({'n': '$pending'}),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            key: const Key('sign_out_confirm'),
            style: pending == 0
                ? null
                : FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Get.back(result: true),
            child: Text('sign_out'.tr),
          ),
        ],
      ),
    );
    if (ok ?? false) await session.signOut();
  }
}

/// Offline OpenStreetMap: what is saved on the phone, and the Khartoum download when allowed.
class OfflineMapCard extends StatefulWidget {
  const OfflineMapCard({super.key});

  @override
  State<OfflineMapCard> createState() => _OfflineMapCardState();
}

class _OfflineMapCardState extends State<OfflineMapCard> {
  OfflineMapService get m => Get.find<OfflineMapService>();
  int? _bytes;

  @override
  void initState() {
    super.initState();
    unawaited(_size());
  }

  Future<void> _size() async {
    final b = await m.cacheBytes();
    if (mounted) setState(() => _bytes = b);
  }

  Future<void> _download() async {
    try {
      final r = await m.downloadRegion(GeoBounds.khartoum);
      showToast(
        r.failed == 0
            ? 'offline_map_done'.tr
            : 'offline_map_failed'.trParams({'n': '${r.failed}'}),
      );
    } on Object catch (e) {
      showToast(ApiError.of(e).message(currentLang()));
    }
    await _size();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final mb = ((_bytes ?? 0) / (1024 * 1024)).toStringAsFixed(1);
    return AppCard(
      child: Obx(() {
        final p = m.progress.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'offline_map_body'.tr,
              style: t.bodyLarge!.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: Space.sm),
            Row(
              children: [
                Text('${'offline_map_size'.tr} ', style: t.bodySmall),
                LtrText('$mb MB', style: t.bodySmall),
              ],
            ),
            const SizedBox(height: Space.inCard),
            if (p.running) ...[
              LinearProgressIndicator(
                value: p.fraction,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: Space.sm),
              Text(
                'offline_map_downloading'.trParams({
                  'done': '${p.done}',
                  'total': '${p.total}',
                }),
                style: t.bodySmall,
              ),
              const SizedBox(height: Space.sm),
              AppButton(
                label: 'cancel'.tr,
                variant: ButtonVariant.secondary,
                onPressed: m.cancel,
              ),
            ] else if (m.canDownloadRegions)
              AppButton(
                key: const Key('offline_map_download'),
                label: 'offline_map_download'.trParams({
                  'n': '${m.estimate(GeoBounds.khartoum)}',
                }),
                variant: ButtonVariant.secondary,
                icon: LucideIcons.download,
                onPressed: () => unawaited(_download()),
              )
            else
              Text('offline_map_policy'.tr, style: t.bodySmall),
            const SizedBox(height: Space.sm),
            AppButton(
              label: 'offline_map_clear'.tr,
              variant: ButtonVariant.ghost,
              onPressed: p.running
                  ? null
                  : () async {
                      await m.clear();
                      await _size();
                    },
            ),
          ],
        );
      }),
    );
  }
}
