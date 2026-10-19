import 'package:json_annotation/json_annotation.dart';

import 'job_status.dart';

part 'crew_models.g.dart';

@JsonSerializable(createFactory: false, includeIfNull: false)
class PinBody {
  const PinBody({required this.pin, this.oldPin});

  final String pin;
  final String? oldPin;

  Map<String, dynamic> toJson() => _$PinBodyToJson(this);
}

@JsonSerializable(createFactory: false, includeIfNull: false)
class QrBody {
  const QrBody(this.qrToken) : code = null;

  const QrBody.code(this.code) : qrToken = null;

  /// Exactly one of [qrToken] and [code] is sent.
  final String? qrToken;
  final String? code;

  Map<String, dynamic> toJson() => _$QrBodyToJson(this);
}

@JsonSerializable()
class Shift {
  const Shift({
    this.id,
    this.ambulanceId,
    this.plateNumber,
    this.hospitalId,
    this.hospitalNameAr,
    this.hospitalNameEn,
    this.startedAt,
    this.crew = const [],
  });

  factory Shift.fromJson(Map<String, dynamic> json) => _$ShiftFromJson(json);

  final String? id;
  final String? ambulanceId;
  final String? plateNumber;
  final String? hospitalId;
  final String? hospitalNameAr;
  final String? hospitalNameEn;
  final DateTime? startedAt;
  final List<ShiftCrewMember> crew;

  String? hospital(String lang) =>
      (lang == 'en' ? hospitalNameEn : hospitalNameAr) ??
      hospitalNameAr ??
      hospitalNameEn;

  Map<String, dynamic> toJson() => _$ShiftToJson(this);
}

@JsonSerializable()
class ShiftCrewMember {
  const ShiftCrewMember({
    this.userId,
    this.role,
    this.fullNameAr,
    this.fullNameEn,
    this.phone,
    this.joinedAt,
    this.me = false,
  });

  factory ShiftCrewMember.fromJson(Map<String, dynamic> json) =>
      _$ShiftCrewMemberFromJson(json);

  final String? userId;
  final String? role;
  final String? fullNameAr;
  final String? fullNameEn;
  final String? phone;
  final DateTime? joinedAt;
  final bool me;

  String? name(String lang) =>
      (lang == 'en' ? fullNameEn : fullNameAr) ?? fullNameAr ?? fullNameEn;

  Map<String, dynamic> toJson() => _$ShiftCrewMemberToJson(this);
}

/// Envelope returned by `GET /api/v1/crew/shifts/current`.
@JsonSerializable()
class CurrentShift {
  const CurrentShift({this.shift});

  factory CurrentShift.fromJson(Map<String, dynamic> json) =>
      _$CurrentShiftFromJson(json);

  final Shift? shift;
}

/// `GET /api/v1/crew/job` returns `{"job": null}` or the job fields at the top level.
@JsonSerializable()
class Job {
  const Job({
    this.dispatchId,
    this.caseId,
    this.status,
    this.caseNumber,
    this.priority,
    this.complaint,
    this.directions,
    this.lon,
    this.lat,
    this.pinRadiusM,
    this.landmarkAr,
    this.landmarkEn,
    this.destinationHospitalId,
    this.hospitalAr,
    this.hospitalEn,
    this.caseCreatedAt,
    this.sentAt,
    this.confirmDeadlineAt,
    this.confirmedAt,
    this.statusTime,
    this.serverTime,
  });

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);

  static const none = Job();

  final String? dispatchId;
  final String? caseId;
  final String? status;
  final String? caseNumber;
  final String? priority;
  final String? complaint;
  final String? directions;
  final double? lon;
  final double? lat;
  final int? pinRadiusM;
  final String? landmarkAr;
  final String? landmarkEn;
  final String? destinationHospitalId;
  final String? hospitalAr;
  final String? hospitalEn;

  /// When the call centre opened the case (UTC ISO-8601).
  final DateTime? caseCreatedAt;

  /// When the job was dispatched to this ambulance (UTC ISO-8601).
  final DateTime? sentAt;

  /// The crew must confirm before this time (UTC ISO-8601).
  /// Use together with [serverTime] for an accurate countdown.
  final DateTime? confirmDeadlineAt;

  /// When the crew confirmed; null while still [JobStatus.sent].
  final DateTime? confirmedAt;

  /// When the current status started (UTC ISO-8601).
  final DateTime? statusTime;

  /// Server clock at response time. Compute the offset once per poll:
  /// `offset = serverTime − DateTime.now()` then use `DateTime.now() + offset`
  /// as the accurate current time for countdowns.
  final DateTime? serverTime;

  bool get hasJob => dispatchId != null;
  bool get hasLocation => lat != null && lon != null;
  JobStatus? get jobStatus => JobStatus.fromWire(status);

  String? landmark(String lang) =>
      (lang == 'en' ? landmarkEn : landmarkAr) ?? landmarkAr ?? landmarkEn;
  String? hospital(String lang) =>
      (lang == 'en' ? hospitalEn : hospitalAr) ?? hospitalAr ?? hospitalEn;

  Job withStatus(JobStatus s) => Job.fromJson({...toJson(), 'status': s.wire});

  Map<String, dynamic> toJson() => _$JobToJson(this);
}

@JsonSerializable(createFactory: false)
class StatusBody {
  const StatusBody({required this.status, required this.statusTime});

  final String status;

  /// The moment the crew pressed the button (ISO-8601 UTC), not the upload time.
  final String statusTime;

  Map<String, dynamic> toJson() => _$StatusBodyToJson(this);
}

@JsonSerializable(includeIfNull: false)
class GpsPoint {
  const GpsPoint({
    required this.clientPointId,
    required this.recordedAt,
    required this.lon,
    required this.lat,
    this.accuracyM,
    this.speedKmh,
    this.headingDeg,
  });

  factory GpsPoint.fromJson(Map<String, dynamic> json) =>
      _$GpsPointFromJson(json);

  final String clientPointId;
  final String recordedAt;
  final double lon;
  final double lat;
  final double? accuracyM;
  final double? speedKmh;
  final double? headingDeg;

  Map<String, dynamic> toJson() => _$GpsPointToJson(this);
}

@JsonSerializable(createToJson: false)
class GpsSaved {
  const GpsSaved({this.saved = 0, this.duplicates = 0});

  factory GpsSaved.fromJson(Map<String, dynamic> json) =>
      _$GpsSavedFromJson(json);

  @JsonKey(defaultValue: 0)
  final int saved;
  @JsonKey(defaultValue: 0)
  final int duplicates;
}

/// Pre-arrival alert types the receiving ER understands.
enum AlertType {
  stroke('stroke'),
  stemi('stemi'),
  trauma('trauma'),
  sepsis('sepsis'),
  cardiacArrest('cardiac_arrest'),
  obstetric('obstetric'),
  other('other');

  const AlertType(this.wire);
  final String wire;
}

@JsonSerializable(createFactory: false, includeIfNull: false)
class AlertBody {
  const AlertBody({required this.type, this.note});

  final String type;
  final String? note;

  Map<String, dynamic> toJson() => _$AlertBodyToJson(this);
}

@JsonSerializable(createToJson: false)
class DispatchAlert {
  const DispatchAlert({
    this.id,
    this.dispatchId,
    this.type,
    this.note,
    this.raisedAt,
    this.acknowledgedAt,
  });

  factory DispatchAlert.fromJson(Map<String, dynamic> json) =>
      _$DispatchAlertFromJson(json);

  final String? id;
  final String? dispatchId;
  final String? type;
  final String? note;
  final DateTime? raisedAt;
  final DateTime? acknowledgedAt;
}

/// `POST /api/v1/patients`. Unknown person: `temporary` + `temporaryLabel` + `estimatedAge`.
@JsonSerializable(includeIfNull: false)
class PatientBody {
  const PatientBody({
    required this.fullNameAr,
    required this.sex,
    this.nationalId,
    this.temporary,
    this.temporaryLabel,
    this.estimatedAge,
    this.birthDate,
    this.fullNameEn,
    this.phone,
    this.motherName,
  });

  factory PatientBody.fromJson(Map<String, dynamic> json) =>
      _$PatientBodyFromJson(json);

  final String fullNameAr;
  final String sex;
  final String? nationalId;
  final bool? temporary;
  final String? temporaryLabel;
  final int? estimatedAge;
  final String? birthDate;
  final String? fullNameEn;
  final String? phone;
  final String? motherName;

  Map<String, dynamic> toJson() => _$PatientBodyToJson(this);
}

@JsonSerializable(includeIfNull: false)
class ObservationBody {
  const ObservationBody({
    required this.observedAt,
    this.caseId,
    this.heartRate,
    this.respRate,
    this.spo2,
    this.onOxygen,
    this.systolic,
    this.diastolic,
    this.temperatureC,
    this.consciousness,
    this.bloodGlucoseMmol,
    this.painScore,
    this.correctsId,
    this.note,
  });

  factory ObservationBody.fromJson(Map<String, dynamic> json) =>
      _$ObservationBodyFromJson(json);

  final String observedAt;
  final String? caseId;
  final int? heartRate;
  final int? respRate;
  final int? spo2;
  final bool? onOxygen;
  final int? systolic;
  final int? diastolic;
  final double? temperatureC;
  final String? consciousness;
  final double? bloodGlucoseMmol;
  final int? painScore;
  final int? correctsId;
  final String? note;

  bool get hasAnyValue =>
      heartRate != null ||
      respRate != null ||
      spo2 != null ||
      onOxygen != null ||
      systolic != null ||
      diastolic != null ||
      temperatureC != null ||
      consciousness != null ||
      bloodGlucoseMmol != null ||
      painScore != null;

  Map<String, dynamic> toJson() => _$ObservationBodyToJson(this);
}

@JsonSerializable(includeIfNull: false)
class TreatmentBody {
  const TreatmentBody({
    required this.givenAt,
    required this.kind,
    required this.name,
    this.caseId,
    this.dose,
    this.route,
    this.note,
    this.correctsId,
  });

  factory TreatmentBody.fromJson(Map<String, dynamic> json) =>
      _$TreatmentBodyFromJson(json);

  final String givenAt;
  final String? caseId;
  final String kind;
  final String name;
  final String? dose;
  final String? route;
  final String? note;
  final int? correctsId;

  Map<String, dynamic> toJson() => _$TreatmentBodyToJson(this);
}
