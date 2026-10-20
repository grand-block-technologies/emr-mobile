import 'dart:async';

import 'package:emr_core/emr_core.dart';
import 'package:get/get.dart';

import '../../app/crew_routes.dart';
import '../../data/crew_repository.dart';
import '../../services/gps_service.dart';
import '../../services/live_service.dart';

/// Server job merged with what the crew already pressed but the server has not seen yet.
/// The server decides the status, but while our own steps are queued we never show it going back.
Job mergeJob({
  required Job local,
  required Job server,
  required bool pending,
  String? completedLocally,
}) {
  if (pending && server.hasJob && server.dispatchId == completedLocally) {
    return Job.none;
  }
  if (!pending || !server.hasJob || server.dispatchId != local.dispatchId) {
    return server;
  }
  final l = local.jobStatus;
  final s = server.jobStatus;
  if (l != null && s != null && l.index > s.index) return server.withStatus(l);
  return server;
}

/// A job the crew has not seen before.
bool isNewJob(Job prev, Job next) =>
    next.hasJob && next.dispatchId != prev.dispatchId;

/// Shift and job lifecycle for the whole crew session: cache-first start, live queue,
/// polling safety net, GPS cadence, optimistic status steps through the outbox.
class CrewController extends GetxService {
  CrewController({
    required CrewRepository repo,
    required OutboxService outbox,
    required LiveService live,
    required GpsService gps,
    bool Function()? canUpdateStatus,
    DateTime Function()? now,
    this.pollEvery = const Duration(seconds: 20),
    this.jobPollEvery = const Duration(seconds: 10),
  }) : _repo = repo,
       _outbox = outbox,
       _live = live,
       _gps = gps,
       _canUpdateStatus =
           canUpdateStatus ??
           (() =>
               !Get.isRegistered<SessionService>() ||
               Get.find<SessionService>().me.value?.isDriver == true),
       _now = now ?? DateTime.now;

  final CrewRepository _repo;
  final OutboxService _outbox;
  final LiveService _live;
  final GpsService _gps;
  final bool Function() _canUpdateStatus;
  final DateTime Function() _now;
  final Duration pollEvery;

  /// While on a job the paramedic must see the driver's steps quickly: the crew queue only
  /// carries `job.new` and `job.cancelled`.
  final Duration jobPollEvery;

  final shift = Rxn<Shift>();
  final job = Job.none.obs;
  final loading = false.obs;
  final error = Rxn<ApiError>();
  final lastFetched = Rxn<DateTime>();

  /// Server clock minus phone clock, updated on every successful poll.
  /// Use `DateTime.now() + serverClockOffset` as the accurate current time.
  var serverClockOffset = Duration.zero;

  /// Set when a new job arrives; the UI shows the full-screen alert until it is confirmed.
  final alerting = false.obs;

  /// Shown once after the server took a job away (cancelled).
  final cancelledNotice = false.obs;

  /// Brief success handoff after a start/join before showing the shift screen.
  final shiftStarted = Rxn<Shift>();

  /// The crew member who hands over has not yet sent a handover for every patient on the job
  /// (or registered none). "Job completed" waits while this is true.
  final handoverMissing = false.obs;

  /// Bumped when a handover was confirmed or a clinical write was refused, so open screens reload their patients.
  final patientsTick = 0.obs;

  /// Medicines for the treatment picker (cached for offline use).
  final medicines = <Medicine>[].obs;

  /// How many refused patient writes were still queued when the server cancelled the job.
  final cancelledUnsent = 0.obs;

  String? _completedLocally;
  Timer? _poll;
  final _subs = <StreamSubscription<Object>>[];
  bool _started = false;

  bool get onShift => shift.value != null;

  /// A paramedic always hands over; a driver only when no paramedic is on the shift
  /// (otherwise the server answers `403 PARAMEDIC_ON_SHIFT`).
  bool get canHandOver {
    final me = Get.isRegistered<SessionService>()
        ? Get.find<SessionService>().me.value
        : null;
    if (me?.isParamedic ?? false) return true;
    if (!(me?.isDriver ?? false)) return false;
    final crew = shift.value?.crew ?? const <ShiftCrewMember>[];
    return !crew.any((m) => (m.role ?? '').toLowerCase() == 'paramedic');
  }

  /// A paramedic is on this shift, so the driver waits for the paramedic's handover.
  bool get paramedicOnShift =>
      (shift.value?.crew ?? const <ShiftCrewMember>[]).any(
        (m) => (m.role ?? '').toLowerCase() == 'paramedic',
      );

  /// Shift without a driver: no job can be sent until one joins (M4.2).
  bool get waitingForDriver {
    final crew = shift.value?.crew ?? const <ShiftCrewMember>[];
    return crew.isNotEmpty &&
        !crew.any((m) => (m.role ?? '').toLowerCase() == 'driver');
  }
  bool get hasJob => job.value.hasJob;

  /// Cache only: fast and offline-safe, so the first screen never waits for the network.
  Future<void> restore() async {
    shift.value = await _repo.cachedShift();
    job.value = await _repo.cachedJob();
    medicines.assignAll(await _repo.cachedMedicines());
    if (job.value.jobStatus == JobStatus.sent) alerting.value = true;
  }

  /// Network, live queue and GPS. Runs once the app is unlocked (so the location prompt never
  /// appears over the PIN screen). Safe to call again.
  Future<void> activate() async {
    try {
      final current = await _repo.currentShift();
      if (current == null) {
        if (onShift) {
          await _stop(flushGps: false);
          await _repo.forgetShift();
          shift.value = null;
          job.value = Job.none;
          alerting.value = false;
        }
        return;
      }
      shift.value = current;
      await _repo.rememberShift(current);
      await _begin();
      unawaited(loadMedicines());
    } on Object {
      // A cached shift lets a crew continue safely when the phone is offline.
      if (onShift) await _begin();
    }
  }

  /// [restore] then [activate].
  Future<void> init() async {
    await restore();
    await activate();
  }

  Future<void> _begin() async {
    if (!_started) {
      _started = true;
      _subs
        ..add(_live.events.listen((_) => unawaited(refresh())))
        ..add(_outbox.failures.listen(_onRefused))
        ..add(
          _outbox.completed.listen((d) {
            if (d.item.kind == OutboxKind.status ||
                d.item.kind == OutboxKind.confirm) {
              unawaited(refresh());
            }
            if (d.item.kind == OutboxKind.handover) {
              unawaited(
                _repo.markHandoverSent(d.item).then((_) {
                  patientsTick.value++;
                  return refresh();
                }),
              );
            }
          }),
        );
    }
    _live.start();
    _schedulePoll();
    await _gps.start(onJob: hasJob);
    unawaited(refresh());
  }

  bool _pollingJob = false;

  void _schedulePoll() {
    _pollingJob = hasJob;
    _poll?.cancel();
    _poll = Timer.periodic(
      hasJob ? jobPollEvery : pollEvery,
      (_) => unawaited(refresh()),
    );
  }

  Future<void> loadMedicines() async {
    final list = await _repo.medicines();
    if (list.isNotEmpty) medicines.assignAll(list);
  }

  /// "Job completed" waits for a handover. The server's list on the job counts (any phone);
  /// patients registered on this phone also count once their handover is queued.
  Future<void> refreshHandover() async {
    final j = job.value;
    if (!j.hasJob) {
      handoverMissing.value = false;
      return;
    }
    if (!canHandOver) {
      // The driver with a paramedic on the shift waits until the paramedic's handover arrives.
      handoverMissing.value = j.handovers.isEmpty;
      return;
    }
    final mine = (await _repo.patients()).where((p) => p.caseId == j.caseId);
    if (mine.isEmpty) {
      handoverMissing.value = j.handovers.isEmpty;
      return;
    }
    handoverMissing.value = mine.any(
      (p) => !p.handedOver && j.handoverFor(_repo.patientPathId(p)) == null,
    );
  }

  /// Reloads the shift so a partner who joined from another phone shows up (M4.4).
  Future<void> reloadShift() async {
    try {
      final current = await _repo.currentShift();
      if (current == null) return;
      shift.value = current;
      await _repo.rememberShift(current);
    } on Object {
      // Offline: keep the cached shift.
    }
  }

  Future<void> _stop({bool flushGps = true}) async {
    _poll?.cancel();
    _live.stop();
    await _gps.stop(flushPending: flushGps);
  }

  void _onRefused(OutboxFailure f) {
    final isStatus = f.item.kind == OutboxKind.status;
    if (isStatus && f.error.code == 'HANDOVER_REQUIRED') {
      // Not a toast: take the crew to the handover (or tell the driver to wait for the paramedic).
      _completedLocally = null;
      unawaited(refresh());
      _openHandover();
      return;
    }
    if (f.item.kind == OutboxKind.alert && f.error.code == 'FEATURE_DISABLED') {
      // Switched off by the admin: not an error the crew can fix.
      showToast('alerts_disabled'.tr);
      return;
    }
    if (clinicalOutboxKinds.contains(f.item.kind)) {
      // Mark the timeline line "Not saved" here: this service lives for the whole shift, the
      // patient screens may not even be open.
      unawaited(
        (f.item.kind == OutboxKind.handover
                ? _repo.markHandoverRefused(f.item)
                : _repo.markEntryFailed(f.item, failed: true))
            .then((_) => patientsTick.value++),
      );
    }
    // Refused clinical writes stay in the outbox "Not sent" list; the toast is only a hint.
    showToast(f.error.message(currentLang()));
    if (isStatus || f.item.kind == OutboxKind.confirm) {
      _completedLocally = null;
      unawaited(refresh());
    }
  }

  void _openHandover() {
    try {
      if (canHandOver) {
        unawaited(Get.toNamed<void>(CrewRoutes.handover));
      } else {
        showToast('handover_wait_paramedic'.tr);
      }
    } on Object {
      showToast('handover_required'.tr);
    }
  }

  Future<void> _setJob(Job next) async {
    final prev = job.value;
    if (isNewJob(prev, next) && next.jobStatus == JobStatus.sent) {
      alerting.value = true;
    }
    if (prev.hasJob &&
        !next.hasJob &&
        prev.dispatchId != _completedLocally &&
        prev.jobStatus != JobStatus.completed) {
      cancelledNotice.value = true;
      cancelledUnsent.value = _outbox.pendingClinical;
      alerting.value = false;
    }
    if (!next.hasJob) _completedLocally = null;
    job.value = next;
    unawaited(refreshHandover());
    await _repo.cacheJob(next);
    // Not awaited: a permission dialog must never hold up the next job reads.
    if (onShift) unawaited(_gps.start(onJob: next.hasJob));
    if (hasJob != _pollingJob && _poll != null) _schedulePoll();
    if (isNewJob(prev, next)) unawaited(reloadShift());
  }

  Future<void>? _refreshing;
  bool _again = false;

  /// Re-reads the job. Calls during a read are coalesced into one more read afterwards, so an
  /// event that arrives mid-poll is never lost. Errors are kept for the banner; the cached job stays.
  Future<void> refresh() {
    if (!onShift) return Future.value();
    if (_refreshing != null) {
      _again = true;
      return _refreshing!;
    }
    return _refreshing = _refreshLoop().whenComplete(() => _refreshing = null);
  }

  Future<void> _refreshLoop() async {
    do {
      _again = false;
      await _readOnce();
    } while (_again && onShift);
  }

  Future<void> _readOnce() async {
    loading.value = true;
    try {
      final server = await _repo.fetchJob();
      // Update server-clock offset for accurate countdowns.
      if (server.serverTime != null) {
        serverClockOffset = server.serverTime!.difference(_now());
      }
      final local = job.value;
      final pending = local.hasJob && _repo.hasPendingSteps(local.dispatchId!);
      await _setJob(
        mergeJob(
          local: local,
          server: server,
          pending: pending,
          completedLocally: _completedLocally,
        ),
      );
      error.value = null;
      lastFetched.value = _now().toUtc();
    } on Object catch (e) {
      error.value = ApiError.of(e);
    } finally {
      loading.value = false;
    }
  }

  // ---- Shift ----

  Future<void> startShift(
    String value, {
    bool join = false,
    bool code = false,
  }) async {
    try {
      final started = join
          ? await _repo.joinShift(value, code: code)
          : await _repo.startShift(value, code: code);
      shift.value = started;
      shiftStarted.value = started;
    } on Object catch (e) {
      final error = ApiError.of(e);
      // A shift may have started on another phone between the login check and
      // this request; fetch the authoritative current-shift view.
      if (error.code != 'SHIFT_ALREADY_ACTIVE') rethrow;
      final current = await _repo.currentShift();
      if (current == null) rethrow;
      shift.value = current;
      await _repo.rememberShift(current);
    }
    await _begin();
  }

  /// Throws [ApiError] (`SHIFT_HAS_JOB` when a job is open).
  Future<void> endShift() async {
    await _repo.endShift();
    await _stop();
    shift.value = null;
    job.value = Job.none;
    alerting.value = false;
    shiftStarted.value = null;
  }

  // ---- Job steps (optimistic, queued) ----

  Future<void> confirm() async {
    final j = job.value;
    if (!_canUpdateStatus() || !j.hasJob || j.jobStatus != JobStatus.sent) {
      return;
    }
    if (!await _gps.ensureReady()) {
      showToast('location_required'.tr);
      return;
    }
    alerting.value = false;
    await _setJob(j.withStatus(JobStatus.confirmed));
    await _repo.confirm(j.dispatchId!);
  }

  /// Records the step with the time the button was pressed.
  ///
  /// Ending at the scene needs [noTransportReason]; it is sent only from `on_scene`.
  Future<void> advance(
    JobStatus to, {
    NoTransportReason? noTransportReason,
    String? note,
  }) async {
    final j = job.value;
    final from = j.jobStatus;
    if (!_canUpdateStatus() ||
        !j.hasJob ||
        from == null ||
        !from.canMoveTo(to) ||
        to == JobStatus.confirmed) {
      return;
    }
    final atScene = from == JobStatus.onScene && to == JobStatus.completed;
    if (atScene && noTransportReason == null) return;
    final at = _now().toUtc();
    if (to == JobStatus.completed) {
      _completedLocally = j.dispatchId;
    }
    await _setJob(j.withStatus(to));
    await _repo.setStatus(
      j.dispatchId!,
      to,
      at,
      noTransportReason: atScene ? noTransportReason : null,
      note: atScene ? note : null,
    );
  }

  Future<void> raiseAlert(AlertType type, {String? note}) async {
    final j = job.value;
    if (!j.hasJob) return;
    await _repo.raiseAlert(j.dispatchId!, type, note: note);
  }

  void dismissCancelled() {
    cancelledNotice.value = false;
    cancelledUnsent.value = 0;
  }

  void dismissShiftStarted() => shiftStarted.value = null;

  /// Sign-out / lost phone: stop everything and forget the shift (the cache itself is wiped by core).
  Future<void> wipe() async {
    // SessionService clears the outbox before this hook runs. Do not put a
    // final GPS batch back into it after credentials have been revoked.
    await _stop(flushGps: false);
    await _outbox.clear();
    shift.value = null;
    job.value = Job.none;
    alerting.value = false;
    shiftStarted.value = null;
    cancelledNotice.value = false;
    cancelledUnsent.value = 0;
    medicines.clear();
    _completedLocally = null;
  }

  @override
  void onClose() {
    _poll?.cancel();
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    super.onClose();
  }
}
