import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

@JsonSerializable(createFactory: false, includeIfNull: false)
class LoginBody {
  const LoginBody({
    required this.username,
    required this.password,
    required this.clientApp,
    required this.deviceId,
    required this.appVersion,
    this.deviceType = 'mobile',
  });

  final String username;
  final String password;
  final String deviceType;
  final String clientApp;
  final String deviceId;
  final String appVersion;

  Map<String, dynamic> toJson() => _$LoginBodyToJson(this);
}

/// `step` is `sms_code` (send the code to /auth/verify) or `signed_in` (tokens already set).
@JsonSerializable(createToJson: false)
class LoginResult {
  const LoginResult({this.step, this.challengeId, this.expiresAt, this.accessToken, this.refreshToken, this.mustChangePassword});

  factory LoginResult.fromJson(Map<String, dynamic> json) => _$LoginResultFromJson(json);

  final String? step;
  final String? challengeId;
  final DateTime? expiresAt;
  final String? accessToken;
  final String? refreshToken;
  final bool? mustChangePassword;

  bool get signedIn => step == 'signed_in' && accessToken != null;

  LoginTokens? get tokens => signedIn
      ? LoginTokens(accessToken: accessToken!, refreshToken: refreshToken, mustChangePassword: mustChangePassword ?? false)
      : null;
}

@JsonSerializable(createToJson: false)
class Challenge {
  const Challenge({this.challengeId, this.expiresAt});

  factory Challenge.fromJson(Map<String, dynamic> json) => _$ChallengeFromJson(json);

  final String? challengeId;
  final DateTime? expiresAt;
}

@JsonSerializable(createFactory: false)
class VerifyBody {
  const VerifyBody({required this.challengeId, required this.code});

  final String challengeId;
  final String code;

  Map<String, dynamic> toJson() => _$VerifyBodyToJson(this);
}

@JsonSerializable(createToJson: false)
class LoginTokens {
  const LoginTokens({required this.accessToken, this.refreshToken, this.mustChangePassword = false});

  factory LoginTokens.fromJson(Map<String, dynamic> json) => _$LoginTokensFromJson(json);

  final String accessToken;
  final String? refreshToken;
  @JsonKey(defaultValue: false)
  final bool mustChangePassword;
}

@JsonSerializable(createFactory: false)
class RefreshBody {
  const RefreshBody(this.refreshToken);

  final String refreshToken;

  Map<String, dynamic> toJson() => _$RefreshBodyToJson(this);
}

@JsonSerializable(createToJson: false)
class AccessToken {
  const AccessToken(this.accessToken);

  factory AccessToken.fromJson(Map<String, dynamic> json) => _$AccessTokenFromJson(json);

  final String? accessToken;
}

@JsonSerializable(createFactory: false)
class ChangePasswordBody {
  const ChangePasswordBody({required this.oldPassword, required this.newPassword});

  final String oldPassword;
  final String newPassword;

  Map<String, dynamic> toJson() => _$ChangePasswordBodyToJson(this);
}

@JsonSerializable(createFactory: false, includeIfNull: false)
class ForgotBody {
  const ForgotBody({required this.username, this.clientApp});

  final String username;
  final String? clientApp;

  Map<String, dynamic> toJson() => _$ForgotBodyToJson(this);
}

@JsonSerializable(createToJson: false)
class ResetRequested {
  const ResetRequested({this.challengeId, this.expiresAt, this.messageAr, this.messageEn});

  factory ResetRequested.fromJson(Map<String, dynamic> json) => _$ResetRequestedFromJson(json);

  final String? challengeId;
  final DateTime? expiresAt;
  @JsonKey(name: 'message_ar')
  final String? messageAr;
  @JsonKey(name: 'message_en')
  final String? messageEn;
}

@JsonSerializable(createFactory: false)
class ResetBody {
  const ResetBody({required this.challengeId, required this.code, required this.newPassword});

  final String challengeId;
  final String code;
  final String newPassword;

  Map<String, dynamic> toJson() => _$ResetBodyToJson(this);
}

@JsonSerializable()
class Scope {
  const Scope({this.type, this.stateId, this.hospitalId});

  factory Scope.fromJson(Map<String, dynamic> json) => _$ScopeFromJson(json);

  final String? type;
  final String? stateId;
  final String? hospitalId;

  Map<String, dynamic> toJson() => _$ScopeToJson(this);
}

/// `GET /api/v1/me`. Cached on the device so the crew app can open offline.
@JsonSerializable(explicitToJson: true)
class Me {
  const Me({
    required this.id,
    required this.username,
    this.fullNameAr,
    this.fullNameEn,
    this.role,
    this.preferredLanguage,
    this.scopes = const [],
    this.stateCodes = const [],
    this.mustChangePassword = false,
  });

  factory Me.fromJson(Map<String, dynamic> json) => _$MeFromJson(json);

  final String id;
  final String username;
  final String? fullNameAr;
  final String? fullNameEn;
  final String? role;
  final String? preferredLanguage;
  final List<Scope> scopes;
  final List<String> stateCodes;
  @JsonKey(defaultValue: false)
  final bool mustChangePassword;

  bool get isDriver => role == 'DRIVER';
  bool get isParamedic => role == 'PARAMEDIC';
  bool get isCrew => isDriver || isParamedic;
  bool get isCitizen => role == 'CITIZEN';

  String displayName(String lang) =>
      (lang == 'en' ? fullNameEn : fullNameAr) ?? fullNameAr ?? fullNameEn ?? username;

  Map<String, dynamic> toJson() => _$MeToJson(this);
}

@JsonSerializable(createFactory: false)
class PushTokenBody {
  const PushTokenBody(this.pushToken);

  final String pushToken;

  Map<String, dynamic> toJson() => _$PushTokenBodyToJson(this);
}
