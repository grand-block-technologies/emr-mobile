import 'package:json_annotation/json_annotation.dart';

import 'page.dart';

part 'citizen_models.g.dart';

@JsonSerializable(createFactory: false)
class SignUpStartBody {
  const SignUpStartBody(this.phone);

  final String phone;

  Map<String, dynamic> toJson() => _$SignUpStartBodyToJson(this);
}

@JsonSerializable(createFactory: false, includeIfNull: false)
class SignUpFinishBody {
  const SignUpFinishBody({
    required this.challengeId,
    required this.code,
    required this.nationalId,
    required this.fullNameAr,
    required this.password,
    this.fullNameEn,
  });

  final String challengeId;
  final String code;
  final String nationalId;
  final String fullNameAr;
  final String? fullNameEn;
  final String password;

  Map<String, dynamic> toJson() => _$SignUpFinishBodyToJson(this);
}

@JsonSerializable(createToJson: false)
class SignedUp {
  const SignedUp({this.id, this.identityStatus, this.linkedPatient});

  factory SignedUp.fromJson(Map<String, dynamic> json) => _$SignedUpFromJson(json);

  final String? id;
  final String? identityStatus;
  final bool? linkedPatient;
}

/// `phone_verified`, `id_card_verified` (checked in person at a hospital) or `suspended`.
enum IdentityStatus {
  phoneVerified('phone_verified'),
  idCardVerified('id_card_verified'),
  suspended('suspended'),
  unknown('');

  const IdentityStatus(this.wire);
  final String wire;

  static IdentityStatus fromWire(String? s) =>
      values.firstWhere((v) => v.wire == s, orElse: () => IdentityStatus.unknown);
}

@JsonSerializable()
class CitizenProfile {
  const CitizenProfile({
    this.fullNameAr,
    this.fullNameEn,
    this.phone,
    this.preferredLanguage,
    this.identityStatus,
    this.linkedPatient,
  });

  factory CitizenProfile.fromJson(Map<String, dynamic> json) => _$CitizenProfileFromJson(json);

  final String? fullNameAr;
  final String? fullNameEn;
  final String? phone;
  final String? preferredLanguage;
  final String? identityStatus;
  final bool? linkedPatient;

  IdentityStatus get identity => IdentityStatus.fromWire(identityStatus);

  String displayName(String lang) => (lang == 'en' ? fullNameEn : fullNameAr) ?? fullNameAr ?? fullNameEn ?? '';

  Map<String, dynamic> toJson() => _$CitizenProfileToJson(this);
}

@JsonSerializable(includeIfNull: false)
class SosBody {
  const SosBody({required this.lon, required this.lat, this.accuracyM, this.note});

  factory SosBody.fromJson(Map<String, dynamic> json) => _$SosBodyFromJson(json);

  final double lon;
  final double lat;
  final double? accuracyM;
  final String? note;

  Map<String, dynamic> toJson() => _$SosBodyToJson(this);
}

@JsonSerializable(createToJson: false)
class SosCreated {
  const SosCreated({required this.id, this.statusCode});

  factory SosCreated.fromJson(Map<String, dynamic> json) => _$SosCreatedFromJson(json);

  final String id;
  final String? statusCode;
}

/// Citizen-facing request status codes, in the order a request moves through them.
enum RequestStatusCode {
  received('received'),
  findingHospital('finding_hospital'),
  hospitalAccepted('hospital_accepted'),
  ambulanceComing('ambulance_coming'),
  ambulanceArrived('ambulance_arrived'),
  toHospital('to_hospital'),
  closed('closed'),
  unknown('');

  const RequestStatusCode(this.wire);
  final String wire;

  static RequestStatusCode fromWire(String? s) =>
      values.firstWhere((v) => v.wire == s, orElse: () => RequestStatusCode.unknown);
}

@JsonSerializable(createToJson: false)
class RequestRow {
  const RequestRow({required this.id, this.startedAt, this.statusCode, this.statusAr, this.statusEn, this.updatedAt});

  factory RequestRow.fromJson(Map<String, dynamic> json) => _$RequestRowFromJson(json);

  final String id;
  final DateTime? startedAt;
  final String? statusCode;
  final String? statusAr;
  final String? statusEn;
  final DateTime? updatedAt;

  RequestStatusCode get code => RequestStatusCode.fromWire(statusCode);
  bool get isOpen => code != RequestStatusCode.closed;
  String status(String lang) => (lang == 'en' ? statusEn : statusAr) ?? statusAr ?? statusEn ?? statusCode ?? '';
}

@JsonSerializable(createToJson: false)
class RequestStatus {
  const RequestStatus({
    this.statusCode,
    this.statusAr,
    this.statusEn,
    this.hospitalNameAr,
    this.hospitalNameEn,
    this.updatedAt,
    this.reachedSteps = const [],
    this.closingReason,
    this.closingReasonAr,
    this.closingReasonEn,
  });

  factory RequestStatus.fromJson(Map<String, dynamic> json) => _$RequestStatusFromJson(json);

  final String? statusCode;
  final String? statusAr;
  final String? statusEn;
  final String? hospitalNameAr;
  final String? hospitalNameEn;
  final DateTime? updatedAt;

  /// The statuses the request really reached, in order.
  @JsonKey(defaultValue: <ReachedStep>[])
  final List<ReachedStep> reachedSteps;

  /// Why the case was closed; null while open or when no case was made.
  final String? closingReason;
  final String? closingReasonAr;
  final String? closingReasonEn;

  String? closing(String lang) =>
      (lang == 'en' ? closingReasonEn : closingReasonAr) ?? closingReasonAr ?? closingReasonEn;

  RequestStatusCode get code => RequestStatusCode.fromWire(statusCode);
  bool get isClosed => code == RequestStatusCode.closed;
  String status(String lang) => (lang == 'en' ? statusEn : statusAr) ?? statusAr ?? statusEn ?? statusCode ?? '';
  String? hospital(String lang) => (lang == 'en' ? hospitalNameEn : hospitalNameAr) ?? hospitalNameAr ?? hospitalNameEn;
}

@JsonSerializable(createToJson: false)
class ReachedStep {
  const ReachedStep({this.code, this.at});

  factory ReachedStep.fromJson(Map<String, dynamic> json) => _$ReachedStepFromJson(json);

  final String? code;
  final DateTime? at;

  RequestStatusCode get status => RequestStatusCode.fromWire(code);
}

enum DependantRelation {
  child('child'),
  legalGuardian('legal_guardian');

  const DependantRelation(this.wire);
  final String wire;
}

@JsonSerializable(createFactory: false)
class DependantBody {
  const DependantBody({required this.childNationalId, required this.relation});

  final String childNationalId;
  final String relation;

  Map<String, dynamic> toJson() => _$DependantBodyToJson(this);
}

@JsonSerializable(createToJson: false)
class DependantLink {
  const DependantLink({this.id, this.status});

  factory DependantLink.fromJson(Map<String, dynamic> json) => _$DependantLinkFromJson(json);

  final String? id;
  final String? status;
}

/// `GET /citizen/history`: `{patientId, visits, diagnoses, checkResults, conditions}`, each a page
/// with `content`. An older answer that is one page itself is read as the visits.
class CitizenHistory {
  const CitizenHistory({
    this.patientId,
    this.visits = const ApiPage(content: []),
    this.diagnoses = const ApiPage(content: []),
    this.checkResults = const ApiPage(content: []),
    this.conditions = const ApiPage(content: []),
  });

  factory CitizenHistory.fromJson(Map<String, dynamic> json) {
    ApiPage<HistoryRow> page(Object? v) =>
        v is Map ? ApiPage<HistoryRow>.fromJson(Map<String, dynamic>.from(v), HistoryRow.fromJson) : const ApiPage(content: []);
    if (json['content'] is List && json['visits'] == null) {
      return CitizenHistory(patientId: json['patientId'] as String?, visits: page(json));
    }
    return CitizenHistory(
      patientId: json['patientId'] as String?,
      visits: page(json['visits']),
      diagnoses: page(json['diagnoses']),
      checkResults: page(json['checkResults']),
      conditions: page(json['conditions']),
    );
  }

  final String? patientId;
  final ApiPage<HistoryRow> visits;
  final ApiPage<HistoryRow> diagnoses;
  final ApiPage<HistoryRow> checkResults;
  final ApiPage<HistoryRow> conditions;

  bool get isEmpty =>
      visits.content.isEmpty && diagnoses.content.isEmpty && checkResults.content.isEmpty && conditions.content.isEmpty;
  bool get hasNext => visits.hasNext || diagnoses.hasNext || checkResults.hasNext || conditions.hasNext;
}

/// History rows have no published schema yet, so keep the raw map and read known keys defensively.
class HistoryRow {
  const HistoryRow(this.raw);

  factory HistoryRow.fromJson(Object? json) =>
      HistoryRow(json is Map ? Map<String, dynamic>.from(json) : const <String, dynamic>{});

  final Map<String, dynamic> raw;

  String? _s(List<String> keys) {
    for (final k in keys) {
      final v = raw[k];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }

  DateTime? get at => DateTime.tryParse(_s(['startedAt', 'occurredAt', 'createdAt', 'date', 'at']) ?? '');
  String? title(String lang) => lang == 'en'
      ? _s(['titleEn', 'kindEn', 'labelEn', 'diagnosisEn', 'title', 'kind', 'caseNumber'])
      : _s(['titleAr', 'kindAr', 'labelAr', 'diagnosisAr', 'title', 'kind', 'caseNumber']);
  String? subtitle(String lang) => lang == 'en'
      ? _s(['hospitalNameEn', 'hospitalEn', 'summaryEn', 'outcome'])
      : _s(['hospitalNameAr', 'hospitalAr', 'summaryAr', 'outcome']);
}
