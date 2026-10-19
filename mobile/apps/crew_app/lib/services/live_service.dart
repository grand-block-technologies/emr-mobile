import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:emr_core/emr_core.dart';
import 'package:get/get.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

/// `{type, dispatchId, userId, time}` on `/user/queue/job`.
class CrewEvent {
  const CrewEvent({required this.type, this.dispatchId});
  final String type;
  final String? dispatchId;

  static const known = {'job.new', 'job.cancelled'};

  /// Null for garbage or unknown types (the contract says: ignore unknown types).
  static CrewEvent? parse(String? body) {
    if (body == null) return null;
    try {
      final j = jsonDecode(body);
      if (j is! Map || j['type'] is! String || !known.contains(j['type'])) return null;
      return CrewEvent(type: j['type'] as String, dispatchId: j['dispatchId'] as String?);
    } on FormatException {
      return null;
    }
  }
}

/// Reconnect delays 1, 2, 4 … 30 s.
Duration liveBackoff(int attempt) => Duration(seconds: min(30, 1 << min(attempt, 5)));

/// Opens a STOMP connection. Abstract so tests can drive it without a socket.
abstract interface class StompConnector {
  /// Connects with [token]; calls [onConnected] once subscribed, [onEvent] for each frame body, [onError] with the ERROR `message`
  /// header, [onClosed] when the socket drops. Returns a function that closes the connection.
  void Function() connect({
    required String url,
    required String token,
    required void Function() onConnected,
    required void Function(String? body) onEvent,
    required void Function(String? message) onError,
    required void Function() onClosed,
  });
}

class StompDartConnector implements StompConnector {
  @override
  void Function() connect({
    required String url,
    required String token,
    required void Function() onConnected,
    required void Function(String? body) onEvent,
    required void Function(String? message) onError,
    required void Function() onClosed,
  }) {
    late final StompClient client;
    client = StompClient(
      config: StompConfig(
        url: url,
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        reconnectDelay: Duration.zero, // reconnects are ours: fresh token + backoff
        onConnect: (_) {
          client.subscribe(destination: '/user/queue/job', callback: (f) => onEvent(f.body));
          onConnected();
        },
        onStompError: (f) => onError(f.headers['message']),
        onWebSocketError: (_) => onClosed(),
        onWebSocketDone: onClosed,
      ),
    );
    client.activate();
    return client.deactivate;
  }
}

/// The crew's live job queue. Events only say "something changed": the job is always re-read
/// from `GET /crew/job`. Polling stays on as a safety net.
class LiveService extends GetxService {
  LiveService({required StompConnector connector, required SessionService session, required String url})
      : _connector = connector,
        _session = session,
        _url = url;

  final StompConnector _connector;
  final SessionService _session;
  final String _url;

  final connected = false.obs;
  final _events = StreamController<CrewEvent>.broadcast();
  Stream<CrewEvent> get events => _events.stream;

  void Function()? _close;
  StreamSubscription<SessionEvent>? _sessionSub;
  Timer? _retry;
  int _attempt = 0;
  bool _wanted = false;

  /// Starts (or keeps) the connection while on shift.
  void start() {
    _wanted = true;
    _sessionSub ??= _session.events.listen((e) {
      // Reconnect after every refresh so the socket never runs on an expired token.
      if (e is TokenRefreshed && _wanted) _reconnect(immediately: true);
    });
    if (_close == null) _connect();
  }

  void stop() {
    _wanted = false;
    _retry?.cancel();
    _disconnect();
  }

  void _connect() {
    final token = _session.accessToken;
    if (!_wanted || _close != null) return;
    if (token == null) {
      unawaited(_session.refreshAccessToken().then((_) => _scheduleRetry()));
      return;
    }
    _close = _connector.connect(
      url: _url,
      token: token,
      onConnected: () {
        connected.value = true;
        _attempt = 0;
        // Anything missed while disconnected: re-read the job.
        _events.add(const CrewEvent(type: 'live.connected'));
      },
      onEvent: (body) {
        final e = CrewEvent.parse(body);
        if (e != null) _events.add(e);
      },
      onError: (message) {
        _disconnect();
        if (message == 'UNAUTHORIZED') {
          // A successful refresh emits TokenRefreshed, which reconnects; only a failure retries here.
          unawaited(_session.refreshAccessToken().then((o) => o is Refreshed ? null : _scheduleRetry()));
        } else {
          _scheduleRetry();
        }
      },
      onClosed: () {
        _disconnect();
        _scheduleRetry();
      },
    );
  }

  void _disconnect() {
    final c = _close;
    _close = null;
    connected.value = false;
    c?.call();
  }

  void _reconnect({bool immediately = false}) {
    _disconnect();
    if (immediately) {
      _connect();
    } else {
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (!_wanted) return;
    _retry?.cancel();
    _retry = Timer(liveBackoff(_attempt++), () {
      if (_close == null) _connect();
    });
  }

  @override
  void onClose() {
    stop();
    unawaited(_sessionSub?.cancel());
    unawaited(_events.close());
    super.onClose();
  }
}
