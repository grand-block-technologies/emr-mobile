# Mobile team: crew shift start, join and end

Oct 18, 2026 · @houzifa Kroom

## What changed

The crew can now start or join a shift by typing the ambulance's 6-digit shift code, as well as by scanning its QR. "Shift already active" is now a normal state the app handles, not an error.

- **6-digit code:** every ambulance has one, printed under its QR. The app sends `{"code":"482913"}` or `{"qrToken":"…"}`, exactly one of them.
- **Already on a shift:** start and join answer `400 SHIFT_ALREADY_ACTIVE` before anything else. The app treats it as "go to the shift screen", not as a failure.
- **Dev backend only:** code `000000` means "any free ambulance in my hospital" (join: "any shift in my hospital waiting for a partner"). Production refuses it.
- **Dev backend only:** a test phone used with another account moves to that account instead of failing with `DEVICE_INVALID`.

Backend reference: `docs/api/MOBILE-API.md` section 3.2 (backend repo).

## API calls

All three need the crew member's access token. Send exactly one of `qrToken` or `code`.

| Action | Call | Body | Success |
| --- | --- | --- | --- |
| Start a shift | `POST /api/v1/crew/shifts` | `{"code":"482913"}` or `{"qrToken":"7d04a647…"}` | `200` `{"id":"<shiftId>","ambulanceId":"…"}` |
| Join the partner's shift | `POST /api/v1/crew/shifts/current/join` | same | `200`, same shape, the partner's shift `id` |
| End my shift | `POST /api/v1/crew/shifts/current/end` | none | `200` `{"shiftId":"…","ended":true}` |

**Rules:**

- `code` is exactly 6 digits, sent as a string (keep leading zeros: `"048213"`, never a number).
- The code is looked up only among the ambulances of the crew member's own hospital. Another hospital's code answers `404`.
- A shift holds at most 2 crew members. The driver usually starts; the paramedic joins.
- Ending is per person. When the last crew member ends, the shift closes.
- After start or join succeeds, call `GET /api/v1/crew/job` and start sending GPS (see the live-tracking notes).

**Not yet in the backend:** a call that says "am I on a shift, on which ambulance?". Until it exists, `400 SHIFT_ALREADY_ACTIVE` from start is how the app learns it (next section). The planned call is `GET /api/v1/crew/shifts/current`, returning the shift, plate, start time and crew, or `{"shift":null}`.

## Errors and what the app shows

Show the server's `message_ar` / `message_en` unless this table gives a better screen. Never show a raw code to the crew.

| Answer | When | App does | Text (en / ar) |
| --- | --- | --- | --- |
| `400 SHIFT_ALREADY_ACTIVE` | Start or join while already on a shift (checked first) | **Not an error.** Go to the shift screen and load `GET /crew/job` | You are already on a shift. / أنت في مناوبة بالفعل. |
| `404 NOT_FOUND` | Wrong code or QR; another hospital's ambulance; dev `000000` with no free ambulance | Stay on the code screen, clear the boxes, keep the keypad open | Code not found. Check the number on the ambulance. / الرمز غير صحيح. تحقق من الرقم على الإسعاف. |
| `400 VALIDATION_ERROR` | Not 6 digits, or both / neither of `qrToken` and `code` | Should never happen if the keypad only sends 6 digits; treat as a bug and log it | Server message |
| `400 AMBULANCE_UNAVAILABLE` | The ambulance is marked not working | Show the message; the crew calls the hospital | Server message |
| `400 SHIFT_FULL` | Join, but the shift already has 2 crew | Show the message | Server message |
| `400 SHIFT_HAS_JOB` | End shift while the ambulance has an open job | Keep the shift; show "Finish the job first" with a button to the job | Finish the job before ending your shift. / أنهِ المهمة قبل إنهاء المناوبة. |
| `403 OUTSIDE_SCOPE` | QR of another hospital's ambulance | Same screen as `404` | Same as `404` |
| `401` | Session ended or phone blocked | Back to login | Server message |

## Screens

**Start shift screen** (after login, when the crew member is not on a shift):

- Title "Start shift" / "بدء المناوبة". Two buttons: **Start a new shift** (driver) and **Join my partner's shift** (paramedic). Both lead to the code entry; only the endpoint differs.
- Code entry: 6 boxes, number keypad only, digits always left to right even in Arabic (wrap in an LTR direction). Submit by itself when the 6th digit is typed. A "Scan QR instead" link opens the camera.
- While sending: disable the boxes and show a spinner. Send once; never retry automatically.
- Success: show the ambulance plate and "Shift started" for 2 seconds, then open the shift screen.

**Shift screen** (on a shift):

- Ambulance plate, partner's name, and the current job from `GET /crew/job` or "Waiting for a job".
- An "End shift" button at the bottom, with a confirmation dialog. If it returns `SHIFT_HAS_JOB`, show the message and a button to the job.

**At login** (until `GET /crew/shifts/current` exists):

- Remember locally whether the last start or join succeeded on this install.
- If you don't know, show the start screen. If start returns `SHIFT_ALREADY_ACTIVE`, go straight to the shift screen. This costs one request and is correct in every case.

## On the dev backend

The dev backend has two shortcuts for testing. Production has neither.

- **Code `000000`:** start takes the first free ambulance in your hospital; join takes the first shift in your hospital waiting for a partner. `404` means none is free.
- **Shared test phones:** logging in with another account on the same phone moves the phone to that account. The previous account is signed out on that phone. A blocked phone stays blocked.
- **Demo crew are already on a shift.** `demo.driver1` and `demo.medic1` start on ambulance DEMO-11 (Riyadh Demo Hospital, its only working ambulance). Start gives `SHIFT_ALREADY_ACTIVE` until they end it.

**Test the full flow:**

1. Log in as `demo.driver1`. Start returns `SHIFT_ALREADY_ACTIVE`, and the app opens the shift screen.
2. End shift as `demo.driver1`, then log in as `demo.medic1` and end shift too. Both answer `{"ended":true}`.
3. As `demo.driver1`: Start a new shift with `000000`. The plate shown is DEMO-11.
4. As `demo.medic1`: Join with `000000`. The same shift `id` comes back.
5. Type a wrong code, for example `123456`. The app shows "Code not found" and keeps the keypad open.
6. Ask the call centre to send a job to DEMO-11. It appears on the shift screen; then try End shift and check the `SHIFT_HAS_JOB` message.

## Done checklist

Done when every box is ticked in Arabic and English on a real Android phone.

- [ ] `SHIFT_ALREADY_ACTIVE` opens the shift screen with no error shown.
- [ ] Code entry: 6 boxes, number keypad, digits left to right in Arabic, sends by itself on the 6th digit, sends the code as a string.
- [ ] "Scan QR instead" works and sends `qrToken`, never both fields.
- [ ] Wrong code keeps the keypad open with the "Code not found" message.
- [ ] End shift asks for confirmation; `SHIFT_HAS_JOB` shows the message and a link to the job.
- [ ] After start or join, the app loads the job and starts sending GPS.
- [ ] One `deviceId` per app install, kept in secure storage, never a new one per login.
- [ ] The dev test steps above all pass.
