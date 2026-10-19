# Change Log

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


