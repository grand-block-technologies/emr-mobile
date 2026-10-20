# Mobile API guide: crew app and citizen app
 
For mobile developers starting on the **crew app** (drivers, paramedics) and the
**citizen app**. Every example below was recorded from the real backend (development
stack, backend `2cfb801`, 2026-10-13) using the demo accounts in
[DEMO-ACCOUNTS.md](DEMO-ACCOUNTS.md). Tokens and IDs are shortened.
 
## 0. What is ready, and what is not
 
| Area | State |
| --- | --- |
| Crew and citizen endpoints | Built and covered by end-to-end tests (journeys J1–J17). Safe to build screens and flows against. |
| Login, refresh, logout, password | Typed contract: [openapi-shared.json](openapi-shared.json). |
| Live crew job queue (`/user/queue/job`) | Typed contract: [asyncapi-live.json](asyncapi-live.json). |
| Typed contract for crew/citizen endpoints | **Not yet.** No `openapi-crew.json` / `openapi-citizen.json`; responses below are documented from real traffic. Do not generate a client from Swagger for these endpoints yet; shapes may gain fields (never lose) when the contract is published. |
| Field-level errors (`fieldErrors`) | On login/auth and on request-body validation (e.g. a missing `lon`); not yet on every business rule. |
| Push notifications | **Not implemented for production.** The backend queues a push for a new crew job and citizen status changes, but the FCM sender is a stub; development uses a fake. Until it lands, use the live queue (crew) and polling (both). |
| SMS | Development uses a fake SMS service (`GET /dev/sms/latest`). Production Zain SMS is not configured. |
 
## 1. Basics
 
- **Base URL (dev):** `http://localhost:8080`. All paths start with `/api/v1`.
- **JSON** in and out; times are ISO-8601 UTC (`2026-10-13T05:44:47Z`). Send UTC.
- **Auth:** `Authorization: Bearer <accessToken>` on every call except login, verify,
  refresh, forgot/reset password and citizen sign-up.
- **Languages:** every error has `message_ar` and `message_en`; status texts for citizens
  come in both languages (`statusAr`, `statusEn`). Pick by the user's `preferredLanguage`.
 
### Errors
 
Every error has the same body:
 
```json
{"code":"HANDOVER_REQUIRED","message_ar":"أرسل تسليم المريض قبل إنهاء المهمة.",
"message_en":"Send the patient handover before finishing the job.",
"reference":"48cb62ba-…","time":"2026-10-13T05:44:46.476Z"}
```
 
Validation failures may add `fieldErrors` (show each under its field):
 
```json
{"code":"VALIDATION_ERROR", "…":"…",
"fieldErrors":[{"field":"lon","code":"REQUIRED","message_ar":"هذا الحقل مطلوب.","message_en":"This field is required."}]}
```
 
Branch on `code`, show `message_ar`/`message_en`, and show `reference` only for
unexpected errors (support uses it). The full code list is the `ApiError.code` enum in
[openapi-shared.json](openapi-shared.json).
 
### Offline writes and `Idempotency-Key`
 
Crew writes that may be retried after a network drop **require** `Idempotency-Key`
(confirm, status, GPS); patient writes and citizen SOS accept it. Rules:
 
- One new random key (UUID) per user action; reuse the **same key and same body** when retrying.
- A replay returns the original result (status 200, same content) and changes nothing.
- Same key with a different body: `409 IDEMPOTENCY_CONFLICT`. Bad key format: `400 IDEMPOTENCY_KEY_INVALID`
  (allowed: `[A-Za-z0-9._:-]{1,128}`).
- Queue offline actions in order and send them in order when back online. Status times
  are the real times the crew pressed the button (`statusTime`), not the upload time.
 
## 2. Login (both apps)
 
Mobile login always sends `clientApp`, a stable `deviceId` and `appVersion`. Generate
`deviceId` once per install (UUID) and keep it; the account is bound to that device and
an admin or hospital ER can block it if the phone is lost.
 
| Field | Crew app | Citizen app |
| --- | --- | --- |
| `deviceType` | `mobile` | `mobile` |
| `clientApp` | `crew_app` | `citizen_app` |
| `appVersion` | e.g. `1.0.0` (`x.y.z`) | same |
 
**Step 1, password:** `POST /api/v1/auth/login`
 
```json
{"username":"demo.driver1","password":"Demo-Pass-2026","deviceType":"mobile",
"clientApp":"crew_app","deviceId":"413d6f2a-…","appVersion":"1.0.0"}
```
→ `200 {"step":"sms_code","challengeId":"72c05e9d-…","expiresAt":"2026-10-13T05:49:42Z","accessToken":null,"refreshToken":null,"mustChangePassword":null}`
and an SMS code is sent. The crew and citizen apps always get `step: "sms_code"` (settings
`auth.sms_second_factor.crew_app|citizen_app` are on). Only the staff web portal signs in with the
password alone (`step: "signed_in"`); handle that value anyway so a future setting change needs no release.
 
**Step 2, SMS code:** `POST /api/v1/auth/verify` `{"challengeId":"72c05e9d-…","code":"193903"}`
→ `200 {"accessToken":"eyJ…","refreshToken":"4H3a8ZML…","mustChangePassword":false}`
 
- Access token lives **15 minutes**; the mobile session (refresh token) lives **7 days**.
- Keep the refresh token in the platform secure store (Keychain / Android Keystore).
- `POST /api/v1/auth/resend` `{"challengeId"}` sends a new code (after 60 s, at most 3 times).
- `mustChangePassword: true` → only `POST /api/v1/auth/change-password`
  (`{"oldPassword","newPassword"}`: 12–72 characters with letters and digits, not containing the username,
  not a common password; else `400 PASSWORD_POLICY`) is allowed until changed.
 
**Refresh:** `POST /api/v1/auth/refresh` `{"refreshToken":"4H3a8ZML…"}` → `200 {"accessToken":"eyJ…"}`
(refresh token is unchanged). Refresh before expiry or on `401 UNAUTHORIZED`.
 
**Logout:** `POST /api/v1/auth/logout` → `204`.
**Forgot password:** `POST /api/v1/auth/forgot-password` `{"username"}` → `202` with a
`challengeId`; then `POST /api/v1/auth/reset-password` `{"challengeId","code","newPassword"}` → `204`.
 
**Current user:** `GET /api/v1/me`
 
```json
{"id":"…-0000000000d8","username":"demo.driver1","fullNameAr":"سائق الرياض","fullNameEn":"Driver Riyadh",
"role":"DRIVER","preferredLanguage":"ar",
"scopes":[{"scopeType":"hospital","stateId":null,"hospitalId":"…-000000000e01","type":"hospital"}],
"stateCodes":["KH"],"mustChangePassword":false}
```
(`type` is deprecated; use `scopeType`.)
 
### Login errors to handle
 
| HTTP / code | Meaning | App behaviour |
| --- | --- | --- |
| 401 `INVALID_CREDENTIALS` | Wrong username/password | Show message |
| 400 `INVALID_CODE`, `CODE_EXPIRED`, `INVALID_CHALLENGE` | Bad or old SMS code | Ask again / resend |
| 423 `ACCOUNT_LOCKED` | 5 wrong passwords; locked 30 min | Show message; admin can unlock |
| 429 `SMS_RATE_LIMIT` | Max 5 SMS codes per user per hour | Show message; do not retry in a loop |
| 429 `AUTH_RATE_LIMIT`, `RESEND_WAIT`, `RESEND_LIMIT` | Too fast | Wait |
| 426 `APP_UPDATE_REQUIRED` | `appVersion` below the minimum setting | Force update screen |
| 401 `DEVICE_BLOCKED` / `DEVICE_INVALID` | Phone was blocked, or the device binding is broken | Log out, show message |
| 403 `ACCOUNT_DISABLED` | Account disabled by admin | Show message |
| 403 `WRONG_CLIENT_APP` / `FORBIDDEN` | Wrong app for this role (e.g. a citizen in the crew app) | Show "use the other app" |
| 503 `SMS_UNAVAILABLE` | SMS service down | Retry later |
 
**Device binding and shared test phones.** In production a `deviceId` belongs to the first account that logs in
with it; another account on the same phone gets `401 DEVICE_INVALID` (the phone must be reset or the app
reinstalled, which makes a new `deviceId`). On the **dev backend only** (`auth.dev-device-switch`, added
2026-10-18), logging in with another account moves the phone to that account: the previous account's
sessions on that phone end and its push token and PIN are cleared. A blocked phone stays blocked
(`DEVICE_BLOCKED`). Keep one `deviceId` per app install, stored securely; do not generate a new one per login.
 
## 3. Crew app (DRIVER, PARAMEDIC)
 
### 3.1 Device setup after login
 
| Action | Call | Response |
| --- | --- | --- |
| Register push token (FCM) | `PUT /api/v1/devices/current/push-token` `{"pushToken":"…"}` (≤ 4096 chars) | `{"registered":true}` |
| Set or change the offline PIN | `PUT /api/v1/crew/pin` `{"pin":"4321"}` (add `"oldPin"` to change) | `{"saved":true}` |
| Check the PIN | `POST /api/v1/crew/pin/verify` `{"pin":"4321"}` | `{"verified":true}`; wrong: `401 PIN_INVALID`; 5 wrong: `423 PIN_LOCKED` for 15 min |
| My devices | `GET /api/v1/devices` | `[{"id","clientApp","appVersion","blockedAt","createdAt","lastSeenAt","pushRegistered"}]` |
 
PIN is 4–8 digits and is checked by the server; the app uses it to unlock itself while
offline (keep only a verifier locally, never the PIN in clear).
 
### 3.2 Shift
 
Scan the QR code on the ambulance, **or type its 6-digit shift code** (printed under the QR; added 2026-10-18).
Send exactly one of `qrToken` or `code`.
 
| Action | Call | Response |
| --- | --- | --- |
| Start a shift | `POST /api/v1/crew/shifts` `{"qrToken":"7d04a647…"}` or `{"code":"482913"}` | `{"id":"<shiftId>","ambulanceId":"…"}` |
| Join the crew's current shift | `POST /api/v1/crew/shifts/current/join` `{"qrToken":"…"}` or `{"code":"482913"}` | same as start |
| End my shift | `POST /api/v1/crew/shifts/current/end` | `{"shiftId":"…","ended":true}` |
| Am I on a shift? | `GET /api/v1/crew/shifts/current` | `{"shift": <shift>}` or `{"shift": null}` |
 
`<shift>` (also the answer of start and join, since 2026-10-18):
 
```json
{"id":"…","ambulanceId":"…","plateNumber":"DEMO-11","hospitalId":"…",
"hospitalNameAr":"مستشفى الرياض التجريبي","hospitalNameEn":"Riyadh Demo Hospital","startedAt":"2026-10-18T08:02:11Z",
"crew":[{"userId":"…","role":"driver","fullNameAr":"…","fullNameEn":"…","phone":"+2499…","joinedAt":"…","me":false},
         {"userId":"…","role":"paramedic","fullNameAr":"…","fullNameEn":"…","phone":"+2499…","joinedAt":"…","me":true}]}
```
`crew` lists who is on the shift now, in joining order; `me` marks the caller. Call `GET /crew/shifts/current` after login
to choose between the start screen and the shift screen.
 
- `code` is exactly 6 digits. It is looked up only among the ambulances of the crew member's own hospital.
- Show a number keypad with 6 boxes, and a "Scan QR instead" button.
- **Development backend only:** `000000` means "the first free ambulance in my hospital" for start, and "the first
  shift in my hospital waiting for a partner" for join. Production refuses `000000` (`404 NOT_FOUND`).
- Check `GET /api/v1/crew/shifts/current` first: the demo crew (`demo.driver1`, `demo.medic1`) are
  already on the DEMO-11 shift in the demo data, so start gives `SHIFT_ALREADY_ACTIVE` until they end it.
 
Errors:
- `400 SHIFT_ALREADY_ACTIVE`: already on a shift (checked first).
- `400 SHIFT_FULL`.
- `400 SHIFT_HAS_JOB`: cannot end with an open job.
- `400 AMBULANCE_UNAVAILABLE`.
- `400 VALIDATION_ERROR`: not exactly one of `qrToken`/`code`, or the code is not 6 digits.
- `404 SHIFT_CODE_NOT_FOUND` (typed code) or `404 NOT_FOUND` (QR): unknown code. Dev `000000`: `404 NO_FREE_AMBULANCE`.
- `400 AMBULANCE_UNAVAILABLE` on join: the ambulance is on a job; a partner can join only between jobs.
- Type the code with a number pad and check `^[0-9]{6}$` before sending.
 
### 3.3 Current job
 
`GET /api/v1/crew/job`
 
No job: `{"job":null}`. With a job:
 
```json
{"dispatchId":"1ab18142-…","caseId":"913f17f5-…","status":"sent","caseNumber":"KH-2026-000109",
"priority":"P1","complaint":"Demo: breathing difficulty","directions":null,
"lon":32.56,"lat":15.55,"pinRadiusM":300,"landmarkAr":null,"landmarkEn":null,
"destinationHospitalId":"…-000000000e01","hospitalAr":"مستشفى الرياض التجريبي","hospitalEn":"Riyadh Demo Hospital",
"caseCreatedAt":"2026-10-18T07:50:12.795Z","sentAt":"2026-10-18T07:50:12.983Z",
"confirmDeadlineAt":"2026-10-18T07:51:12.983Z","confirmedAt":null,
"statusTime":"2026-10-18T07:50:12.983Z","serverTime":"2026-10-18T07:50:13.104Z"}
```
 
The pin is approximate within `pinRadiusM` metres; show the circle, not just a point.
 
**Times** (all UTC, ISO-8601, from the server clock; added 2026-10-18):
 
| Field | Meaning | Show it as |
| --- | --- | --- |
| `caseCreatedAt` | When the call centre opened the case | "Call 12 min ago" |
| `sentAt` | When this job was sent to the ambulance | "Sent 08:50" (local time) |
| `confirmDeadlineAt` | Confirm before this time, or the hospital and call centre are alerted | Countdown on the alarm screen |
| `confirmedAt` | When the crew confirmed; `null` until then | — |
| `statusTime` | When the current `status` started (`sentAt` until the first change) | "On scene for 6 min" |
| `serverTime` | Server time when this answer was made | Use it for every countdown, never the phone clock |
 
Count down with the server's clock: at each `GET /crew/job`, store `offset = serverTime − phone time`.
Then remaining time = `confirmDeadlineAt − (phone time + offset)`. Phones in the field often have the wrong time.
 
**How the app learns about a new job:**
1. Live (preferred while the app is open): STOMP over WebSocket at `/ws`, subscribe to
   `/user/queue/job`; events `job.new` and `job.cancelled` with
   `{"type","dispatchId","userId","time"}` → then call `GET /api/v1/crew/job`.
   Connection rules (heart-beats, receipts, token expiry) are in [asyncapi-live.json](asyncapi-live.json).
2. Polling `GET /api/v1/crew/job` (e.g. every 15–30 s on shift) as a fallback.
3. Push (`job.new`) once production FCM is implemented.
 
If the crew does not confirm in time the hospital is alerted and phones the crew.
 
### 3.4 Confirm and move through the job
 
All three calls need `Idempotency-Key`.
 
**Confirm:** `POST /api/v1/dispatches/{dispatchId}/confirm` (no body)
 
```json
{"id":"1ab18142-…","caseId":"913f17f5-…","hospitalId":"…","ambulanceId":"…",
"status":"confirmed","confirmedVia":"app","confirmedAt":"2026-10-13T05:44:46.434Z","statusTime":null}
```
 
**Status:** `POST /api/v1/dispatches/{dispatchId}/status` `{"status":"en_route","statusTime":"2026-10-13T05:44:47Z"}`
→ same shape with the new `status` and `statusTime`.
 
Allowed order (the server refuses anything else):
 
```
sent → confirmed → en_route → on_scene → leaving_scene → at_hospital → completed
                                  └──────────────→ completed   (treated at the scene, no transport)
```
 
- `statusTime` is the phone's time of the step. A phone with a wrong clock is not refused (2026-10-20): a time before the
  previous step is moved to the previous step, and a time more than 5 minutes ahead is moved to the server's now.
  Still apply the server time offset (`Date` header) so the record is right.
 
**Finishing a job (2026-10-18): the case now closes by itself, so the crew must finish it properly.**
 
| Situation | What the crew app does | Result |
| --- | --- | --- |
| Patient taken to hospital | At `at_hospital`, the paramedic (or the driver when alone on the shift) registers the patient (if not yet) and sends the handover (`POST /api/v1/handovers`, section 3.5). Then `completed`. | Without a handover, `completed` answers `409 HANDOVER_REQUIRED`. When the ER confirms the handover and the job is completed (either order), the case closes as `taken_to_hospital`. |
| No transport | From `on_scene`: `{"status":"completed","statusTime":"…","noTransportReason":"refused","note":"…"}` | The case closes at once with that reason. |
 
`noTransportReason` is one of `treated_at_scene`, `refused`, `died_at_scene`, `patient_not_found`, `cancelled_by_caller`, `false_alarm`
(`note` is optional, up to 2000 characters). It is required to complete from `on_scene` and refused on any other step
(`400 VALIDATION_ERROR` on the field). Show these as large buttons on an "End without transport" screen. For `refused`,
ask for a short note.
- A cancelled job arrives as `job.cancelled` (live) and the job disappears from `GET /crew/job`. Since 2026-10-20 this
  also happens when the call centre closes the case (for example a false alarm) while the ambulance is on the way.
  Patient writes still in the outbox for that job then get `403 PATIENT_ACCESS_DENIED`: tell the paramedic, do not drop them silently.
 
**GPS:** `POST /api/v1/crew/gps` with a batch of 1–500 points (`Idempotency-Key` required):
 
```json
[{"clientPointId":"f711e7bc-…","recordedAt":"2026-10-13T05:44:48Z","lon":32.552,"lat":15.542,
  "accuracyM":6,"speedKmh":42,"headingDeg":45}]
```
→ `{"saved":2,"duplicates":0,"skipped":0}`. `clientPointId` is a UUID per point; resent points are
counted as `duplicates`, never stored twice. Points more than 5 minutes ahead of the server's clock are
`skipped` (2026-10-20); the rest of the batch is saved. Send while on a job (phone GPS fills gaps
when the ambulance tracker is silent); batch every 15 s on a job, 60 s idle (server
settings `gps.interval_on_job_seconds` / `gps.interval_idle_seconds`).
 
**Live tracking** (2026-10-18): the newest point of each batch is shown live on the call-centre and hospital
maps (`ambulance.position`, `source: "phone"`) when it is under 2 minutes old and the vehicle tracker has nothing
newer. So on a job:
- Send each batch as soon as it is due. Do not hold points back to save data.
- Keep sending when the app is in the background: use an Android foreground service with a visible
  "On a job – sharing location" notification.
- Points older than 2 minutes (sent after a signal gap) are saved for the route but do not move the live dot.
 
**Pre-arrival alert** (new 2026-10-14): warn the receiving ER about a time-critical patient.
`POST /api/v1/dispatches/{dispatchId}/alerts` with `{"type":"stroke","note":"FAST positive 10:05"}`.
`type`: `stroke`, `stemi`, `trauma`, `sepsis`, `cardiac_arrest`, `obstetric` or `other`. Only crew on the job's
shift may send it (`403 OUTSIDE_SCOPE` otherwise); `409 DISPATCH_NOT_ACTIVE` after the job ended. The ER sees it
on its arrivals board with the ambulance ETA and acknowledges it. Offer it as one large button per type on
the job screen.
 
### 3.5 Patient care on scene (PARAMEDIC; DRIVER when alone)
 
Allowed only while the crew's job for that case is open; after `completed` the
paramedic gets `403 PATIENT_ACCESS_DENIED`. Send `Idempotency-Key` on each.
 
A driver alone on the shift (no paramedic on it, see `crew` in the shift view) may register the patient
(`POST /patients`) and send the handover (`POST /handovers`), so the job can finish. With a paramedic on the
shift the driver gets `403 PARAMEDIC_ON_SHIFT`. Vitals and treatments stay paramedic only.
 
**Register a patient** (temporary when the identity is unknown): `POST /api/v1/patients`
 
```json
{"temporary":true,"temporaryLabel":"Unknown adult male","estimatedAge":40,
"fullNameAr":"مجهول","fullNameEn":"Unknown","sex":"male"}
```
→ `{"id":"d3927958-…","firstRecordStatus":"not_started"}`.
Known patient: send `nationalId` (6–15 digits), `fullNameAr` (required), `sex`
(`male|female|unknown`), optional `fullNameEn`, `birthDate`, `phone`, `motherName`.
 
**Save or correct the patient's name and details** (added 2026-10-19), for example when an unknown patient
gives their name: `PATCH /api/v1/patients/{id}` with any of `fullNameAr`, `fullNameEn`, `sex`, `birthDate`,
`estimatedAge`, `phone`, `motherName`, `temporaryLabel` (at least one). → `{"id":"…","fields":["fullNameAr","phone"]}`.
The patient stays "temporary" until a national ID is added (`POST /api/v1/patients/{id}/national-id`).
 
**Observation:** `POST /api/v1/patients/{id}/observations`
 
```json
{"observedAt":"2026-10-13T05:44:52Z","caseId":"913f17f5-…","heartRate":112,"respRate":26,"spo2":89,
"onOxygen":false,"systolic":135,"diastolic":85,"consciousness":"A","painScore":3}
```
At least one measurement. Limits: heart rate 20–250, resp. rate 2–80, SpO₂ 40–100,
systolic 40–300 and diastolic 20–200 (diastolic < systolic), temperature 25–45 °C,
glucose 0.5–60 mmol/L, pain 0–10, consciousness `A|C|V|P|U` (ACVPU). Out of range:
`400 DATABASE_RULE`.
 
**Treatment:** `POST /api/v1/patients/{id}/treatments`
 
```json
{"givenAt":"2026-10-13T05:44:53Z","caseId":"913f17f5-…","kind":"procedure",
"name":"Oxygen by mask","dose":"10 L/min","route":"inhaled"}
```
→ `{"id":123}`. `kind`: `medicine|procedure|oxygen|fluid|other`; `route`:
`oral|iv|im|sc|inhaled|topical|rectal|other`.
 
For `kind: "medicine"`, `name` must be a medicine from `GET /api/v1/medicines` →
`[{"code":"ASPIRIN","nameAr":"أسبرين","nameEn":"Aspirin"}, …]` (added 2026-10-20). Show a picker and send the `code`;
the English or Arabic name is also accepted and stored as the code. Anything else is `400 MEDICINE_INVALID`.
Other kinds keep free text.
 
Pre-arrival alerts (`POST /dispatches/{id}/alerts`) can be switched off by the admin: then `404 FEATURE_DISABLED`.
`GET /me` lists the features that are on in `features`; hide the alert buttons unless it has `feature.crew_alerts`.
 
To correct an entry, send a new one with
`correctsId` = the old entry's id (records are never edited).
 
### 3.6 Offline map (self-hosted tiles)
 
Map tiles come from our own tile server, not the public OpenStreetMap server (added 2026-10-18; ops guide `docs/ops/MAP-TILES.md`).
 
| Item | Value |
| --- | --- |
| Raster tile URL | `{TILES_BASE}/styles/basic-preview/256/{z}/{x}/{y}.png` (256 px PNG). Dev: `TILES_BASE` = `http://<dev-host>:8081` |
| Zoom | Data to 14; the server draws up to 18 from it. Use 10–16 for offline |
| Khartoum download box | lon 32.35–32.75, lat 15.40–15.80, zoom 10–16: about 7,600 tiles, roughly 150–250 MB |
| Login | None. Tiles hold only public map data |
| Labels | Latin script for now (for example "Wad Abdun"). Arabic labels come later with a style change |
| Attribution | Show "© OpenStreetMap contributors, © OpenMapTiles" on the map |
 
Rules for the region download:
 
- Download on Wi-Fi only, after the user starts it. Never download in the background on mobile data.
- Run at most 4 requests at a time and retry failed tiles. The server is shared with the call centre.
- Store tiles on the device with their `z/x/y` key and use them when offline (`flutter_map` with a cached tile provider works).
- Refresh the region monthly. The server data is rebuilt monthly.
 
### 3.7 Lost phone
 
An admin or the hospital ER can block the device: every session ends (`401`) and that
`deviceId` can no longer log in. The app should log out and show the message.
 
## 4. Citizen app (CITIZEN)
 
### 4.1 Sign up
 
1. `POST /api/v1/citizen/sign-up/start` `{"phone":"+249973743354"}` →
   `{"challengeId":"47d954f0-…","expiresAt":"…"}` and an SMS code.
2. `POST /api/v1/citizen/sign-up/finish`
 
```json
{"challengeId":"47d954f0-…","code":"611855","nationalId":"49412543746",
"fullNameAr":"مواطن تجريبي","fullNameEn":"Demo Signup","password":"Signup-Pass-2026"}
```
→ `{"id":"8c4d2c1c-…","identityStatus":"phone_verified","linkedPatient":false}`.
Then log in as in section 2 (username = phone number, `clientApp: citizen_app`).
 
Errors: `409 CITIZEN_PHONE_ACCOUNT_EXISTS`, `409 CITIZEN_ID_ACCOUNT_EXISTS`,
`429 SIGNUP_RATE_LIMIT`, `400 INVALID_CODE` / `CODE_EXPIRED`.
 
### 4.2 Profile
 
`GET /api/v1/citizen/me`
 
```json
{"fullNameAr":"مواطن تجريبي","fullNameEn":"Demo Citizen","phone":"+249912345003",
"preferredLanguage":"ar","identityStatus":"phone_verified","linkedPatient":true}
```
`identityStatus`: `phone_verified` → `id_card_verified` (verified in person at a hospital) or `suspended`.
 
### 4.3 SOS
 
`POST /api/v1/citizen/requests` (send `Idempotency-Key` so a retry does not create a second request)
 
```json
{"lon":32.561,"lat":15.552,"accuracyM":8,"note":"My neighbour fell"}
```
→ `{"id":"18f5bb00-…","statusCode":"received"}`. `lon`/`lat` required; `accuracyM` 0–100000; `note` ≤ 2000.
 
Errors: `429 CITIZEN_OPEN_REQUESTS` (already has open requests), `403 CITIZEN_SUSPENDED`
(account suspended after prank calls), `400 VALIDATION_ERROR` with `fieldErrors`.
 
The call centre phones the citizen back; the app is not a chat.
 
### 4.4 Follow a request
 
`GET /api/v1/citizen/requests?page=0&size=10`
 
```json
{"content":[{"id":"18f5bb00-…","startedAt":"2026-10-13T05:44:47Z","statusCode":"received",
  "statusAr":"تم استلام طلبك، سيتصل بك مركز البلاغات","statusEn":"Request received; the call centre will call you",
  "updatedAt":"2026-10-13T05:44:47Z"}],"page":0,"size":10,"hasNext":false,"totalElements":null}
```
 
`GET /api/v1/citizen/requests/{id}`
 
```json
{"statusCode":"ambulance_coming","statusAr":"سيارة الإسعاف في الطريق إليك","statusEn":"The ambulance is on its way",
"hospitalNameAr":"…","hospitalNameEn":"…","updatedAt":"…"}
```
 
| `statusCode` | English text |
| --- | --- |
| `received` | Request received; the call centre will call you |
| `finding_hospital` | Finding a hospital |
| `hospital_accepted` | A hospital accepted your request |
| `ambulance_coming` | The ambulance is on its way |
| `ambulance_arrived` | The ambulance has arrived |
| `to_hospital` | On the way to the hospital |
| `closed` | Request closed |
 
Show `statusAr`/`statusEn` from the server rather than your own words. There is no live
channel for citizens: poll the open request (e.g. every 10–15 s while the screen is open);
push for status changes comes when production FCM is implemented.
 
### 4.5 Family and medical history
 
- Add a child or ward: `POST /api/v1/citizen/dependants`
  `{"childNationalId":"29990001234","relation":"child"}` (`child|legal_guardian`) →
  `{"id":"ad0ee538-…","status":"pending"}`. The link is verified in person at a hospital.
- History: `GET /api/v1/citizen/history?page=0&size=10` (add `patientId=` for a verified
  family member). Until the citizen's ID card (and the family link) has been verified at a
  hospital: `403 CITIZEN_HISTORY_NOT_VERIFIED`; show that message with guidance.
 
## 5. Demo accounts (development only)
 
| App | Username | Password | Notes |
| --- | --- | --- | --- |
| Crew | `demo.driver1` | `Demo-Pass-2026` | Riyadh hospital; ambulance DEMO-11 QR from the admin portal (`GET /api/v1/ambulances/{id}/qr.png`) |
| Crew | `demo.medic1` | `Demo-Pass-2026` | Paramedic, Riyadh |
| Crew | `demo.driver2`, `demo.driver3` | `Demo-Pass-2026` | Thawra, Haj Yousif |
| Citizen | `demo.citizen` | `Demo-Pass-2026` | Phone `+249912345003` |
 
SMS codes in development: `GET /dev/sms/latest?phone=%2B249999990108` (URL-encode `+`).
To get a job onto a crew phone during development, someone must run the call-centre and
hospital-ER steps (create case → send to hospital → accept → dispatch the ambulance), for
example from the web portals or the backend smoke script.
 
## 6. Still to come (backend)
 
1. Typed `openapi-crew.json` and `openapi-citizen.json` with a live schema test (as for admin).
2. `fieldErrors` on every crew/citizen business rule.
3. Production push (FCM) for `job.new` and citizen status changes, with a documented payload.
4. Production Zain SMS configuration (crew and citizen login codes, SMS SOS). Web staff no longer need SMS.
 
 