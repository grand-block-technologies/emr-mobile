import 'dart:async';

import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/gps_service.dart';
import '../../services/offline_map/cached_tile_provider.dart';
import '../../services/offline_map/offline_map_service.dart';

/// Chip tone and label for a job status.
(Tone, IconData) toneFor(JobStatus? s) => switch (s) {
  JobStatus.sent => (Tone.danger, LucideIcons.bellRing),
  JobStatus.confirmed => (Tone.info, LucideIcons.check),
  JobStatus.enRoute ||
  JobStatus.leavingScene => (Tone.transit, LucideIcons.ambulance),
  JobStatus.onScene => (Tone.scene, LucideIcons.mapPin),
  JobStatus.atHospital => (Tone.info, LucideIcons.hospital),
  JobStatus.completed => (Tone.done, LucideIcons.circleCheck),
  null => (Tone.neutral, LucideIcons.circleHelp),
};

class JobStatusChip extends StatelessWidget {
  const JobStatusChip(this.status, {super.key});
  final JobStatus? status;

  @override
  Widget build(BuildContext context) {
    final (tone, icon) = toneFor(status);
    return StatusChip(
      label: 'status_${status?.wire ?? 'unknown'}'.tr,
      tone: tone,
      icon: icon,
    );
  }
}

/// Full-screen alarm for a new job (AMD-02): repeats sound + vibration until swiped.
/// TODO(push): a true lock-screen alarm needs a full-screen-intent notification once FCM is live.
class JobAlert extends StatefulWidget {
  const JobAlert({
    required this.job,
    required this.onConfirm,
    this.clockOffset = Duration.zero,
    super.key,
  });
  final Job job;
  final VoidCallback onConfirm;
  final Duration clockOffset;

  @override
  State<JobAlert> createState() => _JobAlertState();
}

class _JobAlertState extends State<JobAlert> {
  Timer? _alarm;

  @override
  void initState() {
    super.initState();
    _ring();
    _alarm = Timer.periodic(const Duration(seconds: 2), (_) => _ring());
  }

  void _ring() {
    unawaited(HapticFeedback.heavyImpact());
    unawaited(SystemSound.play(SystemSoundType.alert));
  }

  @override
  void dispose() {
    _alarm?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.job;
    final lang = currentLang();
    final p = Priority.fromCode(j.priority);
    const onDark = TextStyle(color: Colors.white);
    return Container(
      color: p == Priority.p1 || p == Priority.p2
          ? p!.fill
          : AppColors.brandActive,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.bellRing,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Text(
                      'new_job'.tr,
                      style: onDark.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.xxl),
              if (p != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: PriorityPill(p),
                ),
              const SizedBox(height: Space.lg),
              if (j.complaint != null)
                Text(
                  j.complaint!,
                  style: onDark.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (j.landmark(lang) != null) ...[
                const SizedBox(height: Space.sm),
                Text(j.landmark(lang)!, style: onDark.copyWith(fontSize: 17)),
              ],
              if (j.caseNumber != null) ...[
                const SizedBox(height: Space.sm),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: LtrText(
                    j.caseNumber!,
                    style: onDark.copyWith(fontSize: 15),
                  ),
                ),
              ],
              if (j.confirmDeadlineAt != null) ...[
                const SizedBox(height: Space.md),
                JobConfirmDeadline(
                  deadline: j.confirmDeadlineAt!,
                  clockOffset: widget.clockOffset,
                ),
              ],
              const Spacer(),
              _JobAlertAction(onConfirm: widget.onConfirm),
            ],
          ),
        ),
      ),
    );
  }
}

/// Confirmation is deliberately unavailable while the location provider is
/// off: without it the crew is invisible when the vehicle tracker is silent.
class _JobAlertAction extends StatelessWidget {
  const _JobAlertAction({required this.onConfirm});
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final gps = Get.isRegistered<GpsService>() ? Get.find<GpsService>() : null;
    if (gps == null) {
      return SwipeToConfirm(
        key: const Key('swipe_accept'),
        label: 'swipe_to_accept'.tr,
        onConfirmed: onConfirm,
      );
    }
    return Obx(() {
      if (gps.permitted.value) {
        return SwipeToConfirm(
          key: const Key('swipe_accept'),
          label: 'swipe_to_accept'.tr,
          onConfirmed: onConfirm,
        );
      }
      return Container(
        key: const Key('location_off_warning'),
        padding: const EdgeInsets.all(Space.lg),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(Space.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(LucideIcons.mapPinOff, color: Colors.white, size: 30),
            const SizedBox(height: Space.sm),
            Text(
              'location_required'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Space.sm),
            TextButton(
              onPressed: () => unawaited(gps.start(onJob: true)),
              child: Text(
                'try_again'.tr,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// A server-clock-corrected deadline for acknowledging an incoming job.
/// It deliberately appears only on the new-job alarm: after confirmation, the
/// deadline has no operational value to the crew.
class JobConfirmDeadline extends StatefulWidget {
  const JobConfirmDeadline({
    required this.deadline,
    required this.clockOffset,
    super.key,
  });

  final DateTime deadline;
  final Duration clockOffset;

  @override
  State<JobConfirmDeadline> createState() => _JobConfirmDeadlineState();
}

class _JobConfirmDeadlineState extends State<JobConfirmDeadline> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.deadline.difference(
      DateTime.now().toUtc().add(widget.clockOffset),
    );
    final expired = remaining.isNegative;
    final seconds = remaining.inSeconds.clamp(0, 359999);
    final time =
        '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';
    final urgent = !expired && seconds < 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 4),
      decoration: BoxDecoration(
        color: urgent ? Colors.red.shade700 : Colors.black38,
        borderRadius: BorderRadius.circular(Space.sm),
      ),
      child: Text(
        expired
            ? 'confirm_deadline_expired'.tr
            : 'confirm_deadline'.trParams({'t': time}),
        style: TextStyle(
          color: expired ? Colors.white70 : Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Approximate pin as a circle of `pinRadiusM`, plus the crew's own position.
class JobMap extends StatelessWidget {
  const JobMap({
    required this.job,
    super.key,
    this.height = 200,
    this.isFullScreen = false,
    this.showDirectionsButton = true,
  });

  /// Off in widget tests (no tile downloads there).
  static bool showTiles = true;

  final Job job;
  final double height;
  final bool isFullScreen;
  final bool showDirectionsButton;

  @override
  Widget build(BuildContext context) {
    if (!job.hasLocation && !isFullScreen) return const SizedBox.shrink();
    final target = job.hasLocation
        ? LatLng(job.lat!, job.lon!)
        : const LatLng(15.581, 32.556);
    final gps = Get.isRegistered<GpsService>() ? Get.find<GpsService>() : null;

    // Keep the map and tile layer out of the GPS observer. Rebuilding FlutterMap
    // for every location fix restarts tile layout/loading, which is especially
    // noticeable with the 512 px online tiles.
    final mapWidget = FlutterMap(
      options: MapOptions(initialCenter: target, initialZoom: 15),
      children: [
        if (showTiles)
          TileLayer(
            urlTemplate: Get.find<AppConfig>().tileUrlTemplate,
            userAgentPackageName: 'sd.gov.emr.crew',
            // Every tile seen is kept on the phone, so the map still draws offline.
            tileProvider: Get.isRegistered<OfflineMapService>()
                ? CachedTileProvider(Get.find<OfflineMapService>().store)
                : null,
          ),
        if (job.hasLocation)
          CircleLayer(
            circles: [
              CircleMarker(
                point: target,
                radius: (job.pinRadiusM ?? 300).toDouble(),
                useRadiusInMeter: true,
                color: AppColors.danger.withValues(alpha: 0.15),
                borderColor: AppColors.danger,
                borderStrokeWidth: 2,
              ),
            ],
          ),
        if (gps == null)
          _MapMarkers(job: job, target: target)
        else
          Obx(
            () => _MapMarkers(
              job: job,
              target: target,
              crewPosition: gps.last.value,
            ),
          ),
        RichAttributionWidget(
          // Opposite side from the directions pill (which sits at the end edge).
          alignment: Directionality.of(context) == TextDirection.rtl
              ? AttributionAlignment.bottomRight
              : AttributionAlignment.bottomLeft,
          attributions: const [
            TextSourceAttribution('© OpenStreetMap contributors'),
          ],
        ),
      ],
    );

    final directionsButton = (showDirectionsButton && job.hasLocation)
        ? PositionedDirectional(
            end: Space.md,
            bottom: Space.md,
            child: FilledButton.icon(
              key: const Key('directions'),
              style:
                  FilledButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.brand,
                    elevation: 3,
                    shadowColor: AppColors.ink.withValues(alpha: 0.3),
                    shape: const StadiumBorder(),
                  ).copyWith(
                    overlayColor: const WidgetStatePropertyAll(
                      AppColors.brandSoft,
                    ),
                  ),
              onPressed: () => unawaited(openDirections(job.lat!, job.lon!)),
              icon: const Icon(LucideIcons.navigation, size: 18),
              label: Text('directions'.tr),
            ),
          )
        : null;

    if (isFullScreen) {
      return Stack(
        children: [
          Positioned.fill(child: mapWidget),
          ?directionsButton,
        ],
      );
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Space.cardRadius),
        border: Border.all(color: AppColors.line),
        boxShadow: cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: mapWidget),
          ?directionsButton,
        ],
      ),
    );
  }
}

class _MapMarkers extends StatelessWidget {
  const _MapMarkers({
    required this.job,
    required this.target,
    this.crewPosition,
  });

  final Job job;
  final LatLng target;
  final Fix? crewPosition;

  @override
  Widget build(BuildContext context) => MarkerLayer(
    markers: [
      if (job.hasLocation)
        Marker(
          point: target,
          child: const Icon(
            LucideIcons.mapPin,
            color: AppColors.danger,
            size: 28,
          ),
        ),
      if (crewPosition != null)
        Marker(
          point: LatLng(crewPosition!.lat, crewPosition!.lon),
          child: const Icon(
            LucideIcons.navigation,
            color: AppColors.transit,
            size: 24,
          ),
        ),
    ],
  );
}

/// Opens turn-by-turn directions in the phone's maps app.
Future<void> openDirections(double lat, double lon) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon',
  );
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    showToast('cannot_open_maps'.tr);
  }
}

/// Icon for each pre-arrival alert type.
IconData alertIcon(AlertType t) => switch (t) {
  AlertType.stroke => LucideIcons.brain,
  AlertType.stemi => LucideIcons.heartPulse,
  AlertType.trauma => LucideIcons.bone,
  AlertType.sepsis => LucideIcons.biohazard,
  AlertType.cardiacArrest => LucideIcons.heartCrack,
  AlertType.obstetric => LucideIcons.baby,
  AlertType.other => LucideIcons.circleAlert,
};

/// One large tile per pre-arrival alert type (icon + word), each with a confirm.
class AlertGrid extends StatelessWidget {
  const AlertGrid({required this.onAlert, super.key});
  final Future<void> Function(AlertType type) onAlert;

  Future<void> _confirm(AlertType t) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        icon: IconTile(alertIcon(t), tone: Tone.danger),
        title: Text('alert_confirm_title'.tr),
        content: Text(
          'alert_confirm_body'.trParams({'type': 'alert_${t.wire}'.tr}),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            key: const Key('alert_send'),
            onPressed: () => Get.back(result: true),
            child: Text('send'.tr),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      await onAlert(t);
      showToast('alert_queued'.tr);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final w = (c.maxWidth - Space.sm) / 2;
      return Wrap(
        spacing: Space.sm,
        runSpacing: Space.sm,
        children: [
          for (final t in AlertType.values)
            SizedBox(
              width: w,
              child: Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Space.cardRadius),
                  side: const BorderSide(color: AppColors.line),
                ),
                clipBehavior: Clip.antiAlias,
                child: Semantics(
                  button: true,
                  child: InkWell(
                    key: Key('alert_${t.wire}'),
                    onTap: () => _confirm(t),
                    child: Padding(
                      padding: const EdgeInsets.all(Space.md),
                      child: Row(
                        children: [
                          IconTile(
                            alertIcon(t),
                            size: 36,
                            iconSize: 18,
                            tone: Tone.danger,
                          ),
                          const SizedBox(width: Space.md),
                          Expanded(
                            child: Text(
                              'alert_${t.wire}'.tr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
