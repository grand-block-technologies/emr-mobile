import 'dart:async';

import 'package:emr_core/emr_core.dart';
import 'package:get/get.dart';

import '../../data/crew_repository.dart';
import '../home/crew_controller.dart';

/// Paramedic care on the current job. Everything is queued, so it works with no network;
/// the server accepts it only while the job for this case is open.
class PatientController extends GetxController with FormStatus {
  PatientController({
    required CrewRepository repo,
    required CrewController crew,
    OutboxService? outbox,
    DateTime Function()? now,
  })  : _repo = repo,
        _crew = crew,
        _outbox = outbox ?? Get.find<OutboxService>(),
        _now = now ?? DateTime.now;

  final CrewRepository _repo;
  final CrewController _crew;
  final OutboxService _outbox;
  final DateTime Function() _now;

  final patients = <LocalPatient>[].obs;
  final selected = Rxn<LocalPatient>();
  final _subs = <StreamSubscription<Object>>[];
  Worker? _ticks;

  String? get caseId => _crew.job.value.caseId;
  String? get dispatchId => _crew.job.value.dispatchId;

  /// The "Not sent" list: clinical writes the server refused, oldest first.
  RxList<RejectedItem> get rejected => _outbox.rejected;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
    _ticks = ever<int>(_crew.patientsTick, (_) => unawaited(load()));
    _subs
      .add(_outbox.completed.listen((d) {
        if (clinicalOutboxKinds.contains(d.item.kind)) unawaited(load());
      }));
  }

  @override
  void onClose() {
    _ticks?.dispose();
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    super.onClose();
  }

  /// Sends a refused write again, optionally corrected (a new action, new idempotency key).
  Future<void> resend(RejectedItem r, {Object? body}) async {
    await _repo.markEntryFailed(r.item, failed: false);
    if (r.item.kind == OutboxKind.handover) await _repo.markHandoverQueued(r.item);
    await _outbox.retryRejected(r, body: body);
    await load();
  }

  /// The paramedic chose to delete a refused write.
  Future<void> discard(RejectedItem r) async {
    await _outbox.discardRejected(r);
    await _repo.pruneOrphans();
    await load();
  }

  // ---- Handover ----

  /// Vitals were recorded (and not refused) for any patient on this job: "Add vitals" becomes "Update vitals".
  bool get hasVitals => patients.any((p) => p.entries.any((e) => e.label == 'entry_vitals' && !e.failed));

  /// Everyone on this job has a handover sent (or queued). Vacuously true with no patients.
  bool get allHandedOver => patients.every((p) => p.handedOver);

  /// Last vitals and treatments as text, for the paramedic to edit.
  String handoverPrefill(LocalPatient p) {
    final lines = <String>[
      p.displayName,
      for (final e in p.entries)
        if (!e.failed && e.detail != null)
          '${SudanTime.clock(e.at)} ${e.label.tr}: ${e.detail}',
    ];
    final text = lines.join('\n');
    return text.length <= HandoverBody.maxSummary
        ? text
        : text.substring(0, HandoverBody.maxSummary);
  }

  /// Queues the handover for [p]. False when the summary is empty or too long.
  Future<bool> sendHandover(LocalPatient p, String summary) async {
    final id = dispatchId;
    final text = summary.trim();
    if (id == null || text.isEmpty || text.length > HandoverBody.maxSummary) {
      return false;
    }
    await _repo.sendHandover(p, dispatchId: id, summary: text);
    await load();
    return true;
  }

  // ---- Quick vitals ----

  /// Picks the patient for "Add vitals" without the add-patient form: the only patient, or a new
  /// unknown patient when there is none. Null when there are several (the view asks which).
  Future<LocalPatient?> patientForQuickVitals({int? unknownAge}) async {
    await load();
    if (patients.length == 1) {
      selected.value = patients.first;
      return patients.first;
    }
    if (patients.isEmpty) {
      final id = caseId;
      // The server refuses an unknown patient without an estimated age.
      if (id == null || unknownAge == null) return null;
      final p = await _repo.registerPatient(
        PatientBody(
          temporary: true,
          temporaryLabel: 'Unknown patient',
          estimatedAge: unknownAge,
          fullNameAr: 'مجهول',
          fullNameEn: 'Unknown',
          sex: 'unknown',
        ),
        caseId: id,
      );
      patients.add(p);
      selected.value = p;
      return p;
    }
    return null;
  }

  Future<void> load() async {
    await _repo.pruneOrphans();
    final id = caseId;
    patients.assignAll((await _repo.patients()).where((p) => p.caseId == id));
    unawaited(_crew.refreshHandover());
  }

  void select(LocalPatient p) => selected.value = p;

  /// Known person (national ID) or unknown (temporary label + estimated age).
  Future<bool> register({
    required bool unknown,
    required String fullNameAr,
    required String sex,
    String? fullNameEn,
    String? nationalId,
    String? phone,
    String? temporaryLabel,
    int? estimatedAge,
  }) async {
    clearErrors();
    final id = caseId;
    if (id == null) return false;
    final checks = <String, String?>{'fullNameAr': unknown ? null : Validators.required(fullNameAr), 'sex': Validators.required(sex)};
    if (unknown) {
      checks['temporaryLabel'] = Validators.required(temporaryLabel);
      checks['estimatedAge'] = estimatedAge == null || estimatedAge < 0 || estimatedAge > 120 ? 'v_number' : null;
    } else {
      checks['nationalId'] = Validators.nationalId(nationalId);
      if (phone != null && phone.trim().isNotEmpty) checks['phone'] = Validators.sudanPhone(phone);
    }
    if (!applyLocal(checks)) return false;

    final body = unknown
        ? PatientBody(
            temporary: true,
            temporaryLabel: temporaryLabel!.trim(),
            estimatedAge: estimatedAge,
            fullNameAr: fullNameAr.trim().isEmpty ? temporaryLabel.trim() : fullNameAr.trim(),
            sex: sex,
          )
        : PatientBody(
            nationalId: nationalId!.trim(),
            fullNameAr: fullNameAr.trim(),
            fullNameEn: (fullNameEn?.trim().isEmpty ?? true) ? null : fullNameEn!.trim(),
            sex: sex,
            phone: (phone == null || phone.trim().isEmpty) ? null : Phone.toE164(phone),
          );
    final p = await _repo.registerPatient(body, caseId: id);
    patients.add(p);
    selected.value = p;
    return true;
  }

  /// Fields with plausible but unusual values; the view asks the paramedic to confirm them.
  List<String> unusual(Map<String, num?> values) => Vitals.unusual(values);

  Future<bool> addVitals(Map<String, num?> values, {bool? onOxygen, String? consciousness, String? note}) async {
    clearErrors();
    final p = selected.value;
    if (p == null) return false;
    final errors = Vitals.errors(values);
    setFieldKeys(errors);
    if (errors.isNotEmpty) return false;
    final body = ObservationBody(
      observedAt: isoUtc(_now()),
      caseId: caseId,
      heartRate: values['heartRate']?.toInt(),
      respRate: values['respRate']?.toInt(),
      spo2: values['spo2']?.toInt(),
      systolic: values['systolic']?.toInt(),
      diastolic: values['diastolic']?.toInt(),
      temperatureC: values['temperatureC']?.toDouble(),
      bloodGlucoseMmol: values['bloodGlucoseMmol']?.toDouble(),
      painScore: values['painScore']?.toInt(),
      onOxygen: onOxygen,
      consciousness: consciousness,
      note: (note?.trim().isEmpty ?? true) ? null : note!.trim(),
    );
    if (!body.hasAnyValue) {
      error.value = ApiError(status: 400, code: 'NO_VALUES', ar: 'v_one_value'.tr, en: 'v_one_value'.tr);
      return false;
    }
    // The timeline line goes first: a refusal can come back before this method returns.
    await _repo.recordEntry(p, 'entry_vitals', detail: _vitalsText(values, onOxygen: onOxygen, consciousness: consciousness));
    await _repo.addObservation(p, body);
    await load();
    return true;
  }

  Future<bool> addTreatment({required String kind, required String name, String? dose, String? route, String? note}) async {
    clearErrors();
    final p = selected.value;
    if (p == null) return false;
    if (!applyLocal({'kind': Validators.required(kind), 'name': Validators.required(name)})) return false;
    // The timeline line goes first: a refusal can come back before this method returns.
    await _repo.recordEntry(
      p,
      'entry_treatment',
      detail: [name.trim(), if (dose?.trim().isNotEmpty ?? false) dose!.trim(), if (route != null) 'route_$route'.tr].join(' · '),
    );
    await _repo.addTreatment(
      p,
      TreatmentBody(
        givenAt: isoUtc(_now()),
        caseId: caseId,
        kind: kind,
        name: name.trim(),
        dose: (dose?.trim().isEmpty ?? true) ? null : dose!.trim(),
        route: route,
        note: (note?.trim().isEmpty ?? true) ? null : note!.trim(),
      ),
    );
    await load();
    return true;
  }
}

String _vitalsText(Map<String, num?> v, {bool? onOxygen, String? consciousness}) {
  String n(num x) => x == x.roundToDouble() ? '${x.toInt()}' : '$x';
  final parts = <String>[
    for (final e in v.entries)
      if (e.value != null && e.key != 'systolic' && e.key != 'diastolic') '${'vital_${e.key}'.tr} ${n(e.value!)}',
    if (v['systolic'] != null || v['diastolic'] != null) '${'vital_systolic'.tr}/${'vital_diastolic'.tr} ${v['systolic'] == null ? '?' : n(v['systolic']!)}/${v['diastolic'] == null ? '?' : n(v['diastolic']!)}',
    ?consciousness,
    if (onOxygen ?? false) 'vital_onOxygen'.tr,
  ];
  return parts.join(', ');
}

abstract final class TreatmentOptions {
  static const kinds = ['medicine', 'procedure', 'oxygen', 'fluid', 'other'];
  static const routes = ['oral', 'iv', 'im', 'sc', 'inhaled', 'topical', 'rectal', 'other'];
  static const sexes = ['male', 'female', 'unknown'];
}
