import 'dart:async';

import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../app/crew_routes.dart';
import '../../services/live_service.dart';
import '../job/job_widgets.dart';
import 'crew_controller.dart';

/// One screen, three states: no shift → start a shift; new job → full-screen alert; job → steps.
class CrewHomeView extends StatelessWidget {
  const CrewHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CrewController>();
    return Obx(() {
      final started = c.shiftStarted.value;
      if (started != null) {
        return _ShiftStartedView(shift: started, onDone: c.dismissShiftStarted);
      }
      final me = Get.find<SessionService>().me.value;
      final isDriver = me?.isDriver ?? false;
      if (isDriver && c.onShift && c.alerting.value && c.job.value.hasJob) {
        return Scaffold(
          body: JobAlert(
            job: c.job.value,
            clockOffset: c.serverClockOffset,
            onConfirm: () => unawaited(c.confirm()),
          ),
        );
      }
      final hasJob = c.onShift && c.job.value.hasJob;

      if (hasJob && isDriver) {
        return _DriverFullScreenJobView(controller: c, job: c.job.value);
      }

      return Scaffold(
        appBar: AppBar(
          title: Text((c.onShift ? 'on_shift' : 'off_shift').tr),
          bottom: const SyncBar(),
          actions: [
            IconButton(
              key: const Key('open_settings'),
              tooltip: 'settings'.tr,
              icon: const Icon(LucideIcons.settings, size: 22),
              onPressed: () => Get.toNamed<void>(CrewRoutes.settings),
            ),
            const SizedBox(width: Space.xs),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: c.refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Space.screen,
              Space.sm,
              Space.screen,
              Space.xxl,
            ),
            children: [
              if (c.cancelledNotice.value) ...[
                _Notice(text: 'job_cancelled'.tr, onClose: c.dismissCancelled),
                const SizedBox(height: Space.lg),
              ],
              if (!c.onShift)
                const _StartShift()
              else if (hasJob)
                const _JobPanel()
              else
                const _Waiting(),
            ],
          ),
        ),
        bottomNavigationBar: hasJob && isDriver
            ? const _NextStepBar()
            : c.onShift
            ? const _EndShiftBar()
            : null,
      );
    });
  }
}

/// Ending a shift is a primary shift action, so keep it reachable at the
/// bottom of the waiting-for-job screen as well as in Settings.
class _EndShiftBar extends StatelessWidget {
  const _EndShiftBar();

  @override
  Widget build(BuildContext context) => BottomActionBar(
    child: AppButton(
      key: const Key('end_shift_home'),
      label: 'end_shift'.tr,
      variant: ButtonVariant.secondary,
      icon: LucideIcons.logOut,
      onPressed: () => unawaited(_endShift(context)),
    ),
  );

  Future<void> _endShift(BuildContext context) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('end_shift'.tr),
        content: Text('end_shift_body'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text('end_shift'.tr),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    try {
      await Get.find<CrewController>().endShift();
    } on Object catch (e) {
      final error = ApiError.of(e);
      showToast(
        error.code == 'SHIFT_HAS_JOB'
            ? 'finish_job_first'.tr
            : error.message(currentLang()),
      );
    }
  }
}

class _ShiftStartedView extends StatefulWidget {
  const _ShiftStartedView({required this.shift, required this.onDone});

  final Shift shift;
  final VoidCallback onDone;

  @override
  State<_ShiftStartedView> createState() => _ShiftStartedViewState();
}

class _ShiftStartedViewState extends State<_ShiftStartedView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), widget.onDone);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IconTile(LucideIcons.circleCheck, size: 72, iconSize: 36),
              const SizedBox(height: Space.lg),
              Text(
                'shift_started'.tr,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (widget.shift.plateNumber != null) ...[
                const SizedBox(height: Space.sm),
                Text(
                  widget.shift.plateNumber!,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.onClose});
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

class _StartShift extends StatefulWidget {
  const _StartShift();

  @override
  State<_StartShift> createState() => _StartShiftState();
}

class _StartShiftState extends State<_StartShift> {
  final _manual = TextEditingController();
  bool _busy = false;
  ApiError? _error;

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  Future<void> _go({
    required bool join,
    String? token,
    bool manualCode = false,
  }) async {
    // GetMaterialApp stores named pages as `GetPage<dynamic>`. Asking Flutter
    // for Route<String> makes Navigator cast that dynamic route at runtime.
    final scanned = token == null
        ? await Get.toNamed<dynamic>(CrewRoutes.scan)
        : null;
    final qr = token ?? (scanned is String ? scanned : null);
    if (qr == null || qr.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Get.find<CrewController>().startShift(
        qr,
        join: join,
        code: manualCode,
      );
    } on Object catch (e) {
      final error = ApiError.of(e);
      if (error.code == 'NOT_FOUND' || error.code == 'OUTSIDE_SCOPE') {
        _manual.clear();
      }
      if (error.code == 'VALIDATION_ERROR') {
        debugPrint('[crew shift] unexpected validation error: ${error.code}');
      }
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconTile(LucideIcons.scanQrCode, size: 56, iconSize: 28),
              ),
              const SizedBox(height: Space.lg),
              Text('start_shift_title'.tr, style: t.titleMedium),
              const SizedBox(height: Space.xs),
              Text(
                'start_shift_body'.tr,
                style: t.bodyLarge!.copyWith(color: AppColors.inkMuted),
              ),
              const SizedBox(height: Space.xl),
              if (_error != null) ...[
                ErrorBanner(
                  message:
                      (_error!.code == 'NOT_FOUND' ||
                          _error!.code == 'OUTSIDE_SCOPE')
                      ? 'ambulance_code_not_found'.tr
                      : _error!.message(currentLang()),
                  reference: _error!.isUnexpected ? _error!.reference : null,
                ),
                const SizedBox(height: Space.lg),
              ],
              AppButton(
                key: const Key('scan_start'),
                label: 'scan_start_shift'.tr,
                icon: LucideIcons.scanQrCode,
                busy: _busy,
                height: 52,
                onPressed: () => unawaited(_go(join: false)),
              ),
              const SizedBox(height: Space.sm),
              AppButton(
                key: const Key('scan_join'),
                label: 'scan_join_shift'.tr,
                variant: ButtonVariant.secondary,
                icon: LucideIcons.users,
                height: 52,
                onPressed: _busy ? null : () => unawaited(_go(join: true)),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.lg),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              leading: const Icon(
                LucideIcons.keyboard,
                size: 20,
                color: AppColors.inkMuted,
              ),
              title: Text('qr_manual'.tr, style: t.labelLarge),
              childrenPadding: const EdgeInsets.only(bottom: Space.lg),
              children: [
                LabeledField(
                  fieldKey: const Key('qr_manual'),
                  label: 'qr_code'.tr,
                  controller: _manual,
                  ltr: true,
                ),
                const SizedBox(height: Space.sm),
                AppButton(
                  key: const Key('qr_manual_start'),
                  label: 'start_shift'.tr,
                  variant: ButtonVariant.secondary,
                  onPressed: _busy
                      ? null
                      : () => unawaited(
                          _go(
                            join: false,
                            token: _manual.text,
                            manualCode: true,
                          ),
                        ),
                ),
                const SizedBox(height: Space.sm),
                AppButton(
                  key: const Key('qr_manual_join'),
                  label: 'join_shift'.tr,
                  variant: ButtonVariant.secondary,
                  onPressed: _busy
                      ? null
                      : () => unawaited(
                          _go(
                            join: true,
                            token: _manual.text,
                            manualCode: true,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CrewController>();
    final live = Get.isRegistered<LiveService>()
        ? Get.find<LiveService>()
        : null;
    final t = Theme.of(context).textTheme;
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              children: [
                const IconTile(LucideIcons.ambulance, size: 64, iconSize: 32),
                const SizedBox(height: Space.lg),
                if (c.shift.value?.plateNumber != null) ...[
                  Text(
                    c.shift.value!.plateNumber!,
                    style: t.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  if (c.shift.value!.hospital(currentLang()) != null) ...[
                    const SizedBox(height: Space.xs),
                    Text(
                      c.shift.value!.hospital(currentLang())!,
                      style: t.bodyMedium!.copyWith(color: AppColors.inkMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (_partner(c.shift.value!) != null) ...[
                    const SizedBox(height: Space.sm),
                    Text(
                      'shift_partner'.trParams({
                        'name':
                            _partner(c.shift.value!)!.name(currentLang()) ?? '',
                      }),
                      style: t.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: Space.lg),
                ],
                Text(
                  'waiting_job_title'.tr,
                  style: t.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Space.xs),
                Text(
                  'waiting_job_body'.tr,
                  style: t.bodyLarge!.copyWith(color: AppColors.inkMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Space.lg),
                StatusChip(
                  label:
                      ((live?.connected.value ?? false)
                              ? 'live_on'
                              : 'live_polling')
                          .tr,
                  tone: (live?.connected.value ?? false)
                      ? Tone.info
                      : Tone.neutral,
                  icon: (live?.connected.value ?? false)
                      ? LucideIcons.radio
                      : LucideIcons.refreshCw,
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          _Freshness(at: c.lastFetched.value, error: c.error.value),
        ],
      ),
    );
  }

  ShiftCrewMember? _partner(Shift shift) {
    for (final member in shift.crew) {
      if (!member.me) return member;
    }
    return null;
  }
}

/// "Updated 2 min ago" or the last error.
class _Freshness extends StatelessWidget {
  const _Freshness({required this.at, required this.error});
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

class _JobPanel extends StatelessWidget {
  const _JobPanel();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CrewController>();
    final t = Theme.of(context).textTheme;
    return Obx(() {
      final me = Get.find<SessionService>().me.value;
      final j = c.job.value;
      final lang = currentLang();
      final status = j.jobStatus;
      final p = Priority.fromCode(j.priority);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            stripe: p?.fill,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (p != null) PriorityPill(p),
                    JobStatusChip(status),
                  ],
                ),
                // Time row: sent-ago + current-status duration
                _JobTimeBadges(job: j),
                const SizedBox(height: Space.lg),
                if (j.complaint != null)
                  Text(
                    j.complaint!,
                    style: t.headlineSmall!.copyWith(fontSize: 22),
                  ),
                if (j.caseNumber != null) ...[
                  const SizedBox(height: Space.xs),
                  LtrText(
                    j.caseNumber!,
                    style: t.labelMedium!.copyWith(color: AppColors.inkMuted),
                  ),
                ],
                if (j.landmark(lang) != null ||
                    j.directions != null ||
                    j.hospital(lang) != null) ...[
                  const SizedBox(height: Space.lg),
                  const Divider(),
                  const SizedBox(height: Space.lg),
                ],
                if (j.landmark(lang) != null) ...[
                  InfoRow(
                    icon: LucideIcons.landmark,
                    label: 'landmark'.tr,
                    text: j.landmark(lang)!,
                  ),
                  const SizedBox(height: Space.md),
                ],
                if (j.directions != null) ...[
                  InfoRow(
                    icon: LucideIcons.signpost,
                    label: 'directions_note'.tr,
                    text: j.directions!,
                  ),
                  const SizedBox(height: Space.md),
                ],
                if (j.hospital(lang) != null)
                  InfoRow(
                    icon: LucideIcons.hospital,
                    label: 'destination'.tr,
                    text: j.hospital(lang)!,
                  ),
              ],
            ),
          ),
          if (j.hasLocation) ...[
            const SizedBox(height: Space.lg),
            JobMap(job: j, height: 220),
          ],
          if ((me?.isParamedic ?? false) &&
              status != null &&
              status != JobStatus.sent &&
              !status.isClosed) ...[
            const SizedBox(height: Space.betweenCards),
            SectionHeader(
              'prearrival_alert'.tr,
              subtitle: 'prearrival_alert_body'.tr,
            ),
            AlertGrid(onAlert: c.raiseAlert),
          ],
          if (me?.isParamedic ?? false) ...[
            const SizedBox(height: Space.betweenCards),
            RowGroup(
              children: [
                ListRow(
                  key: const Key('open_patients'),
                  icon: LucideIcons.stethoscope,
                  title: 'patient_care'.tr,
                  subtitle: 'patient_care_body'.tr,
                  onTap: () => Get.toNamed<void>(CrewRoutes.patients),
                ),
              ],
            ),
          ],
          const SizedBox(height: Space.lg),
          _Freshness(at: c.lastFetched.value, error: c.error.value),
        ],
      );
    });
  }
}

/// Completing at the scene skips the hospital: ask first, it cannot be undone.
Future<void> _confirmJobStep(CrewController c, JobStatus next) async {
  if (next == JobStatus.completed &&
      c.job.value.jobStatus == JobStatus.onScene) {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text('complete_at_scene_title'.tr),
        content: Text('complete_at_scene_body'.tr),
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
  }
  await c.advance(next);
}

/// The next step, always at the bottom within thumb reach. Swipe while the job is unconfirmed.
class _NextStepBar extends StatelessWidget {
  const _NextStepBar();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CrewController>();
    return Obx(() {
      final status = c.job.value.jobStatus;
      if (status == null || status.isClosed) return const SizedBox.shrink();
      if (status == JobStatus.sent) {
        return BottomActionBar(
          child: SwipeToConfirm(
            key: const Key('swipe_accept_inline'),
            label: 'swipe_to_accept'.tr,
            onConfirmed: () => unawaited(c.confirm()),
          ),
        );
      }
      final steps = status.next.where((s) => s != JobStatus.confirmed).toList();
      return BottomActionBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final next in steps) ...[
              if (next != steps.first) const SizedBox(height: Space.xs),
              AppButton(
                key: Key('step_${next.wire}'),
                label: 'step_${next.wire}'.tr,
                height: next == status.primaryNext ? 56 : Space.minTarget,
                variant: next == status.primaryNext
                    ? ButtonVariant.primary
                    : ButtonVariant.ghost,
                icon: next == status.primaryNext
                    ? (Directionality.of(context) == TextDirection.rtl
                          ? LucideIcons.circleArrowLeft
                          : LucideIcons.circleArrowRight)
                    : null,
                onPressed: () => unawaited(_confirmJobStep(c, next)),
              ),
            ],
          ],
        ),
      );
    });
  }
}

/// Uber-style driver interface: full screen navigation map with floating information cards and controls.
class _DriverFullScreenJobView extends StatelessWidget {
  const _DriverFullScreenJobView({required this.controller, required this.job});

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
                        _Notice(
                          text: 'job_cancelled'.tr,
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
                    InkWell(
                      borderRadius: BorderRadius.circular(Space.sm),
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          _expanded
                              ? LucideIcons.chevronUp
                              : LucideIcons.chevronDown,
                          size: 20,
                          color: AppColors.inkMuted,
                        ),
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
                _JobTimeBadges(job: j),
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
  Widget build(BuildContext context) {
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
          for (final next in steps) ...[
            if (next != steps.first) const SizedBox(height: Space.xs),
            AppButton(
              key: Key('step_${next.wire}'),
              label: 'step_${next.wire}'.tr,
              height: next == status!.primaryNext ? 56 : Space.minTarget,
              variant: next == status!.primaryNext
                  ? ButtonVariant.primary
                  : ButtonVariant.ghost,
              icon: next == status!.primaryNext
                  ? (Directionality.of(context) == TextDirection.rtl
                        ? LucideIcons.circleArrowLeft
                        : LucideIcons.circleArrowRight)
                  : null,
              onPressed: () => unawaited(_confirmJobStep(controller, next)),
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
          _Freshness(
            at: controller.lastFetched.value,
            error: controller.error.value,
          ),
        ],
      ),
    );
  }
}

/// Two small time badges: how long ago the job was sent, and how long in the current status.
/// Only shows fields the server actually returned. Updates every 60 s.
class _JobTimeBadges extends StatefulWidget {
  const _JobTimeBadges({required this.job});
  final Job job;

  @override
  State<_JobTimeBadges> createState() => _JobTimeBadgesState();
}

class _JobTimeBadgesState extends State<_JobTimeBadges> {
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
