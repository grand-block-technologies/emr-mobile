import 'dart:async';

import 'package:emr_core/emr_core.dart';
import 'package:get/get.dart';

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

  String? _completedLocally;
  Timer? _poll;
  final _subs = <StreamSubscription<Object>>[];
  bool _started = false;

  bool get onShift => shift.value != null;
  bool get hasJob => job.value.hasJob;

  /// Cache only: fast and offline-safe, so the first screen never waits for the network.
  Future<void> restore() async {
    shift.value = await _repo.cachedShift();
    job.value = await _repo.cachedJob();
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
          }),
        );
    }
    _live.start();
    _poll?.cancel();
    _poll = Timer.periodic(pollEvery, (_) => unawaited(refresh()));
    await _gps.start(onJob: hasJob);
    unawaited(refresh());
  }

  Future<void> _stop({bool flushGps = true}) async {
    _poll?.cancel();
    _live.stop();
    await _gps.stop(flushPending: flushGps);
  }

  void _onRefused(OutboxFailure f) {
    showToast(f.error.message(currentLang()));
    if (f.item.kind == OutboxKind.status || f.item.kind == OutboxKind.confirm) {
      _completedLocally = null;
      unawaited(refresh());
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
      alerting.value = false;
    }
    if (!next.hasJob) _completedLocally = null;
    job.value = next;
    await _repo.cacheJob(next);
    if (onShift) await _gps.start(onJob: next.hasJob);
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
  Future<void> advance(JobStatus to) async {
    final j = job.value;
    final from = j.jobStatus;
    if (!_canUpdateStatus() ||
        !j.hasJob ||
        from == null ||
        !from.canMoveTo(to) ||
        to == JobStatus.confirmed) {
      return;
    }
    final at = _now().toUtc();
    if (to == JobStatus.completed) _completedLocally = j.dispatchId;
    await _setJob(j.withStatus(to));
    await _repo.setStatus(j.dispatchId!, to, at);
  }

  Future<void> raiseAlert(AlertType type, {String? note}) async {
    final j = job.value;
    if (!j.hasJob) return;
    await _repo.raiseAlert(j.dispatchId!, type, note: note);
  }

  void dismissCancelled() => cancelledNotice.value = false;

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
