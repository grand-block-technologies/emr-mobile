// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crew_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$PinBodyToJson(PinBody instance) => <String, dynamic>{
  'pin': instance.pin,
  'oldPin': ?instance.oldPin,
};

Map<String, dynamic> _$QrBodyToJson(QrBody instance) => <String, dynamic>{
  'qrToken': ?instance.qrToken,
  'code': ?instance.code,
};

Shift _$ShiftFromJson(Map<String, dynamic> json) => Shift(
  id: json['id'] as String?,
  ambulanceId: json['ambulanceId'] as String?,
  plateNumber: json['plateNumber'] as String?,
  hospitalId: json['hospitalId'] as String?,
  hospitalNameAr: json['hospitalNameAr'] as String?,
  hospitalNameEn: json['hospitalNameEn'] as String?,
  startedAt: json['startedAt'] == null
      ? null
      : DateTime.parse(json['startedAt'] as String),
  crew:
      (json['crew'] as List<dynamic>?)
          ?.map((e) => ShiftCrewMember.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$ShiftToJson(Shift instance) => <String, dynamic>{
  'id': instance.id,
  'ambulanceId': instance.ambulanceId,
  'plateNumber': instance.plateNumber,
  'hospitalId': instance.hospitalId,
  'hospitalNameAr': instance.hospitalNameAr,
  'hospitalNameEn': instance.hospitalNameEn,
  'startedAt': instance.startedAt?.toIso8601String(),
  'crew': instance.crew,
};

ShiftCrewMember _$ShiftCrewMemberFromJson(Map<String, dynamic> json) =>
    ShiftCrewMember(
      userId: json['userId'] as String?,
      role: json['role'] as String?,
      fullNameAr: json['fullNameAr'] as String?,
      fullNameEn: json['fullNameEn'] as String?,
      phone: json['phone'] as String?,
      joinedAt: json['joinedAt'] == null
          ? null
          : DateTime.parse(json['joinedAt'] as String),
      me: json['me'] as bool? ?? false,
    );

Map<String, dynamic> _$ShiftCrewMemberToJson(ShiftCrewMember instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'role': instance.role,
      'fullNameAr': instance.fullNameAr,
      'fullNameEn': instance.fullNameEn,
      'phone': instance.phone,
      'joinedAt': instance.joinedAt?.toIso8601String(),
      'me': instance.me,
    };

CurrentShift _$CurrentShiftFromJson(Map<String, dynamic> json) => CurrentShift(
  shift: json['shift'] == null
      ? null
      : Shift.fromJson(json['shift'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CurrentShiftToJson(CurrentShift instance) =>
    <String, dynamic>{'shift': instance.shift};

Job _$JobFromJson(Map<String, dynamic> json) => Job(
  dispatchId: json['dispatchId'] as String?,
  caseId: json['caseId'] as String?,
  status: json['status'] as String?,
  caseNumber: json['caseNumber'] as String?,
  priority: json['priority'] as String?,
  complaint: json['complaint'] as String?,
  directions: json['directions'] as String?,
  lon: (json['lon'] as num?)?.toDouble(),
  lat: (json['lat'] as num?)?.toDouble(),
  pinRadiusM: (json['pinRadiusM'] as num?)?.toInt(),
  landmarkAr: json['landmarkAr'] as String?,
  landmarkEn: json['landmarkEn'] as String?,
  destinationHospitalId: json['destinationHospitalId'] as String?,
  hospitalAr: json['hospitalAr'] as String?,
  hospitalEn: json['hospitalEn'] as String?,
  caseCreatedAt: json['caseCreatedAt'] == null
      ? null
      : DateTime.parse(json['caseCreatedAt'] as String),
  sentAt: json['sentAt'] == null
      ? null
      : DateTime.parse(json['sentAt'] as String),
  confirmDeadlineAt: json['confirmDeadlineAt'] == null
      ? null
      : DateTime.parse(json['confirmDeadlineAt'] as String),
  confirmedAt: json['confirmedAt'] == null
      ? null
      : DateTime.parse(json['confirmedAt'] as String),
  statusTime: json['statusTime'] == null
      ? null
      : DateTime.parse(json['statusTime'] as String),
  serverTime: json['serverTime'] == null
      ? null
      : DateTime.parse(json['serverTime'] as String),
  handovers:
      (json['handovers'] as List<dynamic>?)
          ?.map((e) => JobHandover.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$JobToJson(Job instance) => <String, dynamic>{
  'dispatchId': instance.dispatchId,
  'caseId': instance.caseId,
  'status': instance.status,
  'caseNumber': instance.caseNumber,
  'priority': instance.priority,
  'complaint': instance.complaint,
  'directions': instance.directions,
  'lon': instance.lon,
  'lat': instance.lat,
  'pinRadiusM': instance.pinRadiusM,
  'landmarkAr': instance.landmarkAr,
  'landmarkEn': instance.landmarkEn,
  'destinationHospitalId': instance.destinationHospitalId,
  'hospitalAr': instance.hospitalAr,
  'hospitalEn': instance.hospitalEn,
  'caseCreatedAt': instance.caseCreatedAt?.toIso8601String(),
  'sentAt': instance.sentAt?.toIso8601String(),
  'confirmDeadlineAt': instance.confirmDeadlineAt?.toIso8601String(),
  'confirmedAt': instance.confirmedAt?.toIso8601String(),
  'statusTime': instance.statusTime?.toIso8601String(),
  'serverTime': instance.serverTime?.toIso8601String(),
  'handovers': instance.handovers.map((e) => e.toJson()).toList(),
};

Map<String, dynamic> _$StatusBodyToJson(StatusBody instance) =>
    <String, dynamic>{
      'status': instance.status,
      'noTransportReason': ?instance.noTransportReason,
      'note': ?instance.note,
      'statusTime': instance.statusTime,
    };

GpsPoint _$GpsPointFromJson(Map<String, dynamic> json) => GpsPoint(
  clientPointId: json['clientPointId'] as String,
  recordedAt: json['recordedAt'] as String,
  lon: (json['lon'] as num).toDouble(),
  lat: (json['lat'] as num).toDouble(),
  accuracyM: (json['accuracyM'] as num?)?.toDouble(),
  speedKmh: (json['speedKmh'] as num?)?.toDouble(),
  headingDeg: (json['headingDeg'] as num?)?.toDouble(),
);

Map<String, dynamic> _$GpsPointToJson(GpsPoint instance) => <String, dynamic>{
  'clientPointId': instance.clientPointId,
  'recordedAt': instance.recordedAt,
  'lon': instance.lon,
  'lat': instance.lat,
  'accuracyM': ?instance.accuracyM,
  'speedKmh': ?instance.speedKmh,
  'headingDeg': ?instance.headingDeg,
};

GpsSaved _$GpsSavedFromJson(Map<String, dynamic> json) => GpsSaved(
  saved: (json['saved'] as num?)?.toInt() ?? 0,
  duplicates: (json['duplicates'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AlertBodyToJson(AlertBody instance) => <String, dynamic>{
  'type': instance.type,
  'note': ?instance.note,
};

DispatchAlert _$DispatchAlertFromJson(Map<String, dynamic> json) =>
    DispatchAlert(
      id: json['id'] as String?,
      dispatchId: json['dispatchId'] as String?,
      type: json['type'] as String?,
      note: json['note'] as String?,
      raisedAt: json['raisedAt'] == null
          ? null
          : DateTime.parse(json['raisedAt'] as String),
      acknowledgedAt: json['acknowledgedAt'] == null
          ? null
          : DateTime.parse(json['acknowledgedAt'] as String),
    );

PatientBody _$PatientBodyFromJson(Map<String, dynamic> json) => PatientBody(
  fullNameAr: json['fullNameAr'] as String,
  sex: json['sex'] as String,
  nationalId: json['nationalId'] as String?,
  temporary: json['temporary'] as bool?,
  temporaryLabel: json['temporaryLabel'] as String?,
  estimatedAge: (json['estimatedAge'] as num?)?.toInt(),
  birthDate: json['birthDate'] as String?,
  fullNameEn: json['fullNameEn'] as String?,
  phone: json['phone'] as String?,
  motherName: json['motherName'] as String?,
);

Map<String, dynamic> _$PatientBodyToJson(PatientBody instance) =>
    <String, dynamic>{
      'fullNameAr': instance.fullNameAr,
      'sex': instance.sex,
      'nationalId': ?instance.nationalId,
      'temporary': ?instance.temporary,
      'temporaryLabel': ?instance.temporaryLabel,
      'estimatedAge': ?instance.estimatedAge,
      'birthDate': ?instance.birthDate,
      'fullNameEn': ?instance.fullNameEn,
      'phone': ?instance.phone,
      'motherName': ?instance.motherName,
    };

ObservationBody _$ObservationBodyFromJson(Map<String, dynamic> json) =>
    ObservationBody(
      observedAt: json['observedAt'] as String,
      caseId: json['caseId'] as String?,
      heartRate: (json['heartRate'] as num?)?.toInt(),
      respRate: (json['respRate'] as num?)?.toInt(),
      spo2: (json['spo2'] as num?)?.toInt(),
      onOxygen: json['onOxygen'] as bool?,
      systolic: (json['systolic'] as num?)?.toInt(),
      diastolic: (json['diastolic'] as num?)?.toInt(),
      temperatureC: (json['temperatureC'] as num?)?.toDouble(),
      consciousness: json['consciousness'] as String?,
      bloodGlucoseMmol: (json['bloodGlucoseMmol'] as num?)?.toDouble(),
      painScore: (json['painScore'] as num?)?.toInt(),
      correctsId: (json['correctsId'] as num?)?.toInt(),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$ObservationBodyToJson(ObservationBody instance) =>
    <String, dynamic>{
      'observedAt': instance.observedAt,
      'caseId': ?instance.caseId,
      'heartRate': ?instance.heartRate,
      'respRate': ?instance.respRate,
      'spo2': ?instance.spo2,
      'onOxygen': ?instance.onOxygen,
      'systolic': ?instance.systolic,
      'diastolic': ?instance.diastolic,
      'temperatureC': ?instance.temperatureC,
      'consciousness': ?instance.consciousness,
      'bloodGlucoseMmol': ?instance.bloodGlucoseMmol,
      'painScore': ?instance.painScore,
      'correctsId': ?instance.correctsId,
      'note': ?instance.note,
    };

TreatmentBody _$TreatmentBodyFromJson(Map<String, dynamic> json) =>
    TreatmentBody(
      givenAt: json['givenAt'] as String,
      kind: json['kind'] as String,
      name: json['name'] as String,
      caseId: json['caseId'] as String?,
      dose: json['dose'] as String?,
      route: json['route'] as String?,
      note: json['note'] as String?,
      correctsId: (json['correctsId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TreatmentBodyToJson(TreatmentBody instance) =>
    <String, dynamic>{
      'givenAt': instance.givenAt,
      'caseId': ?instance.caseId,
      'kind': instance.kind,
      'name': instance.name,
      'dose': ?instance.dose,
      'route': ?instance.route,
      'note': ?instance.note,
      'correctsId': ?instance.correctsId,
    };

Map<String, dynamic> _$HandoverBodyToJson(HandoverBody instance) =>
    <String, dynamic>{
      'caseId': instance.caseId,
      'dispatchId': instance.dispatchId,
      'patientId': instance.patientId,
      'summary': instance.summary,
    };

Medicine _$MedicineFromJson(Map<String, dynamic> json) => Medicine(
  code: json['code'] as String,
  nameAr: json['nameAr'] as String?,
  nameEn: json['nameEn'] as String?,
);

Map<String, dynamic> _$MedicineToJson(Medicine instance) => <String, dynamic>{
  'code': instance.code,
  'nameAr': instance.nameAr,
  'nameEn': instance.nameEn,
};

JobHandover _$JobHandoverFromJson(Map<String, dynamic> json) => JobHandover(
  id: json['id'] as String?,
  patientId: json['patientId'] as String?,
  fullNameAr: json['fullNameAr'] as String?,
  fullNameEn: json['fullNameEn'] as String?,
  temporaryLabel: json['temporaryLabel'] as String?,
  status: json['status'] as String?,
  handedAt: json['handedAt'] == null
      ? null
      : DateTime.parse(json['handedAt'] as String),
  receivedAt: json['receivedAt'] == null
      ? null
      : DateTime.parse(json['receivedAt'] as String),
);

Map<String, dynamic> _$JobHandoverToJson(JobHandover instance) =>
    <String, dynamic>{
      'id': instance.id,
      'patientId': instance.patientId,
      'fullNameAr': instance.fullNameAr,
      'fullNameEn': instance.fullNameEn,
      'temporaryLabel': instance.temporaryLabel,
      'status': instance.status,
      'handedAt': instance.handedAt?.toIso8601String(),
      'receivedAt': instance.receivedAt?.toIso8601String(),
    };

CrewPastJob _$CrewPastJobFromJson(Map<String, dynamic> json) => CrewPastJob(
  dispatchId: json['dispatchId'] as String,
  caseId: json['caseId'] as String?,
  caseNumber: json['caseNumber'] as String?,
  priority: json['priority'] as String?,
  complaint: json['complaint'] as String?,
  status: json['status'] as String?,
  sentAt: json['sentAt'] == null
      ? null
      : DateTime.parse(json['sentAt'] as String),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  closingReason: json['closingReason'] as String?,
  hospitalAr: json['hospitalAr'] as String?,
  hospitalEn: json['hospitalEn'] as String?,
  plateNumber: json['plateNumber'] as String?,
);

Map<String, dynamic> _$CrewPastJobToJson(CrewPastJob instance) =>
    <String, dynamic>{
      'dispatchId': instance.dispatchId,
      'caseId': instance.caseId,
      'caseNumber': instance.caseNumber,
      'priority': instance.priority,
      'complaint': instance.complaint,
      'status': instance.status,
      'sentAt': instance.sentAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'closingReason': instance.closingReason,
      'hospitalAr': instance.hospitalAr,
      'hospitalEn': instance.hospitalEn,
      'plateNumber': instance.plateNumber,
    };
