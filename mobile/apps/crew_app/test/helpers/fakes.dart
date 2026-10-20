import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crew_app/services/gps_service.dart';
import 'package:crew_app/services/live_service.dart';
import 'package:dio/dio.dart';

/// Canned reply; `status == null` is a transport failure (offline).
class FakeReply {
  const FakeReply(this.status, [this.body]);
  const FakeReply.offline() : status = null, body = null;
  final int? status;
  final Object? body;
}

typedef FakeHandler =
    FutureOr<FakeReply> Function(RequestOptions o, Object? body);

/// Route-based fake HTTP adapter (same idea as the core test helper).
class FakeAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final bodies = <Object?>[];
  final _routes = <String, List<FakeHandler>>{};
  FakeHandler? fallback;
  bool offlineAll = false;

  void on(String route, FakeHandler h) => (_routes[route] ??= []).add(h);
  void reply(String route, int status, [Object? body]) =>
      on(route, (_, _) => FakeReply(status, body));

  /// Replaces whatever is queued for [route] (the server state changed).
  void set(String route, int status, [Object? body]) {
    _routes.remove(route);
    reply(route, status, body);
  }

  /// Replaces whatever is queued for [route] with a transport failure.
  void setOffline(String route) {
    _routes.remove(route);
    on(route, (_, _) => const FakeReply.offline());
  }

  List<RequestOptions> calls(String route) =>
      requests.where((r) => '${r.method} ${r.uri.path}' == route).toList();
  List<Object?> bodiesOf(String route) => [
    for (var i = 0; i < requests.length; i++)
      if ('${requests[i].method} ${requests[i].uri.path}' == route) bodies[i],
  ];

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    if (offlineAll) {
      throw DioException.connectionError(
        requestOptions: o,
        reason: 'offline (fake)',
      );
    }
    requests.add(o);
    Object? body;
    if (stream != null) {
      final bytes = await stream.fold<List<int>>(
        <int>[],
        (a, b) => a..addAll(b),
      );
      if (bytes.isNotEmpty) {
        body = jsonDecode(utf8.decode(bytes));
      }
    }
    bodies.add(body);
    final q = _routes['${o.method} ${o.uri.path}'];
    final h = q == null || q.isEmpty
        ? fallback
        : (q.length > 1 ? q.removeAt(0) : q.first);
    if (h == null) {
      return ResponseBody.fromString(
        jsonEncode(err('NOT_FOUND')),
        404,
        headers: _json,
      );
    }
    final r = await h(o, body);
    if (r.status == null) {
      throw DioException.connectionError(
        requestOptions: o,
        reason: 'offline (fake)',
      );
    }
    return ResponseBody.fromString(
      r.body == null ? '' : jsonEncode(r.body),
      r.status!,
      headers: _json,
    );
  }

  static const _json = {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  };

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> err(
  String code, {
  String ar = 'خطأ',
  String en = 'Error',
}) => {
  'code': code,
  'message_ar': ar,
  'message_en': en,
  'reference': 'ref',
  'time': '2026-10-15T07:00:00Z',
};

class FakeLocation implements LocationSource {
  FakeLocation({this.allowed = true});
  bool allowed;
  final ctrl = StreamController<Fix>.broadcast();

  @override
  Future<bool> ensurePermission() async => allowed;

  @override
  Stream<Fix> fixes({required bool onJob}) => ctrl.stream;

  void emit(
    double lat,
    double lon,
    DateTime at, {
    double? accuracyM = 5,
    double? speedMs = 10,
    double? headingDeg = 90,
  }) => ctrl.add(
    Fix(
      lat: lat,
      lon: lon,
      at: at,
      accuracyM: accuracyM,
      speedMs: speedMs,
      headingDeg: headingDeg,
    ),
  );
}

/// Records connections and lets the test push frames/errors.
class FakeStomp implements StompConnector {
  final tokens = <String>[];
  int closed = 0;
  void Function()? _onConnected;
  void Function(String?)? _onEvent;
  void Function(String?)? _onError;
  void Function()? _onClosed;

  @override
  void Function() connect({
    required String url,
    required String token,
    required void Function() onConnected,
    required void Function(String? body) onEvent,
    required void Function(String? message) onError,
    required void Function() onClosed,
  }) {
    tokens.add(token);
    _onConnected = onConnected;
    _onEvent = onEvent;
    _onError = onError;
    _onClosed = onClosed;
    return () => closed++;
  }

  void connected() => _onConnected?.call();
  void event(Map<String, Object?> e) => _onEvent?.call(jsonEncode(e));
  void raw(String? body) => _onEvent?.call(body);
  void error(String message) => _onError?.call(message);
  void drop() => _onClosed?.call();
}

/// The live job payload recorded from the backend.
const liveJob = {
  'dispatchId': 'd-1',
  'caseId': 'c-1',
  'status': 'sent',
  'caseNumber': 'KH-2026-000003',
  'priority': 'P2',
  'complaint': 'Motorbike accident, leg injury',
  'directions': 'Behind the market',
  'lon': 32.556,
  'lat': 15.581,
  'pinRadiusM': 300,
  'landmarkAr': 'قرب المسجد الكبير',
  'landmarkEn': 'Near the big mosque',
  'destinationHospitalId': 'h-1',
  'hospitalAr': 'مستشفى الرياض',
  'hospitalEn': 'Riyadh Hospital',
};

Map<String, Object?> jobWith(String status, {String id = 'd-1'}) => {
  ...liveJob,
  'status': status,
  'dispatchId': id,
};
