# Change Log

## 2026-10-20 — Field-test fixes M1–M5 and the client's paramedic notes

Source: `docs/EMR-MR mobile field-test fixes (M1-M6).md`, `docs/MOBILE-API.md` and the client notes. Backend gaps are in [`mobile/BUGS.md`](mobile/BUGS.md).

### Crew app
- **M1 Handover** (`modules/handover/handover_view.dart`): "Hand over the patient" card from `leaving_scene`; per-patient summary prefilled with the last vitals and treatments; `POST /handovers` through the outbox (offline patients use the `{ref:}` id); "Job completed" is disabled until every patient has a handover; `409 HANDOVER_REQUIRED` opens the screen instead of a toast. A driver with a paramedic on the shift does not see it (hint only).
- **M2 End without transport** (`modules/job/no_transport_view.dart`): six reasons, note (required for `refused`), confirm, then `noTransportReason`/`note` on the status call, only from `on_scene`.
- **M3 Medicine picker + Not sent list**: searchable Arabic/English picker (`GET /medicines`, cached, sent as `code`); refused clinical writes (patient, vitals, treatment, handover) are kept in a "Not sent" list with the server message, "Not saved" in the patient timeline, fix-and-resend or delete; the sync chip never says "all sent" while anything is in it; the cancelled-job notice says how many patient entries will be refused; oxygen or a diastolic alone is not a vitals measurement.
- **Client notes**: request history (on-phone), multi-select pre-arrival alerts (one alert per type), "Add vitals" in one tap (uses the only patient or registers an unknown one), handover before the driver can end the job.
- **M4**: 4.2 paramedic alone waits for a driver; 4.3 busy ambulance says "Join after this job ends"; 4.4 shift reloaded on pull-to-refresh and new job; 4.5 job reloaded every 10 s on a job; 4.6 alerts only when `me.features` has `feature.crew_alerts` (`404 FEATURE_DISABLED` = off); 4.7 number pad + 6-digit check + `SHIFT_CODE_NOT_FOUND`; 4.1 and 4.8 below.

### Shared (`emr_core`)
- Outbox keeps refused clinical writes (`rejected`, persisted, `retryRejected` / `discardRejected`); new `OutboxKind.handover`; `SyncState.rejected`.
- Models: `StatusBody.noTransportReason/note`, `NoTransportReason`, `HandoverBody`, `Medicine`, `Me.features`, `CitizenHistory`.
- M4.1 / M5.4: password 12–72 characters, not the username (hint text updated); Arabic name needs Arabic letters.
- M4.8: the dev "phone to read the code" is no longer prefilled with the username.

### Citizen app
- M5.1 medical history reads the four lists as four sections (visits newest first); M5.2 closed request shows only received/closed; M5.3 "keep your phone free" hidden once closed; M5.4 sign-up checks.

### Follow-up: new backend fields (rechecked against the Swagger)
- Crew request history now comes from `GET /crew/jobs` (any phone, with the case's closing reason); the first page is cached for offline. The on-phone-only history was removed.
- `GET /crew/job` → `handovers`: patients show "Received by the ER" once confirmed; handovers sent from another phone are listed; a driver with a paramedic has "Job completed" disabled until the paramedic's handover is on the job.
- Job reads no longer wait for the GPS start (it could sit on the Android notification-permission dialog and hold up every later job read).
- Citizen: closed requests show `reachedSteps` and `closingReasonAr/En`; history uses the published row fields (the fourth list is allergies and current medicines).
- `mobile/BUGS.md`: B1–B5 closed, B6 (phone in the login answer) still open.

### Tests (M6)
- Fixed the two stale crew tests (shift-started screen; fake server answers `GET /crew/shifts/current`; the journey test now runs as a driver, as only drivers get the alarm and the steps).
- New: `apps/crew_app/test/field_fixes_test.dart`, more cases in `crew_controller_test.dart`, `emr_core` outbox/model/validator tests, citizen history/closed-request/sign-up tests.

## 2026-10-18

### 1. API Response Logging in Debug Console
- **File modified**: [`mobile/packages/emr_core/lib/src/api/api_client.dart`](mobile/packages/emr_core/lib/src/api/api_client.dart)
- **Details**:
  - Replaced `_SafeLogInterceptor` with `_DebugLogInterceptor` (active when `kDebugMode` is true).
  - Logs HTTP method, URL path, and status code.
  - Automatically formats and prints the JSON response body (`[api] response:\n<formatted JSON>`) on successful requests.
  - Automatically formats and prints the error response body (`[api] error response:\n<formatted JSON>`) on failed requests.
  - Formats Maps, Lists, and JSON strings with 2-space indentation.
  - Safeguards against printing large binary payloads (e.g. byte arrays or images).

### 2. Remove "Alert the Hospital Before Arrival" from the Driver Side
- **File modified**: [`mobile/apps/crew_app/lib/modules/home/crew_home_view.dart`](mobile/apps/crew_app/lib/modules/home/crew_home_view.dart)
- **Details**:
  - Updated the active job view (`_JobPanel`) to restrict the pre-arrival alert section (`prearrival_alert`, `AlertGrid`) to paramedics only:
    ```dart
    if ((me?.isParamedic ?? false) && status != null && status != JobStatus.sent && !status.isClosed) ...[
      const SizedBox(height: Space.betweenCards),
      SectionHeader('prearrival_alert'.tr, subtitle: 'prearrival_alert_body'.tr),
      AlertGrid(onAlert: c.raiseAlert),
    ],
    ```
  - Drivers (`role: 'DRIVER'`) no longer see the "Alert the hospital before arrival" header or the grid of emergency alert buttons (Stroke, STEMI, Trauma, Sepsis, Cardiac Arrest, Obstetric, Other).
  - Paramedics (`role: 'PARAMEDIC'`) retain full access to pre-arrival hospital alerting and patient care.
  - Moved `final me = Get.find<SessionService>().me.value;` inside the `Obx` builder so role-based UI reacts dynamically to session updates.

### 3. Automated Tests & Verification
- **File modified**: [`mobile/apps/crew_app/test/crew_app_flow_test.dart`](mobile/apps/crew_app/test/crew_app_flow_test.dart)
- **Details**:
  - Added regression test `drivers with an active job see map and steps but NOT hospital alert or patient care` asserting that:
    - Drivers see the active job status, map, and step progression buttons.
    - Neither `Alert the hospital before arrival` nor `alert_stroke` is rendered for drivers.
    - `open_patients` (patient care) remains hidden for drivers.
  - Ran `flutter analyze`: **0 issues found** (strict lints clean).
  - Ran full test suite across all packages: **All 219 tests passing** (`emr_core`: 124, `crew_app`: 69, `citizen_app`: 26).

### 4. Change "Left the Scene" to "Transporting"
- **File modified**: [`mobile/apps/crew_app/lib/app/crew_translations.dart`](mobile/apps/crew_app/lib/app/crew_translations.dart)
- **Details**:
  - Updated `status_leaving_scene` label from `'Left the scene'` to `'Transporting'` in English.
  - Updated `status_leaving_scene` label from `'غادر الموقع'` to `'جاري النقل'` in Arabic.
  - The driver and crew app now display the status chip as "Transporting" ("جاري النقل") when en route from the scene to the destination hospital.

### 5. Uber-Style Full Screen Map for Drivers with Floating Cards & Controls
- **Files modified**:
  - [`mobile/apps/crew_app/lib/modules/job/job_widgets.dart`](mobile/apps/crew_app/lib/modules/job/job_widgets.dart)
  - [`mobile/apps/crew_app/lib/modules/home/crew_home_view.dart`](mobile/apps/crew_app/lib/modules/home/crew_home_view.dart)
- **Details**:
  - **Full-Screen Map Base**: Updated `JobMap` to support `isFullScreen: true` (edge-to-edge rendering without container borders/radii) and decoupled the turn-by-turn directions action.
  - **Floating Top Bar (`_FloatingTopBar`)**: A floating navigation bar with rounded corners and shadow displaying the shift indicator dot, "On shift" status, live sync status pill (`LiveSyncChip`), and the settings gear button.
  - **Floating Job Information Card (`_FloatingJobCard`)**: A sleek card floating on top of the map showing priority pill, status chip ("Transporting", "On the way", etc.), case number, chief complaint headline, and expandable destination details (hospital, landmark, directions).
  - **Floating Directions Button**: Elevated pill button (`directions` key) positioned above the bottom action card to launch Google Maps / turn-by-turn navigation.
  - **Floating Bottom Action Card (`_FloatingBottomCard`)**: Thumb-reachable action card with `SwipeToConfirm` for new jobs, status progression buttons (`AppButton` with `Key('step_...')`), and freshness timestamp.
  - **Paramedic Separation**: Paramedics (`role: 'PARAMEDIC'`) continue to use the comprehensive clinical scrollable view with patient care and pre-arrival alerts.


