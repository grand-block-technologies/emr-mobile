import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

/// A position good enough to send an ambulance.
class SosFix {
  const SosFix({required this.lat, required this.lon, this.accuracyM, this.stale = false});
  final double lat;
  final double lon;
  final double? accuracyM;

  /// True when it came from the last known position, not a fresh fix.
  final bool stale;
}

enum LocateFailure { serviceOff, denied, none }

/// Gets the best fix quickly. Abstract so tests can feed positions.
abstract interface class SosLocator {
  /// Fresh high-accuracy fix within [timeout], else the last known position, else a failure.
  Future<(SosFix?, LocateFailure?)> locate({Duration timeout});
}

class GeolocatorSosLocator implements SosLocator {
  @override
  Future<(SosFix?, LocateFailure?)> locate({Duration timeout = const Duration(seconds: 15)}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      final last = await Geolocator.getLastKnownPosition();
      return last == null ? (null, LocateFailure.serviceOff) : (_fix(last, stale: true), null);
    }
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return (null, LocateFailure.denied);
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high, timeLimit: timeout),
      );
      return (_fix(pos), null);
    } on Object {
      final last = await Geolocator.getLastKnownPosition();
      return last == null ? (null, LocateFailure.none) : (_fix(last, stale: true), null);
    }
  }

  static SosFix _fix(Position p, {bool stale = false}) =>
      SosFix(lat: p.latitude, lon: p.longitude, accuracyM: p.accuracy, stale: stale);
}

/// Opens the dialler. Returns false when the phone cannot place calls.
Future<bool> callNumber(String number) => launchUrl(Uri(scheme: 'tel', path: number));
