import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'apis.dart';
import 'auth_interceptor.dart';

/// One Dio for every call, so the outbox and Retrofit share the token and refresh logic.
class ApiClient {
  ApiClient({
    required AppConfig config,
    required AuthTokenSource tokens,
    HttpClientAdapter? adapter,
  }) : dio = Dio(
         BaseOptions(
           baseUrl: config.apiBaseUrl,
           connectTimeout: const Duration(seconds: 10),
           receiveTimeout: const Duration(seconds: 20),
           sendTimeout: const Duration(seconds: 20),
           contentType: Headers.jsonContentType,
           responseType: ResponseType.json,
         ),
       ) {
    if (adapter != null) dio.httpClientAdapter = adapter;
    dio.interceptors.add(AuthInterceptor(dio, tokens));
    if (kDebugMode) dio.interceptors.add(_DebugLogInterceptor());
    auth = AuthApi(dio);
    crew = CrewApi(dio);
    citizen = CitizenApi(dio);
  }

  final Dio dio;
  late final AuthApi auth;
  late final CrewApi crew;
  late final CitizenApi citizen;
}

/// Logs API requests, responses, and errors in the debug console during development.
class _DebugLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[api] ${options.method} ${options.path}');
    final body = _formatBody(options.data);
    if (body.isNotEmpty) {
      debugPrint('[api] request:\n$body');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    debugPrint(
      '[api] ${response.requestOptions.method} ${response.requestOptions.path} → ${response.statusCode}',
    );
    final body = _formatBody(response.data);
    if (body.isNotEmpty) {
      debugPrint('[api] response:\n$body');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '[api] ${err.requestOptions.method} ${err.requestOptions.path} ✗ ${err.response?.statusCode ?? err.type.name}',
    );
    final body = _formatBody(err.response?.data);
    if (body.isNotEmpty) {
      debugPrint('[api] error response:\n$body');
    }
    handler.next(err);
  }

  String _formatBody(Object? data) {
    if (data == null) return '';
    if (data is Uint8List) {
      return '<binary ${data.length} bytes>';
    }
    if (data is List<int> && data.length > 50) {
      return '<binary ${data.length} bytes>';
    }
    try {
      if (data is Map || data is List) {
        return const JsonEncoder.withIndent('  ').convert(data);
      }
      if (data is String) {
        final trimmed = data.trim();
        if (trimmed.isEmpty) return '';
        try {
          final decoded = jsonDecode(trimmed);
          return const JsonEncoder.withIndent('  ').convert(decoded);
        } catch (_) {
          return trimmed;
        }
      }
    } catch (_) {}
    return data.toString();
  }
}
