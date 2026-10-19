import 'package:dio/dio.dart';
import 'package:emr_core/emr_core.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _dioError(int? status, Object? data) {
  final o = RequestOptions(path: '/x');
  return DioException(
    requestOptions: o,
    response: status == null ? null : Response<dynamic>(requestOptions: o, statusCode: status, data: data),
    type: status == null ? DioExceptionType.connectionError : DioExceptionType.badResponse,
  );
}

void main() {
  group('ApiError.of', () {
    test('parses the bilingual body and field errors', () {
      final e = ApiError.of(_dioError(400, {
        'code': 'VALIDATION_ERROR',
        'message_ar': 'قيم غير صالحة',
        'message_en': 'Invalid values',
        'reference': 'abc',
        'time': '2026-10-15T07:20:01Z',
        'fieldErrors': [
          {'field': 'lat', 'code': 'REQUIRED', 'message_ar': 'مطلوب', 'message_en': 'Required'},
        ],
      }));

      expect(e.status, 400);
      expect(e.code, 'VALIDATION_ERROR');
      expect(e.message('ar'), 'قيم غير صالحة');
      expect(e.message('en'), 'Invalid values');
      expect(e.reference, 'abc');
      expect(e.fieldMessage('lat', 'en'), 'Required');
      expect(e.fieldMessage('lat', 'ar'), 'مطلوب');
      expect(e.fieldMessage('lon', 'en'), isNull);
      expect(e.isRetryable, isFalse);
    });

    test('no response is a retryable NETWORK error', () {
      final e = ApiError.of(_dioError(null, null));
      expect(e.code, 'NETWORK');
      expect(e.isNetwork, isTrue);
      expect(e.isRetryable, isTrue);
    });

    test('a non-JSON 502 becomes an unexpected, retryable error', () {
      final e = ApiError.of(_dioError(502, '<html>bad gateway</html>'));
      expect(e.status, 502);
      expect(e.code, 'HTTP_502');
      expect(e.isRetryable, isTrue);
      expect(e.isUnexpected, isTrue);
    });

    test('429 is retryable, 409 is not', () {
      expect(ApiError.of(_dioError(429, {'code': 'AUTH_RATE_LIMIT', 'message_ar': 'a', 'message_en': 'b'})).isRetryable, isTrue);
      expect(ApiError.of(_dioError(409, {'code': 'IDEMPOTENCY_CONFLICT', 'message_ar': 'a', 'message_en': 'b'})).isRetryable, isFalse);
    });

    test('falls back to the other language when one is missing', () {
      final e = ApiError.of(_dioError(400, {'code': 'X', 'message_en': 'Only English'}));
      expect(e.message('ar'), 'Only English');
    });

    test('passes an ApiError through and maps unknown objects to UNEXPECTED', () {
      expect(ApiError.of(ApiError.network), same(ApiError.network));
      expect(ApiError.of(StateError('boom')).code, 'UNEXPECTED');
    });
  });

  group('IdempotencyKey', () {
    test('creates keys that satisfy the server rule', () {
      final k = IdempotencyKey.create();
      expect(IdempotencyKey.isValid(k), isTrue);
      expect(IdempotencyKey.create(), isNot(k));
    });

    test('rejects keys with spaces or longer than 128', () {
      expect(IdempotencyKey.isValid('has space'), isFalse);
      expect(IdempotencyKey.isValid('a' * 129), isFalse);
      expect(IdempotencyKey.isValid('ok.key:1-2_3'), isTrue);
    });
  });
}
