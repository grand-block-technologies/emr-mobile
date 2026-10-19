// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'citizen_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$SignUpStartBodyToJson(SignUpStartBody instance) =>
    <String, dynamic>{'phone': instance.phone};

Map<String, dynamic> _$SignUpFinishBodyToJson(SignUpFinishBody instance) =>
    <String, dynamic>{
      'challengeId': instance.challengeId,
      'code': instance.code,
      'nationalId': instance.nationalId,
      'fullNameAr': instance.fullNameAr,
      'fullNameEn': ?instance.fullNameEn,
      'password': instance.password,
    };

SignedUp _$SignedUpFromJson(Map<String, dynamic> json) => SignedUp(
  id: json['id'] as String?,
  identityStatus: json['identityStatus'] as String?,
  linkedPatient: json['linkedPatient'] as bool?,
);

CitizenProfile _$CitizenProfileFromJson(Map<String, dynamic> json) =>
    CitizenProfile(
      fullNameAr: json['fullNameAr'] as String?,
      fullNameEn: json['fullNameEn'] as String?,
      phone: json['phone'] as String?,
      preferredLanguage: json['preferredLanguage'] as String?,
      identityStatus: json['identityStatus'] as String?,
      linkedPatient: json['linkedPatient'] as bool?,
    );

Map<String, dynamic> _$CitizenProfileToJson(CitizenProfile instance) =>
    <String, dynamic>{
      'fullNameAr': instance.fullNameAr,
      'fullNameEn': instance.fullNameEn,
      'phone': instance.phone,
      'preferredLanguage': instance.preferredLanguage,
      'identityStatus': instance.identityStatus,
      'linkedPatient': instance.linkedPatient,
    };

SosBody _$SosBodyFromJson(Map<String, dynamic> json) => SosBody(
  lon: (json['lon'] as num).toDouble(),
  lat: (json['lat'] as num).toDouble(),
  accuracyM: (json['accuracyM'] as num?)?.toDouble(),
  note: json['note'] as String?,
);

Map<String, dynamic> _$SosBodyToJson(SosBody instance) => <String, dynamic>{
  'lon': instance.lon,
  'lat': instance.lat,
  'accuracyM': ?instance.accuracyM,
  'note': ?instance.note,
};

SosCreated _$SosCreatedFromJson(Map<String, dynamic> json) => SosCreated(
  id: json['id'] as String,
  statusCode: json['statusCode'] as String?,
);

RequestRow _$RequestRowFromJson(Map<String, dynamic> json) => RequestRow(
  id: json['id'] as String,
  startedAt: json['startedAt'] == null
      ? null
      : DateTime.parse(json['startedAt'] as String),
  statusCode: json['statusCode'] as String?,
  statusAr: json['statusAr'] as String?,
  statusEn: json['statusEn'] as String?,
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

RequestStatus _$RequestStatusFromJson(Map<String, dynamic> json) =>
    RequestStatus(
      statusCode: json['statusCode'] as String?,
      statusAr: json['statusAr'] as String?,
      statusEn: json['statusEn'] as String?,
      hospitalNameAr: json['hospitalNameAr'] as String?,
      hospitalNameEn: json['hospitalNameEn'] as String?,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$DependantBodyToJson(DependantBody instance) =>
    <String, dynamic>{
      'childNationalId': instance.childNationalId,
      'relation': instance.relation,
    };

DependantLink _$DependantLinkFromJson(Map<String, dynamic> json) =>
    DependantLink(id: json['id'] as String?, status: json['status'] as String?);
