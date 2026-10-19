import 'dart:async';

import 'package:get/get.dart';

import '../auth/auth_repository.dart';

/// A data-only push. Treat it only as a hint to refetch; never display its content.
class PushHint {
  const PushHint({required this.type, this.id});
  final String type;

  /// `dispatchId` (crew) or request `id` (citizen).
  final String? id;

  static PushHint? fromData(Map<String, Object?> data) {
    final type = data['type'];
    if (type is! String) return null;
    final id = data['dispatchId'] ?? data['id'];
    return PushHint(type: type, id: id is String ? id : null);
  }
}

/// Where push tokens come from. Production FCM sending is not live on the backend yet, so the
/// default provider has no token. Plug in a FirebaseMessaging-backed provider once
/// `google-services.json` / `GoogleService-Info.plist` exist (see mobile/README.md).
abstract interface class PushProvider {
  Future<String?> token();
  Stream<String> get tokenRefreshes;
  Stream<Map<String, Object?>> get messages;
}

class NoPushProvider implements PushProvider {
  const NoPushProvider();

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();

  @override
  Stream<Map<String, Object?>> get messages => const Stream.empty();
}

/// Registers the push token after sign-in and whenever it changes, and turns messages into hints.
class PushService extends GetxService {
  PushService({required PushProvider provider, required AuthRepository repo}) : _provider = provider, _repo = repo;

  final PushProvider _provider;
  final AuthRepository _repo;
  final _hints = StreamController<PushHint>.broadcast();
  final _subs = <StreamSubscription<Object?>>[];
  String? registered;

  Stream<PushHint> get hints => _hints.stream;

  @override
  void onInit() {
    super.onInit();
    _subs
      ..add(_provider.tokenRefreshes.listen((t) => unawaited(_register(t))))
      ..add(_provider.messages.listen((m) {
        final h = PushHint.fromData(m);
        if (h != null) _hints.add(h);
      }));
  }

  /// Call after sign-in. Failures are ignored: the live queue and polling still work.
  Future<void> registerCurrent() async {
    final t = await _provider.token();
    if (t != null) await _register(t);
  }

  Future<void> _register(String token) async {
    if (token == registered) return;
    try {
      await _repo.registerPushToken(token);
      registered = token;
    } on Object {
      // Retried on the next sign-in or token refresh.
    }
  }

  /// Sign-out: the next user must register their own token.
  void forget() => registered = null;

  @override
  void onClose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    unawaited(_hints.close());
    super.onClose();
  }
}
