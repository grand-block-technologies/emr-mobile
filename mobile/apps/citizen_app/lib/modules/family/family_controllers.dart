import 'dart:async';

import 'package:emr_core/emr_core.dart';
import 'package:get/get.dart';

import '../../data/citizen_repository.dart';

/// Links a child or ward. A hospital confirms the link in person.
class FamilyController extends GetxController with FormStatus {
  FamilyController({required CitizenRepository repo}) : _repo = repo;

  final CitizenRepository _repo;
  final links = <SavedDependant>[].obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async => links.assignAll(await _repo.dependants());

  Future<bool> add(String childNationalId, DependantRelation? relation) async {
    if (busy.value) return false;
    clearErrors();
    if (!applyLocal({
      'childNationalId': Validators.nationalId(childNationalId),
      'relation': relation == null ? 'v_required' : null,
    })) {
      return false;
    }
    busy.value = true;
    try {
      links.add(await _repo.addDependant(childNationalId, relation!));
      return true;
    } on Object catch (e) {
      showApiError(ApiError.of(e));
      return false;
    } finally {
      busy.value = false;
    }
  }
}

/// Medical history. Until the ID card (and family link) is verified at a hospital the server
/// answers `403 CITIZEN_HISTORY_NOT_VERIFIED`; the view explains how to verify.
class HistoryController extends GetxController {
  HistoryController({required CitizenRepository repo, this.patientId})
    : _repo = repo;

  final CitizenRepository _repo;
  final String? patientId;

  final history = const CitizenHistory().obs;
  final loading = false.obs;
  final error = Rxn<ApiError>();
  final notVerified = false.obs;
  int _page = 0;

  bool get hasNext => history.value.hasNext;

  @override
  void onInit() {
    super.onInit();
    unawaited(reload());
  }

  Future<void> reload() async {
    loading.value = true;
    error.value = null;
    notVerified.value = false;
    try {
      history.value = await _repo.history(page: 0, patientId: patientId);
      _page = 0;
    } on Object catch (e) {
      final err = ApiError.of(e);
      if (err.code == 'CITIZEN_HISTORY_NOT_VERIFIED') {
        notVerified.value = true;
      } else {
        error.value = err;
      }
    } finally {
      loading.value = false;
    }
  }

  /// Next page of all four lists.
  Future<void> more() async {
    if (!hasNext) return;
    try {
      final n = await _repo.history(page: _page + 1, patientId: patientId);
      _page++;
      final h = history.value;
      ApiPage<HistoryRow> join(ApiPage<HistoryRow> a, ApiPage<HistoryRow> b) =>
          ApiPage(
            content: [...a.content, ...b.content],
            page: b.page,
            size: b.size,
            hasNext: b.hasNext,
          );
      history.value = CitizenHistory(
        patientId: h.patientId,
        visits: join(h.visits, n.visits),
        diagnoses: join(h.diagnoses, n.diagnoses),
        checkResults: join(h.checkResults, n.checkResults),
        conditions: join(h.conditions, n.conditions),
      );
    } on Object catch (e) {
      showToast(ApiError.of(e).message(currentLang()));
    }
  }
}

class ProfileController extends GetxController {
  ProfileController({required CitizenRepository repo}) : _repo = repo;

  final CitizenRepository _repo;
  final profile = Rxn<CitizenProfile>();
  final error = Rxn<ApiError>();

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    profile.value ??= await _repo.cachedProfile();
    try {
      profile.value = await _repo.profile();
      error.value = null;
    } on Object catch (e) {
      error.value = ApiError.of(e);
    }
  }
}
