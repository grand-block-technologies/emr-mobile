# EMR-MR Mobile — Device Test Log

Manual and emulator testing of the crew and citizen apps against the real backend.
Updated as each check runs. Automated unit/widget tests are in `PROGRESS.md`.

## Setup

| Item | Value |
| --- | --- |
| Device | Android emulator `emulator-5554` (sdk_gphone16k_arm64, Android 17 / API 37) |
| Backend | `https://scored-rotary-lite-cam.trycloudflare.com` (`env/tunnel.json`) |
| Build | `flutter run --debug --dart-define-from-file=../../env/tunnel.json` |
| Accounts | `docs/demo-accounts.md` (password `Demo-Pass-2026`) |
| Date | 2026-10-15 |

Status key: ⬜ to test · 🔄 testing · ✅ pass · ❌ fail (see Issues) · ⏸️ blocked · ⏭️ skipped (reason given)

## Crew app (`demo.driver1`, `demo.medic1`)

| # | Check | Status | Notes |
| --- | --- | --- | --- |
| C1 | App installs and launches; splash → login in Arabic, RTL | ✅ | Arabic RTL, Plex Arabic, brand colours (screenshot c1) |
| C2 | Language toggle switches to English (LTR) and back | ✅ | English LTR; I2 fixed and re-verified by regression test |
| C3 | Empty login shows field errors, no request sent | ✅ | Required errors, no request; I1 fixed (ring on the field only) |
| C4 | Login `demo.driver1` → SMS code screen; resend countdown visible | ✅ | Real backend challenge; "Resend in 55 s" countdown; dev phone prefilled +249999990108 |
| C5 | Dev "Fill code" reads `/dev/sms/latest` and verifies | ✅ | Dev fill read code from /dev/sms/latest; verify OK; UI switched to Arabic from /me preferredLanguage |
| C6 | First login → PIN setup (new PIN) → home | ✅ | PUT /crew/pin accepted → home. **demo.driver1 PIN is now 2468** |
| C7 | Existing job shows: priority pill, status chip, case number LTR, complaint, hospital | ✅ | After I3+I6 fix: "On shift", P2 pill + stripe, status chip "left scene", KH-2026-000003 LTR, complaint, hospital; next step "Arrived at hospital" (screenshot c7b) |
| C8 | Map shows OSM tiles, pin circle, attribution | ✅ | OSM tiles render, 300 m pin circle, attribution button; tiles cached (0.1 → 0.6 MB) |
| C9 | Sync chip shows "Online · all sent" | ✅ | "متصل · تم إرسال كل شيء" |
| C10 | Settings: profile, sync card, offline map card (policy note with OSM default), language | ✅ | Profile + role chip, sync card, offline-map card with OSM policy note, language, end shift, sign out; I7 fixed |
| C11 | Airplane mode: sync chip offline; app still shows cached job | ✅ | Airplane mode → "Offline", job + map stay; GPS points queued "Offline · 1 waiting"; queue survived kill/relaunch |
| C12 | Kill + relaunch → PIN unlock screen; correct PIN → home | ✅ | Relaunch → PIN unlock in ~140 ms (after I6); correct PIN online (server verify 200) and offline (local verifier) → home |
| C13 | Wrong PIN offline shows tries left | ✅ | Online wrong PIN → server "رمز الطاقم غير صحيح." (no refresh/sign-out on that 401); offline wrong PIN → "تبقّى 4 محاولات" |
| C14 | Location permission prompt appears on shift/job (GPS) | ✅ | Prompt now appears after unlock (I4 fixed); GPS uploads seen: POST /crew/gps → 200 |
| C15 | Paramedic (`demo.medic1`) sees Patient care; add-patient form validates | ✅ | `demo.medic1` (fresh device id, see Q1) → PIN set **2468** → shift picked up from open job → "Patient care" visible; empty state; add-patient form validates national ID, Arabic name, sex; 0 patients posted. Did not save (would create a real patient) |
| C16 | Sign out → confirm dialog → back to login, data wiped | ✅ | Confirm dialog → logout 204 → login. Wipe verified on device: secure storage keeps only device_id, ui_lang, cache key (encrypted); cache.hive and outbox.hive 0 bytes; map tiles kept by design |
| C17 | Citizen account in crew app → "use the other app" | ✅ | Server 403 WRONG_CLIENT_APP → "استخدم التطبيق المخصص لدورك." |
| C18 | Job status step / alert send against live job | ⏭️ | Not run: would change the shared demo job KH-2026-000003. Covered by e2e widget test |

## Citizen app (`demo.citizen`)

| # | Check | Status | Notes |
| --- | --- | --- | --- |
| Z1 | Installs, launches, login in Arabic with "Create an account" | ✅ | Arabic RTL, "username or phone" label, "Create an account" button |
| Z2 | Login `demo.citizen` + SMS code → home (Emergency tab) | ✅ | `demo.citizen` + dev SMS code → Emergency tab: red SOS button, note field, Call 999, 4 tabs. Found I10 (SOS button announced twice) — fixed, re-verified |
| Z3 | My requests tab lists requests with server status text | ✅ | 3 real requests with server status text + chips. Found I11 (Arabic-Indic digits mixed with LTR) — fixed, re-verified "13 أكتوبر 2026 · 10:39" |
| Z4 | Request detail: status, progress steps, updated time | ✅ | Server status headline, progress steps (received current), Call 999; Sudan time (09:20Z → 11:20); polling every 12 s seen in log. Found I12/I13 — fixed, re-verified |
| Z5 | Family tab: add dependant form validates (bad ID) | ✅ | Bad ID "12" → "6 to 15 digits"; no relation → "required"; no request sent |
| Z6 | My medical history → "verify your identity" steps (403 NOT_VERIFIED) | ✅ | Server 403 CITIZEN_HISTORY_NOT_VERIFIED → "verify your identity first" + 3 steps (not an error screen). Found I14 (card not a button for TalkBack) — fixed, re-verified |
| Z7 | Account tab: name, phone shown as 0912345003, identity chip | ✅ | Name, phone shown as 0912345003, amber "phone verified" chip + hint, language, sign out |
| Z8 | Sign-up screen: phone validation | ✅ | "12345" → "Enter a valid Sudan mobile number, like 0912345678." under the field; ring only on the field (I1 fix confirmed); no request |
| Z9 | SOS button: location permission prompt | ✅ | Location prompt on SOS; "Don't allow" → reason + red Call 999 + SMS hint; 0 SOS requests sent; Call 999 opens the dialler with 999 (not dialled) |
| Z10 | SOS send creates a real request | ⏭️ | Not run: would put a real request in the call-centre queue. Covered by controller + e2e tests (key reuse, retries, 429/403 paths) |
| Z11 | Sign out | ✅ | Logout 204 → login screen |

## Issues found

| # | Found in | Problem | Status |
| --- | --- | --- | --- |
| I1 | C3 | Error ring (danger 15 %) wrapped the input **and** the message; spec puts the ring on the field only | ✅ Fixed (`LabeledField` renders the message below the ring) |
| I2 | C2 | Field errors already on screen stayed in Arabic after switching to English | ✅ Fixed (`FormStatus` keeps keys/server errors and re-renders on locale change; `LocaleService` updates GetX before notifying) + regression test |
| I3 | C7 | **Major.** Crew with an active job on the server saw "Off shift" after signing in on this phone (no current-shift endpoint; shift was only known if started on this phone) | ✅ Fixed (`CrewController` picks the shift up from an open job via `GET /crew/job`) + 2 regression tests |
| I4 | C14 | Location permission prompt appeared over the PIN lock screen (GPS started before unlock) | ✅ Fixed — re-verified on device |
| I5 | C12 | Two token refreshes at start-up (first API call went out before the refresh finished) | ✅ Fixed (interceptor waits for a pending refresh) + test — re-verified (one refresh in log) |
| I6 | C12 | **Major.** Splash waited for network + permission dialog: sign-in step awaited shift detection (`GET /crew/job`) — offline/slow network would hold the splash for the HTTP timeout | ✅ Fixed (`CrewController.restore()` = cache only before routing; `activate()` after unlock) — re-verified: unlock screen in 140 ms |
| I7 | C10 | Last button in Settings (and patient forms) sat under the gesture bar | ✅ Fixed (`SafeArea`) — re-verified |
| I8 | C12 | **Major.** Online but backend down (530): PIN unlock showed "Something went wrong" instead of using the phone verifier → crew locked out | ✅ Fixed (fallback on any retryable error) + e2e test — re-verified with backend down |
| I9 | C11 | Sync chip said "Offline · 2 waiting" while online with items not yet retried | ✅ Fixed (new "Online · N waiting to send") + test |
| I10 | Z2 | SOS button announced twice by TalkBack (outer Semantics + button) | ✅ Fixed (`excludeSemantics`) — re-verified (listed once) |
| I11 | Z3 | Dates mixed Arabic-Indic digits with an LTR wrapper (odd order); clocks used Latin digits | ✅ Fixed (`SudanTime.dateTime` → Latin digits, natural direction) + test — re-verified |
| I12 | Z4 | "Last updated 11:20" had no date for a request from 2 days ago | ✅ Fixed (`SudanTime.when`) + test — re-verified |
| I13 | Z4 | Status chip repeated the headline text | ✅ Fixed (icon + headline) — re-verified |
| I14 | Z6 | Tappable cards (history, request rows) not exposed as buttons to TalkBack | ✅ Fixed (`AppCard` adds button semantics) — re-verified |
| I15 | Z5 (reported by user) | Add-family-member sheet had a transparent background: the form floated on the dimmed page and "Send" overlapped the tab labels (`Get.bottomSheet` ignores the theme) | ✅ Fixed (core `showAppSheet`: surface background, 12 px top corners, scrim, root navigator) + widget test — re-verified on device |
| I16 | Z11/C16 (reported by user) | Tapping "Sign out" showed nothing for the few seconds the server logout takes (up to 5 s timeout) | ✅ Fixed (`SessionService.signingOut` + shared `SignOutButton`: spinner, no repeat taps; used in crew settings, citizen account, PIN and change-password screens) + test — re-verified on device |

## Questions for the product / backend team

| # | Question |
| --- | --- |
| Q1 | The server refused `demo.medic1` on the phone already used by `demo.driver1`: "لا يمكن استخدام هذا الجهاز لهذا الحساب." (401). So one phone = one crew account. The SRS says hospitals keep spare phones at stations; should a shared/spare phone be re-assignable (e.g. by the hospital ER) or allow a second account after the first signs out? |
| Q2 | There is no endpoint for the current shift (app infers it from an open job) or for the patients already on a case (the paramedic sees only patients added from this phone). Can `GET /crew/shift` and `GET /cases/{id}/patients` (crew-scoped) be added? |
| Q3 | The tunnel backend went down for ~4 minutes during testing (530). App behaved well, but production needs a stable host. |

## Summary

- **Crew:** 17 of 18 checks pass on the real backend; C18 skipped on purpose (would change the shared demo job).
- **Citizen:** 10 of 11 pass; Z10 skipped on purpose (would create a real SOS).
- **Issues:** 16 found, 16 fixed and re-verified on the emulator (3 major: I3, I6, I8). Regression tests added for each code fix: core 124, crew 68, citizen 25 — all green, analyze clean.
- **Demo data changed:** crew PIN set to **2468** for `demo.driver1` and `demo.medic1`. Nothing else was written to the backend except logins, PIN set, GPS points and logouts.

## Log
- 06:05 Crew debug build installed (tunnel env). C1–C6, C9 run.
- 06:08 I3 confirmed with API: driver1 has job KH-2026-000003 (`leaving_scene`) but app showed off-shift.
- 06:15 I1–I3 fixed; core 122, crew 67, citizen 25 tests green; rebuilding to re-test.
- 06:21 Reinstalled with I1–I3 fixes; splash hung on permission + network → I4, I5, I6 found and fixed.
- 06:24 C7, C8, C10, C12, C13, C14 pass on the real backend.
- 06:25 Airplane mode: C11 pass (offline chip, cached job, GPS queued, survives kill).
- 06:26 **Backend went down** (tunnel 530). Good resilience result: nothing dropped ("Waiting for network · 2 waiting"), refresh 530 did not sign the crew out. Found I8 (PIN unlock blocked) and I9 (label) — fixed and re-verified.
- 06:30 C15, C16, C17 and most citizen checks wait for the backend.
- 06:30 Citizen app installed; Z1, Z8 pass offline from backend. Backend back at 06:31.
- 06:32–06:35 Z2–Z7, Z9, Z11 pass; I10–I14 found.
- 06:35–06:39 Crew: backend outage queue flushed ("Online · all sent"); C16, C17 pass; medic refused on same phone (Q1); C15 pass with fresh device id.
- 06:41 I10–I14 fixed; citizen reinstalled; all re-verified on device.
- 07:03 I15 (transparent bottom sheet, reported by user) fixed and re-verified on device.
- 07:17 I16 (no feedback on sign out, reported by user) fixed and re-verified on device.
- 07:38 UI modernisation installed; sign-in, PIN, crew job/settings, citizen SOS/requests/detail/family/account re-checked on device (screenshots). All functional checks above still pass (automated suites green).
- 07:47 Sign-in screens redesigned (brand band, step strip, citizen emergency line); both apps' data cleared to view them — sign in again (crew PIN `2468` will be asked to be set/confirmed via "I have a PIN").


---

# Field-test fixes (2026-10-20) — M1 to M5

Automated results (this machine, `flutter analyze` 0 issues in `emr_core`, `crew_app`, `citizen_app`):
`emr_core` 136 passed, `crew_app` 96 passed, `citizen_app` 29 passed (after the Swagger recheck).

| # | Check | Status | Notes |
| --- | --- | --- | --- |
| H1 | Paramedic hands the patient over at `at_hospital`, offline patient id resolves, "Handover sent" shows | ✅ automated | `field_fixes_test.dart` |
| H2 | Driver alone: "Job completed" disabled until handover; with a paramedic only a hint; `HANDOVER_REQUIRED` opens the screen | ✅ automated | |
| H3 | Paramedic job `at_hospital` → `completed` on a real phone, Arabic + English screenshots | ⬜ to test | needs a real phone and the backend |
| H4 | Driver alone, same | ⬜ to test | |
| E1 | Each of the six reasons sends `noTransportReason`; `refused` needs a note; only from `on_scene` | ✅ automated | |
| E2 | Each reason ends a job on a real phone, case shows Closed with that reason | ⬜ to test | |
| P1 | A picked medicine is sent as its `code` | ✅ automated | |
| P2 | A refused write appears in "Not sent" with its reason, is marked "Not saved", can be fixed or deleted, chip never says "all sent" | ✅ automated | also `emr_core` outbox tests |
| P3 | Same with the phone offline, then online, on a real phone | ⬜ to test | |
| N1 | Alerts multi-select (two types = two alerts); hidden when the feature is off | ✅ automated | |
| N2 | "Add vitals" registers an unknown patient once, then reuses it; oxygen/diastolic alone refused on the phone | ✅ automated | |
| N3 | Request history from `GET /crew/jobs`, opens offline from the cache | ✅ automated | |
| H5 | "Received by the ER" from `handovers[].status`; driver with a paramedic waits for the paramedic's handover | ✅ automated | |
| M4 | 4.1 password 12 chars · 4.2 wait for driver · 4.3 join later · 4.5 10 s reload · 4.6 features · 4.7 shift code · 4.8 dev phone | ✅ automated (4.4, 4.5 by code; no timer test) | 4.4/4.5 not covered by a test |
| M5 | 5.1 four history lists · 5.2 closed request (`reachedSteps`, closing reason) · 5.3 phone hint hidden · 5.4 Arabic name + 12 chars | ✅ automated | |

The backend team reruns the live emulator test on the crew job and citizen SOS flows after M1 to M3 are merged.
