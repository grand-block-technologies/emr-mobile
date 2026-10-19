import 'package:dio/dio.dart';

import 'api_error.dart';
import 'apis.dart';

/// Result of trying to get a new access token.
sealed class RefreshOutcome {
  const RefreshOutcome();
}

class Refreshed extends RefreshOutcome {
  const Refreshed(this.accessToken);
  final String accessToken;
}

/// The server refused the refresh token (expired, revoked, device blocked). The session is over.
class RefreshRejected extends RefreshOutcome {
  const RefreshRejected(this.error);
  final ApiError error;
}

/// The server could not be reached. Keep the session: the crew may simply be offline.
class RefreshUnreachable extends RefreshOutcome {
  const RefreshUnreachable();
}

/// What the interceptor needs from the session. An interface breaks the
/// ApiClient ⇄ SessionService cycle and keeps the interceptor unit-testable.
abstract interface class AuthTokenSource {
  String? get accessToken;

  /// Single-flight: concurrent callers share one refresh.
  Future<RefreshOutcome> refreshAccessToken();

  /// The refresh in progress, if any (so a request made meanwhile waits instead of failing 401).
  Future<RefreshOutcome>? get pendingRefresh;

  /// A response that ends or blocks the session (device blocked, update required,
  /// password change required). The session decides what to do.
  void onSessionError(ApiError error);
}

/// 401 codes that a token refresh can fix. Everything else (DEVICE_BLOCKED,
/// DEVICE_INVALID, SESSION_INVALID …) ends the session at once.
const refreshableCodes = {'UNAUTHORIZED', 'SESSION_IDLE'};

/// Codes that the session must react to wherever they appear.
const sessionCodes = {
  'DEVICE_BLOCKED',
  'DEVICE_INVALID',
  'SESSION_INVALID',
  'APP_UPDATE_REQUIRED',
  'PASSWORD_CHANGE_REQUIRED',
  'ACCOUNT_DISABLED',
};

const kRetriedExtra = 'retried';

/// Adds the bearer token and, on 401, refreshes once and replays the request.
///
/// A plain [Interceptor] (not `QueuedInterceptorsWrapper`): a queued `onError` that
/// awaits `dio.fetch` deadlocks if the replay fails too. Concurrency is handled by
/// the single-flight refresh in [AuthTokenSource].
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio, this._source);

  final Dio _dio;
  final AuthTokenSource _source;

  bool _isPublic(RequestOptions o) => o.extra[kPublicExtra] == true;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_source.accessToken == null && !_isPublic(options)) {
      final pending = _source.pendingRefresh;
      if (pending != null) await pending;
    }
    final token = _source.accessToken;
    if (token != null && !_isPublic(options)) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final o = err.requestOptions;
    final status = err.response?.statusCode;
    final apiError = ApiError.of(err);

    if (status == 401 && !_isPublic(o) && o.extra[kRetriedExtra] != true && _isRefreshable(apiError)) {
      final outcome = await _source.refreshAccessToken();
      switch (outcome) {
        case Refreshed(:final accessToken):
          o.headers['Authorization'] = 'Bearer $accessToken';
          o.extra[kRetriedExtra] = true;
          try {
            return handler.resolve(await _dio.fetch<dynamic>(o));
          } on DioException catch (e) {
            _notifyIfSessionError(e);
            return handler.next(e);
          }
        case RefreshRejected(:final error):
          _source.onSessionError(error);
          return handler.next(err);
        case RefreshUnreachable():
          return handler.next(err);
      }
    }

    if (!_isPublic(o) || apiError.code == 'APP_UPDATE_REQUIRED') _notifyIfSessionError(err);
    handler.next(err);
  }

  bool _isRefreshable(ApiError e) => refreshableCodes.contains(e.code) || e.code.startsWith('HTTP_');

  void _notifyIfSessionError(DioException e) {
    final apiError = ApiError.of(e);
    if (sessionCodes.contains(apiError.code)) _source.onSessionError(apiError);
  }
}
