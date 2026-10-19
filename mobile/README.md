# EMR-MR mobile apps

Two Flutter apps that share one core package:

| App | Users | `clientApp` | Folder |
| --- | --- | --- | --- |
| Crew | `DRIVER`, `PARAMEDIC` | `crew_app` | `apps/crew_app` |
| Citizen | `CITIZEN` | `citizen_app` | `apps/citizen_app` |

Both apps use `packages/emr_core` for the API client, session, offline outbox, design system, Arabic/English strings and the sign-in screens.

The API and UI contract is [`docs/mobile-app.md`](../docs/mobile-app.md). Build progress and design decisions are logged in [`PROGRESS.md`](PROGRESS.md).

## Run

Requires Flutter 3.41 / Dart 3.11. The repo is a pub workspace, so one `pub get` resolves all three packages.

```bash
cd mobile
flutter pub get
cd apps/crew_app        # or apps/citizen_app
flutter run --dart-define-from-file=../../env/dev.json      # Android emulator → http://10.0.2.2:8080
flutter run --dart-define-from-file=../../env/tunnel.json   # current Cloudflare tunnel
```

| Key in `env/*.json` | Meaning |
| --- | --- |
| `API` | Backend base URL |
| `WS` | STOMP endpoint (`ws://…/ws` or `wss://…/ws`) |
| `DEV_TOOLS` | `true` shows "Fill code (dev)" on the SMS screen, which reads `/dev/sms/latest`. Never set it in production |
| `TILES` | OpenStreetMap raster tile URL template. The default is `tile.openstreetmap.org`; production should point at our own tile server |

`trycloudflare.com` addresses change every time the tunnel restarts. When that happens, update `env/tunnel.json`.

Demo accounts are listed in [`docs/demo-accounts.md`](../docs/demo-accounts.md). Crew: `demo.driver1`, `demo.medic1`. Citizen: `demo.citizen`. All use the password `Demo-Pass-2026`.

## Test

```bash
cd packages/emr_core && flutter test     # API, session, outbox, design system, auth flows
cd apps/crew_app     && flutter test     # PIN, job state machine, live/GPS, patient care, e2e
cd apps/citizen_app  && flutter test     # SOS rules, requests, family/history, sign-up, e2e
flutter analyze                          # in each package; the lints are strict
```

There is also a read-only smoke test against a real backend. It never creates SOS requests or changes job state:

```bash
cd packages/emr_core
flutter test test/live --dart-define=LIVE_API=https://<backend-host>
```

After changing models or Retrofit interfaces, regenerate the code with `cd packages/emr_core && dart run build_runner build`.

## Architecture

```
emr_core/lib/src/
  api/        ApiClient (one Dio), AuthInterceptor, ApiError, Retrofit APIs, idempotency keys
  models/     json_serializable models, JobStatus state machine
  storage/    SecureStore (Keychain/Keystore), KeyValueStore (AES-encrypted Hive CE)
  services/   SessionService, OutboxService, ConnectivityService, DeviceService, PushService
  auth/       AuthFlow (the only place that navigates on session events), screens, controllers
  ui/         tokens, theme, widgets (AppButton, PriorityPill, StatusChip, SyncBar, SwipeToConfirm …)
  i18n/       AppTranslations (ar default, en), LocaleService
  bootstrap.dart  bootstrapCore() registers every service; EmrApp is the root widget
apps/<app>/lib/
  app/        routes, translations, flow config, register<App>Services()
  data/       repository (controllers never call Retrofit directly)
  services/   app-only services (crew: PIN, lock, GPS, STOMP live queue; citizen: SOS locator)
  modules/    feature folders: controller + view, wired through GetX route bindings
```

Rules the code follows:

- **Controllers → repositories → API.** Platform pieces (storage, location, connectivity, STOMP, push, HTTP adapter) sit behind interfaces. Tests replace them with fakes, so most tests run the real controllers, repositories, session and interceptor against a fake HTTP adapter.
- **Services never navigate.** They emit events (`SessionEnded`, `UpdateRequired`), and `AuthFlow` turns those into routes.
- **One Dio.** The interceptor adds the token. On `401 UNAUTHORIZED` it does one shared refresh and replays the request. A refresh that can't reach the server keeps the session, because the crew may simply be offline. `DEVICE_BLOCKED`, a revoked session or a disabled account wipes all local data. The token is also refreshed 60 seconds before it expires.
- **Offline outbox (crew).** Every crew write is queued in order on encrypted disk. Each retry sends the same `Idempotency-Key` and the same body. Network errors, 5xx and 429 leave the item in place to retry later. Other 4xx responses drop the item and the crew is told. A later item can use an earlier item's server id through `{ref:name}`, so a paramedic can register a patient and record vitals with no network. Offline GPS points are merged into batches of up to 500.
- **Optimistic job steps.** A status change shows at once and records the time the button was pressed. While a step is still queued, a stale server copy never moves the screen backwards.
- **Data at rest.** Tokens and the PIN verifier live in Keychain/Keystore. Only a salted PBKDF2 verifier is stored for the PIN, never the PIN itself. Cached jobs, patients and the outbox are AES-encrypted Hive, and are wiped on sign-out and when the phone is blocked.

## Offline map (OpenStreetMap)

The crew map draws OpenStreetMap raster tiles through `CachedTileProvider` (`apps/crew_app/lib/services/offline_map/`).

- **Viewed areas work offline.** Every tile the crew sees is saved on the phone, capped at 300 MB with the oldest deleted first. A saved tile is used for 30 days and refreshed when the phone is online. With no network, any saved copy is shown, however old.
- **Region download (Khartoum first, NFR-06).** Settings → Offline map downloads zoom levels 10–16 for greater Khartoum, about 9,000 tiles. The download can be resumed and cancelled, and it shows progress.
- **OSM tile usage policy.** The public `tile.openstreetmap.org` servers forbid bulk downloads and prefetching tiles that are not viewed. The app enforces this with `bulkDownloadAllowed()`: with the default URL, only caching of viewed tiles is active, and the region button is replaced by an explanation. To enable region downloads, set `TILES` to a tile server we host (for example from an OSM extract of Sudan) or a provider whose terms allow offline use. Tile requests send a proper User-Agent, never send the API token, and the map shows the "© OpenStreetMap contributors" attribution.

## Platform notes

- Android `minSdk 28` (Android 9+, SRS NFR-12). Plain HTTP is allowed only to `10.0.2.2` and `localhost` (`res/xml/network_security_config.xml`).
- **Crew** asks for fine, coarse and background location, a location foreground service, the camera (QR scan), wake lock and notifications. On iOS it uses the `location` background mode.
- **Push** is registered through `PushProvider`. Production FCM is not live on the backend yet, so the default `NoPushProvider` sends nothing. To enable push:
  1. Add `firebase_messaging`, plus `google-services.json` and `GoogleService-Info.plist`.
  2. Implement `PushProvider` with `FirebaseMessaging.instance` (`getToken`, `onTokenRefresh`, `onMessage`).
  3. Pass it as `CoreOverrides(push: …)`.

  A push is only a hint to re-read data.
- **Not built yet:**
  - A true lock-screen alarm for new jobs. It needs a full-screen-intent notification once push is live. Today the app alarms with sound and vibration while it is open.
  - A self-hosted tile server, needed before the Khartoum region download can be switched on (see Offline map).
  - Offline turn-by-turn routing (OSRM). Directions currently open the phone's maps app.
  - The danger score (waiting for clinical sign-off).
  - Refusal forms and close reasons (no API yet).
