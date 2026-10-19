import 'dart:async';

import 'package:emr_core/emr_core.dart';
import 'package:get/get.dart';

import '../../app/citizen_routes.dart';
import '../../data/citizen_repository.dart';
import '../../services/sos_locator.dart';

enum SosPhase { idle, locating, sending, failed }

/// The red button. One idempotency key per press, kept across its retries, so a flaky network
/// can never create two requests. When it cannot get through, the user is offered 999.
class SosController extends GetxController {
  SosController({
    required CitizenRepository repo,
    required SosLocator locator,
    required ConnectivityService net,
    this.retryDelays = const [Duration(seconds: 2), Duration(seconds: 4), Duration(seconds: 8)],
    void Function(RequestArgs args)? openRequest,
  })  : _repo = repo,
        _locator = locator,
        _net = net,
        _open = openRequest ?? ((a) => unawaited(Get.toNamed<void>(CitizenRoutes.request, arguments: a)));

  final CitizenRepository _repo;
  final SosLocator _locator;
  final ConnectivityService _net;
  final List<Duration> retryDelays;
  final void Function(RequestArgs args) _open;

  final phase = SosPhase.idle.obs;
  final error = Rxn<ApiError>();
  final offerCall999 = false.obs;
  final locationProblem = Rxn<LocateFailure>();
  final staleFix = false.obs;

  /// Key of the press in progress; reused on every retry of that press.
  String? _key;
  SosBody? _body;

  bool get busy => phase.value == SosPhase.locating || phase.value == SosPhase.sending;

  Future<void> send({String? note}) async {
    if (busy) return;
    error.value = null;
    locationProblem.value = null;
    offerCall999.value = !_net.online.value;
    if (note != null && note.length > 2000) {
      error.value = ApiError(status: 400, code: 'NOTE_TOO_LONG', ar: 'v_too_long'.tr, en: 'v_too_long'.tr);
      return;
    }

    // A new press after a failure keeps the same request if the location was already taken:
    // the server may have received the first try.
    if (_body == null) {
      phase.value = SosPhase.locating;
      final (fix, failure) = await _locator.locate(timeout: const Duration(seconds: 15));
      if (fix == null) {
        locationProblem.value = failure ?? LocateFailure.none;
        offerCall999.value = true;
        phase.value = SosPhase.failed;
        return;
      }
      staleFix.value = fix.stale;
      final trimmed = note?.trim();
      _body = SosBody(lon: fix.lon, lat: fix.lat, accuracyM: fix.accuracyM?.clamp(0, 100000).toDouble(), note: (trimmed?.isEmpty ?? true) ? null : trimmed);
      _key = IdempotencyKey.create();
    }

    phase.value = SosPhase.sending;
    for (var attempt = 0; attempt <= retryDelays.length; attempt++) {
      SosCreated? created;
      try {
        created = await _repo.sos(_body!, _key!);
      } on Object catch (e) {
        final err = ApiError.of(e);
        if (!err.isRetryable || err.status == 429) {
          await _onRefused(err);
          return;
        }
        if (attempt < retryDelays.length) await Future<void>.delayed(retryDelays[attempt]);
        continue;
      }
      // Navigation stays outside the try: a UI problem must never look like a failed SOS.
      _reset();
      phase.value = SosPhase.idle;
      _open(RequestArgs(created.id, justSent: true));
      return;
    }
    // Could not get through: keep the key for the next press, and offer the phone call.
    error.value = ApiError.network;
    offerCall999.value = true;
    phase.value = SosPhase.failed;
  }

  Future<void> _onRefused(ApiError err) async {
    phase.value = SosPhase.failed;
    switch (err.code) {
      case 'CITIZEN_OPEN_REQUESTS':
        _reset();
        phase.value = SosPhase.idle;
        final open = await _repo.latestOpen().catchError((Object _) => null);
        if (open != null) {
          _open(RequestArgs(open.id));
          return;
        }
        error.value = err;
      case 'CITIZEN_SUSPENDED':
        _reset();
        error.value = err;
        offerCall999.value = true;
      default:
        _reset();
        error.value = err;
        offerCall999.value = err.isRetryable;
    }
  }

  void _reset() {
    _key = null;
    _body = null;
  }

  /// The idempotency key of the press in progress (exposed for tests and support).
  String? get pendingKey => _key;
}

/// Arguments for the request screen.
class RequestArgs {
  const RequestArgs(this.id, {this.justSent = false});
  final String id;

  /// Show "keep your phone free, the call centre will call you".
  final bool justSent;
}
