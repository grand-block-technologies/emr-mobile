import 'dart:async';

import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/crew_routes.dart';
import '../../services/live_service.dart';
import '../job/job_widgets.dart';
import '../patient/patient_controller.dart';
import '../patient/patient_views.dart';
import 'crew_controller.dart';
import 'driver_job_view.dart';
import 'job_shared.dart';

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
        return DriverFullScreenJobView(controller: c, job: c.job.value);
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
          onRefresh: () async {
            await c.reloadShift();
            await c.refresh();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Space.screen,
              Space.sm,
              Space.screen,
              Space.xxl,
            ),
            children: [
              if (c.cancelledNotice.value) ...[
                Notice(text: cancelledText(c), onClose: c.dismissCancelled),
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

bool _isCodeNotFound(ApiError e) =>
    e.code == 'NOT_FOUND' ||
    e.code == 'OUTSIDE_SCOPE' ||
    e.code == 'SHIFT_CODE_NOT_FOUND';

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
    if (manualCode && !RegExp(r'^[0-9]{6}$').hasMatch(qr.trim())) {
      // Checked on the phone first: the printed shift code is exactly 6 digits.
      setState(() => _error = const ApiError(
        status: 400,
        code: 'SHIFT_CODE_NOT_FOUND',
        ar: '',
        en: '',
      ));
      return;
    }
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
      if (_isCodeNotFound(error)) _manual.clear();
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
                  message: _isCodeNotFound(_error!)
                      ? 'ambulance_code_not_found'.tr
                      : _error!.code == 'AMBULANCE_UNAVAILABLE'
                      ? '${_error!.message(currentLang())}\n${'join_after_job'.tr}'
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
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  helper: 'shift_code_help'.tr,
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
                if (c.waitingForDriver) ...[
                  const SizedBox(height: Space.md),
                  Text(
                    'waiting_driver'.tr,
                    key: const Key('waiting_driver'),
                    style: t.bodyMedium!.copyWith(color: AppColors.warning),
                    textAlign: TextAlign.center,
                  ),
                ],
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
          RowGroup(
            children: [
              ListRow(
                key: const Key('open_history'),
                icon: LucideIcons.history,
                title: 'history_title'.tr,
                subtitle: 'history_body'.tr,
                onTap: () => Get.toNamed<void>(CrewRoutes.history),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          Freshness(at: c.lastFetched.value, error: c.error.value),
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
                JobTimeBadges(job: j),
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
          if (status == JobStatus.leavingScene ||
              status == JobStatus.atHospital) ...[
            const SizedBox(height: Space.lg),
            HandoverCard(
              canHandOver: c.canHandOver,
              missing: c.handoverMissing.value,
              handovers: j.handovers,
              onOpen: () => Get.toNamed<void>(CrewRoutes.handover),
            ),
          ],
          if (me?.isParamedic ?? false) ...[
            const SizedBox(height: Space.lg),
            AppButton(
              key: const Key('quick_vitals'),
              label: (Get.find<PatientController>().hasVitals ? 'vitals_update' : 'vitals_add').tr,
              icon: LucideIcons.heartPulse,
              height: 56,
              onPressed: () => unawaited(startQuickVitals(context)),
            ),
          ],
          if (j.hasLocation) ...[
            const SizedBox(height: Space.lg),
            JobMap(job: j, height: 220),
          ],
          if ((me?.isParamedic ?? false) &&
              status != null &&
              status != JobStatus.sent &&
              !status.isClosed &&
              (me?.alertsEnabled ?? false)) ...[
            const SizedBox(height: Space.betweenCards),
            SectionHeader(
              'prearrival_alert'.tr,
              subtitle: 'prearrival_alert_body'.tr,
            ),
            AlertGrid(onAlert: c.raiseAlert),
          ],
          const SizedBox(height: Space.lg),
          Freshness(at: c.lastFetched.value, error: c.error.value),
        ],
      );
    });
  }
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
                label: stepLabel(status, next),
                height: next == status.primaryNext ? 56 : Space.minTarget,
                variant: next == status.primaryNext
                    ? ButtonVariant.primary
                    : ButtonVariant.ghost,
                icon: next == status.primaryNext
                    ? (Directionality.of(context) == TextDirection.rtl
                          ? LucideIcons.circleArrowLeft
                          : LucideIcons.circleArrowRight)
                    : null,
                onPressed: stepBlocked(c, status, next)
                    ? null
                    : () => unawaited(confirmJobStep(c, next)),
              ),
            ],
          ],
        ),
      );
    });
  }
}
