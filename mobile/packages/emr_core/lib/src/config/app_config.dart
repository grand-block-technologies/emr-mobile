/// Which mobile app is running. Sent to the backend as `clientApp`.
enum ClientApp {
  crew('crew_app'),
  citizen('citizen_app');

  const ClientApp(this.wire);
  final String wire;
}

/// Build-time configuration. Values come from `--dart-define-from-file=env/<name>.json`.
class AppConfig {
  const AppConfig({
    required this.clientApp,
    required this.version,
    this.apiBaseUrl = const String.fromEnvironment('API', defaultValue: 'http://10.0.2.2:8080'),
    this.wsUrl = const String.fromEnvironment('WS', defaultValue: 'ws://10.0.2.2:8080/ws'),
    this.devTools = const bool.fromEnvironment('DEV_TOOLS'),
    this.tileUrlTemplate = const String.fromEnvironment('TILES', defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
    this.emergencyNumber = '999',
  });

  final ClientApp clientApp;

  /// Reported at login as `appVersion`; the server may answer `426 APP_UPDATE_REQUIRED`.
  final String version;
  final String apiBaseUrl;
  final String wsUrl;

  /// Debug-only helpers (fill the SMS code from `/dev/sms/latest`). Never true in production.
  final bool devTools;

  /// OpenStreetMap raster tiles. The public OSM servers allow caching viewed tiles but forbid
  /// bulk/region downloads; point this at a tile server you run to enable offline regions.
  final String tileUrlTemplate;

  /// Call-centre number shown when the network is down. Admin-configurable on the server later.
  final String emergencyNumber;
}
