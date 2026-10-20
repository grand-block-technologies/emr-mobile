import 'dart:async';

import 'package:emr_core/emr_core.dart';
import 'package:get/get.dart';

import '../../data/citizen_repository.dart';

/// Paged list of the citizen's requests (use `hasNext`; `totalElements` can be null).
class RequestsController extends GetxController {
  RequestsController({required CitizenRepository repo, this.pageSize = 10})
    : _repo = repo;

  final CitizenRepository _repo;
  final int pageSize;

  final rows = <RequestRow>[].obs;
  final loading = false.obs;
  final loadingMore = false.obs;
  final error = Rxn<ApiError>();
  final hasNext = false.obs;
  int _page = 0;

  @override
  void onInit() {
    super.onInit();
    unawaited(reload());
  }

  Future<void> reload() async {
    loading.value = true;
    error.value = null;
    try {
      final p = await _repo.requests(page: 0, size: pageSize);
      _page = 0;
      rows.assignAll(p.content);
      hasNext.value = p.hasNext;
    } on Object catch (e) {
      error.value = ApiError.of(e);
    } finally {
      loading.value = false;
    }
  }

  Future<void> more() async {
    if (!hasNext.value || loadingMore.value) return;
    loadingMore.value = true;
    try {
      final p = await _repo.requests(page: _page + 1, size: pageSize);
      _page++;
      rows.addAll(p.content.where((r) => rows.every((x) => x.id != r.id)));
      hasNext.value = p.hasNext;
    } on Object catch (e) {
      showToast(ApiError.of(e).message(currentLang()));
    } finally {
      loadingMore.value = false;
    }
  }
}

/// One request. There is no live channel for citizens: poll while the screen is open,
/// stop once the request is closed.
class RequestDetailController extends GetxController {
  RequestDetailController({
    required CitizenRepository repo,
    required this.id,
    this.pollEvery = const Duration(seconds: 12),
  }) : _repo = repo;

  final CitizenRepository _repo;
  final String id;
  final Duration pollEvery;

  final status = Rxn<RequestStatus>();
  final error = Rxn<ApiError>();
  Timer? _timer;

  bool get polling => _timer?.isActive ?? false;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
    _timer = Timer.periodic(pollEvery, (_) => unawaited(load()));
  }

  Future<void> load() async {
    try {
      final s = await _repo.request(id);
      status.value = s;
      error.value = null;
      if (s.isClosed) _timer?.cancel();
    } on Object catch (e) {
      error.value = ApiError.of(e);
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
