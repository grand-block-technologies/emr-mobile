import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A canned reply. `status == null` simulates a transport failure (offline).
class FakeReply {
  const FakeReply(this.status, [this.body]);
  const FakeReply.offline()
      : status = null,
        body = null;

  final int? status;
  final Object? body;
}

typedef FakeHandler = FutureOr<FakeReply> Function(RequestOptions o, Object? body);

/// In-memory HTTP adapter: routes by "METHOD /path", records every request.
class FakeAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final bodies = <Object?>[];
  final _routes = <String, List<FakeHandler>>{};
  FakeHandler? fallback;

  /// Queue replies for a route; the last one repeats once the queue is drained.
  void on(String route, FakeHandler handler) => (_routes[route] ??= []).add(handler);
  void reply(String route, int status, [Object? body]) => on(route, (_, _) => FakeReply(status, body));
  /// Replaces whatever is queued for [route] (the server state changed).
  void set(String route, int status, [Object? body]) {
    _routes.remove(route);
    reply(route, status, body);
  }

  void offline(String route) => on(route, (_, _) => const FakeReply.offline());

  List<RequestOptions> calls(String route) =>
      requests.where((r) => '${r.method} ${r.uri.path}' == route).toList();

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    Object? body;
    if (requestStream != null) {
      final bytes = await requestStream.fold<List<int>>(<int>[], (a, b) => a..addAll(b));
      if (bytes.isNotEmpty) {
        final text = utf8.decode(bytes);
        try {
          body = jsonDecode(text);
        } on FormatException {
          body = text;
        }
      }
    }
    bodies.add(body);
    final key = '${options.method} ${options.uri.path}';
    final queue = _routes[key];
    final handler = queue == null || queue.isEmpty ? fallback : (queue.length > 1 ? queue.removeAt(0) : queue.first);
    if (handler == null) {
      return ResponseBody.fromString(jsonEncode(errorBody('NOT_FOUND')), 404, headers: _json);
    }
    final r = await handler(options, body);
    if (r.status == null) {
      throw DioException.connectionError(requestOptions: options, reason: 'offline (fake)');
    }
    return ResponseBody.fromString(r.body == null ? '' : jsonEncode(r.body), r.status!, headers: _json);
  }

  static const _json = {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  };

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> errorBody(String code, {List<Map<String, String>>? fields, String ar = 'خطأ', String en = 'Error'}) => {
      'code': code,
      'message_ar': ar,
      'message_en': en,
      'reference': 'ref-$code',
      'time': '2026-10-15T07:00:00Z',
      'fieldErrors': ?fields,
    };
