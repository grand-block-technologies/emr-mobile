import 'dart:async';
import 'dart:io';

import 'package:emr_core/emr_core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

/// One phone fix.
class Fix {
  const Fix({
    required this.lat,
    required this.lon,
    required this.at,
    this.accuracyM,
    this.speedMs,
    this.headingDeg,
  });
  final double lat;
  final double lon;
  final DateTime at;
  final double? accuracyM;
  final double? speedMs;
  final double? headingDeg;
}

/// Where fixes come from. Abstract so tests can feed positions.
abstract interface class LocationSource {
  Future<bool> ensurePermission();
  Stream<Fix> fixes({required bool onJob});
}

class GeolocatorSource implements LocationSource {
  @override
  Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  @override
  Stream<Fix> fixes({required bool onJob}) =>
      Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
          accuracy: onJob ? LocationAccuracy.high : LocationAccuracy.medium,
          distanceFilter: 20,
          // Android: keeps sending while the screen is off (foreground service + notification).
          foregroundNotificationConfig: ForegroundNotificationConfig(
            notificationTitle: 'EMR crew',
            notificationText: currentLang() == 'ar'
                ? 'في المناوبة – مشاركة الموقع'
                : 'On shift – sharing location',
            enableWakeLock: true,
          ),
        ),
      ).map(
        (p) => Fix(
          lat: p.latitude,
          lon: p.longitude,
          at: p.timestamp.toUtc(),
          accuracyM: p.accuracy,
          speedMs: p.speed < 0 ? null : p.speed,
          headingDeg: p.heading < 0 ? null : p.heading,
        ),
      );
}

/// Phone GPS while on shift: buffered points sent through the outbox every 15 s on a job
/// and every 60 s when idle (AMD-04). Points are never dropped offline; the outbox merges batches.
class GpsService extends GetxService {
  GpsService({
    required LocationSource source,
    required OutboxService outbox,
    DateTime Function()? now,
  }) : _source = source,
       _outbox = outbox,
       _now = now ?? DateTime.now;

  final LocationSource _source;
  final OutboxService _outbox;
  final DateTime Function() _now;
  static const _uuid = Uuid();

  static const onJobEvery = Duration(seconds: 15);
  static const idleEvery = Duration(seconds: 60);
  static const maxAccuracyM = 100.0;
  static const maxFutureFix = Duration(minutes: 5);

  final last = Rxn<Fix>();
  final permitted = true.obs;
  final _buffer = <Map<String, dynamic>>[];
  StreamSubscription<Fix>? _sub;
  Timer? _timer;
  bool? _onJob;

  bool get running => _sub != null;

  /// Checks the service and permission again immediately before job confirmation.
  /// This catches a location switch turned off after the shift began.
  Future<bool> ensureReady() async {
    permitted.value = await _source.ensurePermission();
    // Android 13+ suppresses foreground-service notifications until this
    // runtime permission is granted. Ask as tracking begins, after the user
    // has already accepted the related location prompt.
    if (Platform.isAndroid &&
        permitted.value &&
        await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    return permitted.value;
  }

  /// Starts or switches cadence and provider power mode. Calling again with the
  /// same mode is a no-op.
  Future<void> start({required bool onJob}) async {
    if (running && _onJob == onJob) return;
    _onJob = onJob;
    if (!await ensureReady()) return;
    await _sub?.cancel();
    _sub = _source.fixes(onJob: onJob).listen(_add, onError: (Object _) {});
    _timer?.cancel();
    _timer = Timer.periodic(
      onJob ? onJobEvery : idleEvery,
      (_) => unawaited(flush()),
    );
  }

  void _add(Fix f) {
    if ((f.accuracyM ?? 0) > maxAccuracyM) return;
    if (f.at.toUtc().isAfter(_now().toUtc().add(maxFutureFix))) return;
    last.value = f;
    _buffer.add({
      'clientPointId': _uuid.v4(),
      'recordedAt': isoUtc(f.at),
      'lon': f.lon,
      'lat': f.lat,
      if (f.accuracyM != null)
        'accuracyM': double.parse(f.accuracyM!.toStringAsFixed(1)),
      if (f.speedMs != null)
        'speedKmh': double.parse((f.speedMs! * 3.6).toStringAsFixed(1)),
      if (f.headingDeg != null)
        'headingDeg': double.parse(f.headingDeg!.toStringAsFixed(0)),
    });
  }

  /// Moves buffered points into the outbox.
  Future<void> flush() async {
    if (_buffer.isEmpty) return;
    final batch = List<Map<String, dynamic>>.of(_buffer);
    _buffer.clear();
    await _outbox.addGps(batch);
  }

  /// Stops collection. Normal shift changes preserve a final buffered batch;
  /// sign-out must discard it because the session is no longer authorised.
  Future<void> stop({bool flushPending = true}) async {
    _timer?.cancel();
    _timer = null;
    await _sub?.cancel();
    _sub = null;
    _onJob = null;
    if (flushPending) {
      await flush();
    } else {
      _buffer.clear();
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    unawaited(_sub?.cancel());
    super.onClose();
  }
}
