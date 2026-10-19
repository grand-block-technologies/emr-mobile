import 'package:emr_core/emr_core.dart';

/// Crew data: reads go straight to the API; writes that must survive offline go through the
/// outbox; the current shift and job are cached (encrypted) so the app opens with no network.
class CrewRepository {
  CrewRepository({
    required ApiClient api,
    required OutboxService outbox,
    required KeyValueStore cache,
    DateTime Function()? now,
  }) : _api = api,
       _outbox = outbox,
       _cache = cache,
       _now = now ?? DateTime.now;

  final ApiClient _api;
  final OutboxService _outbox;
  final KeyValueStore _cache;
  final DateTime Function() _now;

  static const _shiftKey = 'crew.shift';
  static const _jobKey = 'crew.job';
  static const _patientsKey = 'crew.patients';

  // ---- PIN (online) ----
  Future<void> setPin(String pin, {String? oldPin}) =>
      _api.crew.setPin(PinBody(pin: pin, oldPin: oldPin));
  Future<void> verifyPin(String pin) => _api.crew.verifyPin(PinBody(pin: pin));

  // ---- Shift ----
  Future<Shift?> cachedShift() async {
    final v = await _cache.get(_shiftKey);
    return v is Map ? Shift.fromJson(Map<String, dynamic>.from(v)) : null;
  }

  Future<Shift> startShift(String value, {bool code = false}) => _saveShift(
    _api.crew.startShift(
      code ? QrBody.code(value.trim()) : QrBody(value.trim()),
    ),
  );
  Future<Shift> joinShift(String value, {bool code = false}) => _saveShift(
    _api.crew.joinShift(
      code ? QrBody.code(value.trim()) : QrBody(value.trim()),
    ),
  );

  Future<Shift> _saveShift(Future<Shift> call) async {
    final s = await call;
    await rememberShift(s);
    return s;
  }

  Future<void> rememberShift(Shift s) => _cache.put(_shiftKey, s.toJson());

  Future<Shift?> currentShift() async => (await _api.crew.currentShift()).shift;

  Future<void> endShift() async {
    await _api.crew.endShift();
    await forgetShift();
  }

  Future<void> forgetShift() async {
    await _cache.delete(_shiftKey);
    await _cache.delete(_jobKey);
    await _cache.delete(_patientsKey);
  }

  // ---- Job ----
  Future<Job> cachedJob() async {
    final v = await _cache.get(_jobKey);
    return v is Map ? Job.fromJson(Map<String, dynamic>.from(v)) : Job.none;
  }

  Future<void> cacheJob(Job job) =>
      job.hasJob ? _cache.put(_jobKey, job.toJson()) : _cache.delete(_jobKey);

  Future<Job> fetchJob() async {
    final j = await _api.crew.job();
    await cacheJob(j);
    return j;
  }

  /// True while confirm/status writes for [dispatchId] are still waiting to be sent.
  bool hasPendingSteps(String dispatchId) => _outbox.items.any(
    (i) =>
        (i.kind == OutboxKind.status || i.kind == OutboxKind.confirm) &&
        i.path.contains(dispatchId),
  );

  Future<void> confirm(String dispatchId) =>
      _outbox.add(OutboxKind.confirm, CrewPaths.confirm(dispatchId), null);

  /// [at] is the moment the button was pressed, not the upload time.
  Future<void> setStatus(String dispatchId, JobStatus status, DateTime at) =>
      _outbox.add(
        OutboxKind.status,
        CrewPaths.status(dispatchId),
        StatusBody(status: status.wire, statusTime: isoUtc(at)).toJson(),
      );

  Future<void> raiseAlert(String dispatchId, AlertType type, {String? note}) =>
      _outbox.add(
        OutboxKind.alert,
        CrewPaths.alerts(dispatchId),
        AlertBody(
          type: type.wire,
          note: (note?.trim().isEmpty ?? true) ? null : note!.trim(),
        ).toJson(),
      );

  // ---- Patients (paramedic) ----

  /// Patients registered on this job, kept so vitals/treatments can be added offline.
  Future<List<LocalPatient>> patients() async {
    final v = await _cache.get(_patientsKey);
    return v is List
        ? v
              .whereType<Map<dynamic, dynamic>>()
              .map((m) => LocalPatient.fromJson(Map<String, dynamic>.from(m)))
              .toList()
        : [];
  }

  Future<void> _savePatients(List<LocalPatient> list) =>
      _cache.put(_patientsKey, [for (final p in list) p.toJson()]);

  Future<LocalPatient> registerPatient(
    PatientBody body, {
    required String caseId,
  }) async {
    final ref = 'pt-${_now().microsecondsSinceEpoch}';
    await _outbox.add(
      OutboxKind.patient,
      CrewPaths.patients,
      body.toJson(),
      resultRef: ref,
    );
    final p = LocalPatient(
      ref: ref,
      caseId: caseId,
      body: body,
      createdAt: _now().toUtc(),
    );
    await _savePatients([...await patients(), p]);
    return p;
  }

  /// The server id once the registration was sent, else a `{ref:…}` placeholder the outbox resolves.
  String patientPathId(LocalPatient p) =>
      _outbox.refValue(p.ref) ?? OutboxRef.placeholder(p.ref);

  Future<void> addObservation(LocalPatient p, ObservationBody body) =>
      _outbox.add(
        OutboxKind.observation,
        CrewPaths.observations(patientPathId(p)),
        body.toJson(),
      );

  Future<void> addTreatment(LocalPatient p, TreatmentBody body) => _outbox.add(
    OutboxKind.treatment,
    CrewPaths.treatments(patientPathId(p)),
    body.toJson(),
  );

  Future<void> recordEntry(LocalPatient p, String label) async {
    final list = await patients();
    final i = list.indexWhere((x) => x.ref == p.ref);
    if (i < 0) return;
    list[i] = list[i].withEntry(label, _now().toUtc());
    await _savePatients(list);
  }
}

/// A patient registered from this phone on the current job.
class LocalPatient {
  const LocalPatient({
    required this.ref,
    required this.caseId,
    required this.body,
    required this.createdAt,
    this.entries = const [],
  });

  factory LocalPatient.fromJson(Map<String, dynamic> j) => LocalPatient(
    ref: j['ref'] as String,
    caseId: j['caseId'] as String,
    body: PatientBody.fromJson(Map<String, dynamic>.from(j['body'] as Map)),
    createdAt: DateTime.parse(j['createdAt'] as String),
    entries: [
      for (final e in (j['entries'] as List? ?? const []))
        (
          label: (e as Map)['label'] as String,
          at: DateTime.parse(e['at'] as String),
        ),
    ],
  );

  final String ref;
  final String caseId;
  final PatientBody body;
  final DateTime createdAt;

  /// What was recorded for this patient from this phone (shown as a timeline).
  final List<({String label, DateTime at})> entries;

  String get displayName => body.temporary == true
      ? (body.temporaryLabel ?? body.fullNameAr)
      : body.fullNameAr;

  LocalPatient withEntry(String label, DateTime at) => LocalPatient(
    ref: ref,
    caseId: caseId,
    body: body,
    createdAt: createdAt,
    entries: [...entries, (label: label, at: at)],
  );

  Map<String, dynamic> toJson() => {
    'ref': ref,
    'caseId': caseId,
    'body': body.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'entries': [
      for (final e in entries) {'label': e.label, 'at': e.at.toIso8601String()},
    ],
  };
}
