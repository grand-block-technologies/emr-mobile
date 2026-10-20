# Backend gaps found while doing the field-test fixes (M1-M6)

For the backend team. The apps use only fields in the backend's OpenAPI (`/v3/api-docs`) and `docs/MOBILE-API.md`; nothing below is invented on the phone.

Rechecked against the Swagger on 2026-10-20: B1 to B5 are now covered by new fields and the apps use them.

| # | Gap | Status |
| --- | --- | --- |
| B1 | No crew endpoint for past jobs (client's "request history"). | ✅ Closed: `GET /crew/jobs` (paged, any phone, `closingReason`). The app shows it and caches the first page for offline. |
| B2 | No field for "Received by the ER". | ✅ Closed: `GET /crew/job` → `handovers[].status` (`pending`/`confirmed`) and `receivedAt`. Shown as "Handover sent", then "Received by the ER". |
| B3 | The driver cannot see whether the paramedic sent the handover. | ✅ Closed by the same `handovers` list. A driver with a paramedic now has "Job completed" disabled until a handover is on the job, then sees "The paramedic sent the handover". |
| B4 | Citizen request: no reached steps or closing reason. | ✅ Closed: `reachedSteps[]`, `closingReason`, `closingReasonAr/En`. A closed request shows only the steps it reached, plus the reason. |
| B5 | History row fields not published. | ✅ Closed: `HistoryVisit`, `HistoryDiagnosis`, `HistoryCheckResult`, `HistoryCondition` (`allergy`/`current_medicine`). |
| B6 | The login answer has no phone number, so the dev "phone to read the code" (M4.8) cannot be prefilled from it. | ⬜ Still open (`LoginResult` unchanged). Prefilled only for the known demo accounts, or when the username is itself a phone number (citizen); otherwise empty. Dev builds only. |

Note: `POST /dispatches/{id}/finish` is new too, but it is supervisor-only ("Finish a job the crew left open"), so the crew app does not call it.
