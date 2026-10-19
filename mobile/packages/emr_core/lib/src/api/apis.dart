import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/auth_models.dart';
import '../models/citizen_models.dart';
import '../models/crew_models.dart';
import '../models/page.dart';

part 'apis.g.dart';

/// Marks a call that needs no token: the auth interceptor neither adds one nor retries on 401.
const publicCall = Extra({kPublicExtra: true});
const kPublicExtra = 'public';

@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio, {String? baseUrl}) = _AuthApi;

  @POST('/api/v1/auth/login')
  @publicCall
  Future<LoginResult> login(@Body() LoginBody body);

  @POST('/api/v1/auth/verify')
  @publicCall
  Future<LoginTokens> verify(@Body() VerifyBody body);

  @POST('/api/v1/auth/resend')
  @publicCall
  Future<Challenge> resend(@Body() Map<String, String> body);

  @POST('/api/v1/auth/refresh')
  @publicCall
  Future<AccessToken> refresh(@Body() RefreshBody body);

  @POST('/api/v1/auth/logout')
  Future<void> logout();

  @POST('/api/v1/auth/change-password')
  Future<void> changePassword(@Body() ChangePasswordBody body);

  @POST('/api/v1/auth/forgot-password')
  @publicCall
  Future<ResetRequested> forgot(@Body() ForgotBody body);

  @POST('/api/v1/auth/reset-password')
  @publicCall
  Future<void> reset(@Body() ResetBody body);

  @GET('/api/v1/me')
  Future<Me> me();

  @PUT('/api/v1/devices/current/push-token')
  Future<void> pushToken(@Body() PushTokenBody body);
}

/// Crew reads and non-queued writes. Queued writes (confirm, status, GPS, alerts, patient care)
/// go through the outbox with stored paths; see `CrewPaths`.
@RestApi()
abstract class CrewApi {
  factory CrewApi(Dio dio, {String? baseUrl}) = _CrewApi;

  @PUT('/api/v1/crew/pin')
  Future<void> setPin(@Body() PinBody body);

  @POST('/api/v1/crew/pin/verify')
  Future<void> verifyPin(@Body() PinBody body);

  @POST('/api/v1/crew/shifts')
  Future<Shift> startShift(@Body() QrBody body);

  @POST('/api/v1/crew/shifts/current/join')
  Future<Shift> joinShift(@Body() QrBody body);

  @GET('/api/v1/crew/shifts/current')
  Future<CurrentShift> currentShift();

  @POST('/api/v1/crew/shifts/current/end')
  Future<void> endShift();

  @GET('/api/v1/crew/job')
  Future<Job> job();
}

@RestApi()
abstract class CitizenApi {
  factory CitizenApi(Dio dio, {String? baseUrl}) = _CitizenApi;

  @POST('/api/v1/citizen/sign-up/start')
  @publicCall
  Future<Challenge> signUpStart(@Body() SignUpStartBody body);

  @POST('/api/v1/citizen/sign-up/finish')
  @publicCall
  Future<SignedUp> signUpFinish(@Body() SignUpFinishBody body);

  @GET('/api/v1/citizen/me')
  Future<CitizenProfile> me();

  @POST('/api/v1/citizen/requests')
  Future<SosCreated> sos(
    @Body() SosBody body,
    @Header('Idempotency-Key') String key,
  );

  @GET('/api/v1/citizen/requests')
  Future<ApiPage<RequestRow>> requests(
    @Query('page') int page,
    @Query('size') int size,
  );

  @GET('/api/v1/citizen/requests/{id}')
  Future<RequestStatus> request(@Path('id') String id);

  @POST('/api/v1/citizen/dependants')
  Future<DependantLink> addDependant(@Body() DependantBody body);

  @GET('/api/v1/citizen/history')
  Future<ApiPage<HistoryRow>> history(
    @Query('page') int page,
    @Query('size') int size, {
    @Query('patientId') String? patientId,
  });
}

/// Paths for writes that travel through the outbox (stored as path + JSON on disk).
abstract final class CrewPaths {
  static String confirm(String dispatchId) =>
      '/api/v1/dispatches/$dispatchId/confirm';
  static String status(String dispatchId) =>
      '/api/v1/dispatches/$dispatchId/status';
  static String alerts(String dispatchId) =>
      '/api/v1/dispatches/$dispatchId/alerts';
  static const gps = '/api/v1/crew/gps';
  static const patients = '/api/v1/patients';
  static String observations(String patientId) =>
      '/api/v1/patients/$patientId/observations';
  static String treatments(String patientId) =>
      '/api/v1/patients/$patientId/treatments';
}
