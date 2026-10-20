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
  static const _medicinesKey = 'crew.medicines';
  static const _historyKey = 'crew.history';

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
  ///
  /// [noTransportReason] and [note] are sent only when completing from `on_scene`.
  Future<void> setStatus(
    String dispatchId,
    JobStatus status,
    DateTime at, {
    NoTransportReason? noTransportReason,
    String? note,
  }) => _outbox.add(
    OutboxKind.status,
    CrewPaths.status(dispatchId),
    StatusBody(
      status: status.wire,
      statusTime: isoUtc(at),
      noTransportReason: noTransportReason?.wire,
      note: (note?.trim().isEmpty ?? true) ? null : note!.trim(),
    ).toJson(),
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

  /// Drops patients whose registration is gone: never sent, no longer queued, and not waiting in
  /// the "Not sent" list (the paramedic deleted it). Anything added to them could never be sent.
  Future<void> pruneOrphans() async {
    await _outbox.load();
    final list = await patients();
    final live = [
      for (final p in list)
        if (_outbox.refValue(p.ref) != null ||
            _outbox.items.any((i) => i.resultRef == p.ref) ||
            _outbox.rejected.any((r) => r.item.resultRef == p.ref))
          p,
    ];
    if (live.length != list.length) await _savePatients(live);
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

  /// [detail] is a short readable text of the entry (used to prefill the handover).
  Future<void> recordEntry(LocalPatient p, String label, {String? detail}) async {
    final list = await patients();
    final i = list.indexWhere((x) => x.ref == p.ref);
    if (i < 0) return;
    list[i] = list[i].withEntry(label, _now().toUtc(), detail: detail);
    await _savePatients(list);
  }

  /// The patient a queued write belongs to: by `{ref:}` or server id in the path/body, or by
  /// the registration's own `resultRef`.
  LocalPatient? patientOf(List<LocalPatient> list, OutboxItem item) {
    final path = item.path;
    final body = item.body;
    for (final p in list) {
      if (item.resultRef == p.ref) return p;
      final id = patientPathId(p);
      if (path.contains('/patients/$id/') ||
          path.contains(OutboxRef.placeholder(p.ref)) ||
          (body is Map &&
              (body['patientId'] == id ||
                  body['patientId'] == OutboxRef.placeholder(p.ref)))) {
        return p;
      }
    }
    return null;
  }

  static String? _entryLabelOf(OutboxKind k) => switch (k) {
    OutboxKind.observation => 'entry_vitals',
    OutboxKind.treatment => 'entry_treatment',
    _ => null,
  };

  /// Marks the newest matching timeline line "Not saved" (or back to normal when [failed] is false).
  Future<void> markEntryFailed(OutboxItem item, {required bool failed}) async {
    final label = _entryLabelOf(item.kind);
    if (label == null) return;
    final list = await patients();
    final p = patientOf(list, item);
    if (p == null) return;
    final idx = p.entries.lastIndexWhere(
      (e) => e.label == label && e.failed != failed,
    );
    if (idx < 0) return;
    final entries = [...p.entries];
    entries[idx] = entries[idx].copyWith(failed: failed);
    list[list.indexWhere((x) => x.ref == p.ref)] = p.copyWith(entries: entries);
    await _savePatients(list);
  }

  // ---- Handover ----

  /// Queues the handover and marks the patient "Handover sent" once the server accepted it.
  Future<void> sendHandover(
    LocalPatient p, {
    required String dispatchId,
    required String summary,
  }) async {
    final list = await patients();
    final i = list.indexWhere((x) => x.ref == p.ref);
    final ref = i < 0 ? p : list[i];
    await _outbox.add(
      OutboxKind.handover,
      CrewPaths.handovers,
      HandoverBody(
        caseId: p.caseId,
        dispatchId: dispatchId,
        patientId: patientPathId(p),
        summary: summary.trim(),
      ).toJson(),
    );
    if (i >= 0) {
      list[i] = ref.copyWith(handover: HandoverState.queued);
      await _savePatients(list);
    }
  }

  /// Marks the patient whose handover the server accepted.
  Future<void> markHandoverSent(OutboxItem item) =>
      _setHandover(item, HandoverState.sent);

  Future<void> markHandoverQueued(OutboxItem item) =>
      _setHandover(item, HandoverState.queued);

  /// A refused handover goes back to "not handed over" so it can be fixed and sent again.
  Future<void> markHandoverRefused(OutboxItem item) =>
      _setHandover(item, HandoverState.none);

  Future<void> _setHandover(OutboxItem item, HandoverState state) async {
    final list = await patients();
    final p = patientOf(list, item);
    if (p == null) return;
    list[list.indexWhere((x) => x.ref == p.ref)] = p.copyWith(handover: state);
    await _savePatients(list);
  }

  // ---- Medicines (cached for offline) ----

  Future<List<Medicine>> cachedMedicines() async {
    final v = await _cache.get(_medicinesKey);
    return v is List
        ? v
              .whereType<Map<dynamic, dynamic>>()
              .map((m) => Medicine.fromJson(Map<String, dynamic>.from(m)))
              .toList()
        : [];
  }

  /// Loads the list and caches it. Falls back to the cache when offline.
  Future<List<Medicine>> medicines() async {
    try {
      final list = await _api.crew.medicines();
      await _cache.put(_medicinesKey, [for (final m in list) m.toJson()]);
      return list;
    } on Object {
      return cachedMedicines();
    }
  }

  // ---- Request history ----

  /// Jobs the crew member was on, newest first, from any phone (`GET /crew/jobs`).
  /// The first page is cached so the list still opens offline.
  Future<ApiPage<CrewPastJob>> pastJobs({int page = 0, int size = 20}) async {
    final p = await _api.crew.pastJobs(page, size);
    if (page == 0) {
      await _cache.put(_historyKey, [for (final j in p.content) j.toJson()]);
    }
    return p;
  }

  Future<List<CrewPastJob>> cachedPastJobs() async {
    final v = await _cache.get(_historyKey);
    return v is List
        ? v
              .whereType<Map<dynamic, dynamic>>()
              .map((m) => CrewPastJob.fromJson(Map<String, dynamic>.from(m)))
              .toList()
        : [];
  }
}

/// One line of a patient's timeline. [failed] means the server refused it ("Not saved").
class PatientEntry {
  const PatientEntry({
    required this.label,
    required this.at,
    this.detail,
    this.failed = false,
  });

  final String label;
  final DateTime at;
  final String? detail;
  final bool failed;

  PatientEntry copyWith({bool? failed}) => PatientEntry(
    label: label,
    at: at,
    detail: detail,
    failed: failed ?? this.failed,
  );

  Map<String, dynamic> toJson() => {
    'label': label,
    'at': at.toIso8601String(),
    'detail': detail,
    'failed': failed,
  };
}

/// Where a patient's handover to the ER stands, as far as this phone knows.
enum HandoverState { none, queued, sent }

/// A patient registered from this phone on the current job.
class LocalPatient {
  const LocalPatient({
    required this.ref,
    required this.caseId,
    required this.body,
    required this.createdAt,
    this.entries = const [],
    this.handover = HandoverState.none,
  });

  factory LocalPatient.fromJson(Map<String, dynamic> j) => LocalPatient(
    ref: j['ref'] as String,
    caseId: j['caseId'] as String,
    body: PatientBody.fromJson(Map<String, dynamic>.from(j['body'] as Map)),
    createdAt: DateTime.parse(j['createdAt'] as String),
    entries: [
      for (final e in (j['entries'] as List? ?? const []))
        PatientEntry(
          label: (e as Map)['label'] as String,
          at: DateTime.parse(e['at'] as String),
          detail: e['detail'] as String?,
          failed: e['failed'] as bool? ?? false,
        ),
    ],
    handover: HandoverState.values.firstWhere(
      (h) => h.name == j['handover'],
      orElse: () => HandoverState.none,
    ),
  );

  final String ref;
  final String caseId;
  final PatientBody body;
  final DateTime createdAt;

  /// What was recorded for this patient from this phone (shown as a timeline).
  final List<PatientEntry> entries;

  final HandoverState handover;

  bool get handedOver => handover != HandoverState.none;

  String get displayName => body.temporary == true
      ? (body.temporaryLabel ?? body.fullNameAr)
      : body.fullNameAr;

  LocalPatient withEntry(String label, DateTime at, {String? detail}) =>
      LocalPatient(
        ref: ref,
        caseId: caseId,
        body: body,
        createdAt: createdAt,
        entries: [...entries, PatientEntry(label: label, at: at, detail: detail)],
        handover: handover,
      );

  LocalPatient copyWith({HandoverState? handover, List<PatientEntry>? entries}) => LocalPatient(
    ref: ref,
    caseId: caseId,
    body: body,
    createdAt: createdAt,
    entries: entries ?? this.entries,
    handover: handover ?? this.handover,
  );

  Map<String, dynamic> toJson() => {
    'ref': ref,
    'caseId': caseId,
    'body': body.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'entries': [
      for (final e in entries) e.toJson(),
    ],
    'handover': handover.name,
  };
}
