// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$LoginBodyToJson(LoginBody instance) => <String, dynamic>{
  'username': instance.username,
  'password': instance.password,
  'deviceType': instance.deviceType,
  'clientApp': instance.clientApp,
  'deviceId': instance.deviceId,
  'appVersion': instance.appVersion,
};

LoginResult _$LoginResultFromJson(Map<String, dynamic> json) => LoginResult(
  step: json['step'] as String?,
  challengeId: json['challengeId'] as String?,
  expiresAt: json['expiresAt'] == null
      ? null
      : DateTime.parse(json['expiresAt'] as String),
  accessToken: json['accessToken'] as String?,
  refreshToken: json['refreshToken'] as String?,
  mustChangePassword: json['mustChangePassword'] as bool?,
);

Challenge _$ChallengeFromJson(Map<String, dynamic> json) => Challenge(
  challengeId: json['challengeId'] as String?,
  expiresAt: json['expiresAt'] == null
      ? null
      : DateTime.parse(json['expiresAt'] as String),
);

Map<String, dynamic> _$VerifyBodyToJson(VerifyBody instance) =>
    <String, dynamic>{
      'challengeId': instance.challengeId,
      'code': instance.code,
    };

LoginTokens _$LoginTokensFromJson(Map<String, dynamic> json) => LoginTokens(
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String?,
  mustChangePassword: json['mustChangePassword'] as bool? ?? false,
);

Map<String, dynamic> _$RefreshBodyToJson(RefreshBody instance) =>
    <String, dynamic>{'refreshToken': instance.refreshToken};

AccessToken _$AccessTokenFromJson(Map<String, dynamic> json) =>
    AccessToken(json['accessToken'] as String?);

Map<String, dynamic> _$ChangePasswordBodyToJson(ChangePasswordBody instance) =>
    <String, dynamic>{
      'oldPassword': instance.oldPassword,
      'newPassword': instance.newPassword,
    };

Map<String, dynamic> _$ForgotBodyToJson(ForgotBody instance) =>
    <String, dynamic>{
      'username': instance.username,
      'clientApp': ?instance.clientApp,
    };

ResetRequested _$ResetRequestedFromJson(Map<String, dynamic> json) =>
    ResetRequested(
      challengeId: json['challengeId'] as String?,
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      messageAr: json['message_ar'] as String?,
      messageEn: json['message_en'] as String?,
    );

Map<String, dynamic> _$ResetBodyToJson(ResetBody instance) => <String, dynamic>{
  'challengeId': instance.challengeId,
  'code': instance.code,
  'newPassword': instance.newPassword,
};

Scope _$ScopeFromJson(Map<String, dynamic> json) => Scope(
  type: json['type'] as String?,
  stateId: json['stateId'] as String?,
  hospitalId: json['hospitalId'] as String?,
);

Map<String, dynamic> _$ScopeToJson(Scope instance) => <String, dynamic>{
  'type': instance.type,
  'stateId': instance.stateId,
  'hospitalId': instance.hospitalId,
};

Me _$MeFromJson(Map<String, dynamic> json) => Me(
  id: json['id'] as String,
  username: json['username'] as String,
  fullNameAr: json['fullNameAr'] as String?,
  fullNameEn: json['fullNameEn'] as String?,
  role: json['role'] as String?,
  preferredLanguage: json['preferredLanguage'] as String?,
  scopes:
      (json['scopes'] as List<dynamic>?)
          ?.map((e) => Scope.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  stateCodes:
      (json['stateCodes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  mustChangePassword: json['mustChangePassword'] as bool? ?? false,
  features:
      (json['features'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
);

Map<String, dynamic> _$MeToJson(Me instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'fullNameAr': instance.fullNameAr,
  'fullNameEn': instance.fullNameEn,
  'role': instance.role,
  'preferredLanguage': instance.preferredLanguage,
  'scopes': instance.scopes.map((e) => e.toJson()).toList(),
  'stateCodes': instance.stateCodes,
  'mustChangePassword': instance.mustChangePassword,
  'features': instance.features,
};

Map<String, dynamic> _$PushTokenBodyToJson(PushTokenBody instance) =>
    <String, dynamic>{'pushToken': instance.pushToken};
