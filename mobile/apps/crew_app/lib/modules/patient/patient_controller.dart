import 'package:emr_core/emr_core.dart';
import 'package:get/get.dart';

import '../../data/crew_repository.dart';
import '../home/crew_controller.dart';

/// Paramedic care on the current job. Everything is queued, so it works with no network;
/// the server accepts it only while the job for this case is open.
class PatientController extends GetxController with FormStatus {
  PatientController({required CrewRepository repo, required CrewController crew, DateTime Function()? now})
      : _repo = repo,
        _crew = crew,
        _now = now ?? DateTime.now;

  final CrewRepository _repo;
  final CrewController _crew;
  final DateTime Function() _now;

  final patients = <LocalPatient>[].obs;
  final selected = Rxn<LocalPatient>();

  String? get caseId => _crew.job.value.caseId;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final id = caseId;
    patients.assignAll((await _repo.patients()).where((p) => p.caseId == id));
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
    await _repo.addObservation(p, body);
    await _repo.recordEntry(p, 'entry_vitals');
    await load();
    return true;
  }

  Future<bool> addTreatment({required String kind, required String name, String? dose, String? route, String? note}) async {
    clearErrors();
    final p = selected.value;
    if (p == null) return false;
    if (!applyLocal({'kind': Validators.required(kind), 'name': Validators.required(name)})) return false;
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
    await _repo.recordEntry(p, 'entry_treatment');
    await load();
    return true;
  }
}

abstract final class TreatmentOptions {
  static const kinds = ['medicine', 'procedure', 'oxygen', 'fluid', 'other'];
  static const routes = ['oral', 'iv', 'im', 'sc', 'inhaled', 'topical', 'rectal', 'other'];
  static const sexes = ['male', 'female', 'unknown'];
}
