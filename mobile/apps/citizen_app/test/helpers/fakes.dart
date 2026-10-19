import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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
      if (bytes.isNotEmpty) body = jsonDecode(utf8.decode(bytes));
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
