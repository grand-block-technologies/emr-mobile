import 'package:emr_core/emr_core.dart';

/// Citizen data. SOS is not queued (it must reach the call centre now or the user calls 999),
/// but its idempotency key is kept across retries of one press.
class CitizenRepository {
  CitizenRepository({required ApiClient api, required KeyValueStore cache, DateTime Function()? now})
      : _api = api,
        _cache = cache,
        _now = now ?? DateTime.now;

  final ApiClient _api;
  final KeyValueStore _cache;
  final DateTime Function() _now;

  static const _dependantsKey = 'citizen.dependants';
  static const _profileKey = 'citizen.profile';

  Future<Challenge> signUpStart(String phoneE164) => _api.citizen.signUpStart(SignUpStartBody(phoneE164));
  Future<SignedUp> signUpFinish(SignUpFinishBody body) => _api.citizen.signUpFinish(body);

  Future<CitizenProfile> profile() async {
    final p = await _api.citizen.me();
    await _cache.put(_profileKey, p.toJson());
    return p;
  }

  Future<CitizenProfile?> cachedProfile() async {
    final v = await _cache.get(_profileKey);
    return v is Map ? CitizenProfile.fromJson(Map<String, dynamic>.from(v)) : null;
  }

  Future<SosCreated> sos(SosBody body, String key) => _api.citizen.sos(body, key);

  Future<ApiPage<RequestRow>> requests({int page = 0, int size = 10}) => _api.citizen.requests(page, size);
  Future<RequestStatus> request(String id) => _api.citizen.request(id);

  /// The newest open request, if any (used when the server says there are too many open).
  Future<RequestRow?> latestOpen() async => (await requests(size: 10)).content.where((r) => r.isOpen).firstOrNull;

  Future<CitizenHistory> history({int page = 0, int size = 10, String? patientId}) =>
      _api.citizen.history(page, size, patientId: patientId);

  /// There is no list endpoint for family links yet, so the links made from this phone are kept.
  Future<List<SavedDependant>> dependants() async {
    final v = await _cache.get(_dependantsKey);
    return v is List ? v.whereType<Map<dynamic, dynamic>>().map((m) => SavedDependant.fromJson(Map<String, dynamic>.from(m))).toList() : [];
  }

  Future<SavedDependant> addDependant(String childNationalId, DependantRelation relation) async {
    final link = await _api.citizen.addDependant(DependantBody(childNationalId: childNationalId.trim(), relation: relation.wire));
    final saved = SavedDependant(
      id: link.id ?? '',
      childNationalId: childNationalId.trim(),
      relation: relation.wire,
      status: link.status ?? 'pending',
      addedAt: _now().toUtc(),
    );
    await _cache.put(_dependantsKey, [for (final d in [...await dependants(), saved]) d.toJson()]);
    return saved;
  }
}

class SavedDependant {
  const SavedDependant({required this.id, required this.childNationalId, required this.relation, required this.status, required this.addedAt});

  factory SavedDependant.fromJson(Map<String, dynamic> j) => SavedDependant(
        id: j['id'] as String? ?? '',
        childNationalId: j['childNationalId'] as String? ?? '',
        relation: j['relation'] as String? ?? 'child',
        status: j['status'] as String? ?? 'pending',
        addedAt: DateTime.tryParse(j['addedAt'] as String? ?? '') ?? DateTime.utc(2026),
      );

  final String id;
  final String childNationalId;
  final String relation;
  final String status;
  final DateTime addedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'childNationalId': childNationalId,
        'relation': relation,
        'status': status,
        'addedAt': addedAt.toIso8601String(),
      };
}
