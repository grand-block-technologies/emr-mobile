import 'package:dio/dio.dart';

/// One rejected input field from `fieldErrors`.
class FieldError {
  const FieldError({required this.field, required this.code, required this.ar, required this.en});

  factory FieldError.fromJson(Map<String, dynamic> j) => FieldError(
        field: j['field'] as String? ?? '',
        code: j['code'] as String? ?? 'INVALID',
        ar: j['message_ar'] as String? ?? '',
        en: j['message_en'] as String? ?? '',
      );

  final String field;
  final String code;
  final String ar;
  final String en;

  String message(String lang) => lang == 'en' ? en : ar;
}

/// The bilingual error body every 4xx/5xx carries, plus a synthetic `NETWORK` error
/// when the server could not be reached at all.
class ApiError implements Exception {
  const ApiError({
    required this.status,
    required this.code,
    required this.ar,
    required this.en,
    this.reference,
    this.fields = const [],
  });

  static const network = ApiError(
    status: 0,
    code: 'NETWORK',
    ar: 'تعذّر الاتصال بالخادم',
    en: 'Cannot reach the server',
  );

  static const unexpected = ApiError(
    status: -1,
    code: 'UNEXPECTED',
    ar: 'حدث خطأ غير متوقع',
    en: 'Something went wrong',
  );

  /// HTTP status; 0 when no response arrived (offline, timeout, DNS).
  final int status;
  final String code;
  final String ar;
  final String en;

  /// Support reference. Show it only on unexpected errors.
  final String? reference;
  final List<FieldError> fields;

  bool get isNetwork => status == 0;

  /// Server-side or transport failure that is worth retrying later with the same request.
  bool get isRetryable => status == 0 || status == 429 || status >= 500;

  /// An error the user cannot fix by changing input; show [reference] with it.
  bool get isUnexpected => status >= 500 || code == 'INTERNAL_ERROR' || status == -1;

  String message(String lang) => lang == 'en' ? en : ar;

  String? fieldMessage(String field, String lang) {
    for (final f in fields) {
      if (f.field == field) return f.message(lang);
    }
    return null;
  }

  /// Converts anything thrown by Dio/Retrofit (or already an [ApiError]) into an [ApiError].
  static ApiError of(Object error) {
    if (error is ApiError) return error;
    if (error is DioException) {
      final res = error.response;
      final data = res?.data;
      if (res != null && data is Map && data['code'] is String) {
        final fields = data['fieldErrors'];
        return ApiError(
          status: res.statusCode ?? -1,
          code: data['code'] as String,
          ar: (data['message_ar'] as String?) ?? (data['message_en'] as String?) ?? '',
          en: (data['message_en'] as String?) ?? (data['message_ar'] as String?) ?? '',
          reference: data['reference'] as String?,
          fields: fields is List
              ? fields.whereType<Map<dynamic, dynamic>>().map((m) => FieldError.fromJson(Map<String, dynamic>.from(m))).toList()
              : const [],
        );
      }
      if (res == null) return network;
      return ApiError(
        status: res.statusCode ?? -1,
        code: 'HTTP_${res.statusCode}',
        ar: unexpected.ar,
        en: unexpected.en,
      );
    }
    return unexpected;
  }

  @override
  String toString() => 'ApiError($status $code${reference == null ? '' : ' ref=$reference'})';
}
