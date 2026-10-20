# EMR-MR mobile: field-test fixes (M1-M6)

Oct 20, 2026 · @houzifa Kroom

## How to use this prompt

On 2026-10-20 both apps (`emr-mobile` first commit `e737b62`) were tested live on an Android emulator against the real backend. The citizen journey works end to end. **The crew app cannot finish an ambulance job today**, so it is not ready for real crews. M1 to M3 are blockers; do them first, one pull request each, then M4 to M6.

What already works and must keep working: login, SMS code, password change, PIN, shift by typed code, live new-job alarm in under 3 s, swipe to confirm, status steps, map, pre-arrival alert, add patient, vitals, `job.cancelled` when the call centre closes the case, citizen sign-up, SOS, and the live request status.

The backend side is ready on `main` of `emr-mr-backend` (commit after `cda3fa6`). Read `docs/api/MOBILE-API.md`; sections 3.2, 3.4 and 3.5 were updated today.

Rules for every part:

- Use only fields and endpoints in `MOBILE-API.md`. A gap goes in the mobile `BUGS.md` and to the backend team; do not invent it.
- Arabic first, English second; check both, right-to-left and left-to-right.
- Show the backend's `message_ar` / `message_en` for errors you do not handle on purpose.
- Every write keeps going through the outbox with an `Idempotency-Key`; it must still work offline.
- Test against the dev backend with your own QA accounts, not the shared demo accounts.

## M1 (blocker): Handover screen at the hospital

Seen in the test: at `at_hospital`, "Job completed" answers "Send the patient handover before finishing the job" (`409 HANDOVER_REQUIRED`). There is no way to send one anywhere in the crew app, so every transport job gets stuck and the ambulance stays busy.

Who sees it: the paramedic; and the driver when the shift has no paramedic (`crew` in the shift view has no `PARAMEDIC`). A driver with a paramedic on the shift gets `403 PARAMEDIC_ON_SHIFT`: hide it for him.

1. When the job is `leaving_scene` or `at_hospital`, show a "Hand over the patient" card above "Job completed".
2. The screen lists the patients registered on this job (from Patient care). If there are none, it offers "Add patient" first (same form as today; for the driver alone, the patient form must be reachable too).
3. For each patient: a required summary (free text, up to 2,000 characters; prefill with the last vitals and treatments as text the crew can edit).
4. Send `POST /api/v1/handovers` with `{caseId, dispatchId, patientId, summary}` and an `Idempotency-Key`, through the outbox. A patient created offline is referenced the same way as today (the outbox `{ref:}` id).
5. Show each patient as "Handover sent" then "Received by the ER" when confirmed (reload the job).
6. "Job completed" stays disabled until every patient on the job has a handover sent. On `409 HANDOVER_REQUIRED`, open this screen instead of a toast.

After `completed`, the case closes by itself when the ER confirms the handover. Nothing else is needed from the crew.

Done when a paramedic, and separately a driver alone, can take a job from `at_hospital` to `completed` on a real phone, and the case shows Closed / Taken to hospital after the ER confirms.

## M2 (blocker): End without transport

Seen in the test: at `on_scene`, "Job completed" plus "Confirm" always gives "The request contains invalid values" and the job stays on scene. The backend needs the reason the patient was not taken (`noTransportReason`).

1. Rename the on-scene button to "End without transport". It opens a screen with six large buttons:

| Code | Arabic | English |
| --- | --- | --- |
| `treated_at_scene` | عولج في الموقع | Treated at the scene |
| `refused` | رفض المريض | Patient refused |
| `died_at_scene` | توفي في الموقع | Died at the scene |
| `patient_not_found` | لم يُعثر على المريض | Patient not found |
| `cancelled_by_caller` | ألغاه المتصل | Cancelled by caller |
| `false_alarm` | بلاغ كاذب | False alarm |

2. An optional note (up to 2,000 characters); required in the app for `refused`.
3. Send `POST /api/v1/dispatches/{id}/status` with `{"status":"completed","statusTime":"…","noTransportReason":"<code>","note":"…"}`. Add `noTransportReason` and `note` to `StatusBody`, and send them only from `on_scene`.
4. Ask once: "End the job? The case will close as \<reason>."
5. On success the case closes with that reason; go back to "Waiting for a job".

Done when each of the six reasons ends a job on a real phone and the case shows Closed with that reason.

## M3 (blocker): Medicine picker, and no silent loss of clinical data

Seen in the test: a medicine treatment ("Aspirin 300 mg, oral") showed as "Treatment 08:24" and "all sent", but the server refused it and saved nothing. A clinical record was lost and the paramedic was not told.

**Medicine picker:**

1. Load `GET /api/v1/medicines` (paramedic) after login and cache it for offline use. Answer: `[{"code":"ASPIRIN","nameAr":"أسبرين","nameEn":"Aspirin"}, …]`.
2. For kind "Medicine", replace the free-text name with a searchable picker (Arabic and English names). Send the `code` as `name`.
3. Other kinds (procedure, oxygen, fluid, other) keep free text.
4. The backend also accepts the English or Arabic name and stores the code, so entries already in phones' outboxes will go through.

**Refused writes (all clinical writes: patient, vitals, treatment, handover):**

1. A write the server refuses (any 4xx) must never disappear with only a toast. Keep it in a "Not sent" list on the Patient care screen, with the server message, and mark the entry "Not saved" in the patient's timeline.
2. Let the paramedic fix and resend it (for example pick the right medicine), or delete it on purpose.
3. The sync chip must not say "all sent" while anything is in "Not sent".
4. When the job ends or is cancelled (`job.cancelled`) and patient writes are still queued, warn before dropping them: they will get `403 PATIENT_ACCESS_DENIED`.
5. Vitals: do not count "on oxygen" or diastolic alone as a measurement (the server needs at least one of the others), so they are not refused.

Done when a medicine picked in the app is saved on the server, and a deliberately bad write shows in "Not sent" with its reason instead of vanishing.

## M4: Smaller crew fixes

| # | Problem seen | Fix |
| --- | --- | --- |
| M4.1 | Password change accepts 8 to 11 characters, then the server refuses with "This value is not valid" and no hint | Require at least 12 characters, not the username; hint text "At least 12 characters" in Arabic and English. Same for reset password. |
| M4.2 | A paramedic can start a shift alone, but no job can be sent to an ambulance without a driver (`AMBULANCE_NO_CREW`, "no driver on shift") | On the waiting screen of a paramedic alone, show "Waiting for a driver to join. Jobs can only be sent with a driver." |
| M4.3 | A partner cannot join while the ambulance is on a job (`400 AMBULANCE_UNAVAILABLE`) | Show the server message on join, and "Join after this job ends". |
| M4.4 | When the partner joins from another phone, the waiting card does not show the partner's name | Reload `GET /crew/shifts/current` on pull to refresh and when a job arrives. |
| M4.5 | The paramedic sees the driver's steps up to 35 s late | While on a job, reload `GET /crew/job` every 10 s (the crew queue only carries `job.new` / `job.cancelled`). |
| M4.6 | Pre-arrival alert buttons show even if the feature is off | Add `features` to `Me`; show the alert grid only when it contains `feature.crew_alerts`. Treat `404 FEATURE_DISABLED` as "switched off", not an error. |
| M4.7 | Typed shift code has no number pad or 6-digit check; `SHIFT_CODE_NOT_FOUND` is not mapped | Number pad, `^[0-9]{6}$` check, clear the field and show the app's "code not found" text on `SHIFT_CODE_NOT_FOUND`. |
| M4.8 | Dev tool "phone to read the code" is prefilled with the username | Prefill with the account's phone from the login answer, or leave it empty. Dev builds only. |
| M4.9 | GPS batches: a fast phone clock used to lose the whole batch | Backend now skips only those points and answers `skipped`. Still use the server time offset for `recordedAt`. |

## M5: Citizen fixes

| # | Problem | Fix |
| --- | --- | --- |
| M5.1 | Medical history is always empty: the app reads the answer as one page, but the backend returns `{patientId, visits, diagnoses, checkResults, conditions}`, each a page with `content` | Parse the four pages and show them as four sections (visits newest first). See `MOBILE-API.md` 4.5. |
| M5.2 | A request closed as treated at the scene still ticks "On the way to hospital" | Tick only the steps the request reached; for a closed request with no transport, skip the hospital steps and show the closing reason. |
| M5.3 | "Keep your phone available, the call centre will call you" stays on a closed request | Hide it once the request is closed. |
| M5.4 | Sign-up accepts any text as the Arabic name, and an 8-character password | Check the Arabic name has Arabic letters; ask for at least 12 characters, as for staff. |

The SOS, request list and live request status work well; keep them as they are.

## M6: Tests, gate and evidence

Two crew tests fail today because the fake server is older than the app (2 of 227):

- `fresh login → set PIN → start shift …`: after the shift starts, the app shows the new "shift started" screen; the test must dismiss it before looking for "Waiting for a job".
- `drivers with an active job see map and steps …`: the fake server must answer `GET /crew/shifts/current` with a shift (the app now asks it when unlocking); without it the app treats the crew as off shift.

Hand back for each part:

- [ ] `flutter analyze` 0 issues and all tests passing in `emr_core`, `crew_app`, `citizen_app`, with new tests for M1 to M5.
- [ ] M1: on a real phone, paramedic job from `at_hospital` to `completed` with handover; then the same with a driver alone. Screenshots in Arabic and English.
- [ ] M2: each of the six reasons ends a job on a real phone; the case shows Closed with that reason.
- [ ] M3: a picked medicine is saved on the server; a bad write appears in "Not sent" with its reason and is never dropped silently. Same with the phone offline, then online.
- [ ] M4 and M5: one line each in `mobile/TESTING.md` with the result.
- [ ] Update `CHANGES.md` and `TESTING.md` (new rows for handover, end without transport, medicine picker, not-sent list).

The backend team will rerun the live emulator test on the crew job and citizen SOS flows when M1 to M3 are merged.
