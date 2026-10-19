# EMR API Reference

Generated from the OpenAPI spec at `https://ryan-directions-advisors-twin.trycloudflare.com/v3/api-docs` (OpenAPI definition, version v0).

- **Base URL:** `https://ryan-directions-advisors-twin.trycloudflare.com`
- **Auth:** `bearerAuth` — HTTP bearer (JWT). Send `Authorization: Bearer <token>`.
- **Endpoints:** 207 across 16 groups
- **Schemas:** 233

## Contents

- [clinical-controller](#clinical-controller) (27)
- [device-controller](#device-controller) (5)
- [call-centre-controller](#call-centre-controller) (17)
- [ops-controller](#ops-controller) (31)
- [admin-controller](#admin-controller) (47)
- [hospital-operations-controller](#hospital-operations-controller) (10)
- [billing-controller](#billing-controller) (11)
- [dispatch-controller](#dispatch-controller) (16)
- [citizen-controller](#citizen-controller) (13)
- [read-controller](#read-controller) (8)
- [auth-controller](#auth-controller) (8)
- [live-contract](#live-contract) (1)
- [health-controller](#health-controller) (1)
- [dev-sms-controller](#dev-sms-controller) (2)
- [report-controller](#report-controller) (9)
- [me-controller](#me-controller) (1)
- [Schemas](#schemas)

## Endpoint summary

| Method | Path | Group | Summary |
|---|---|---|---|
| `PUT` | `/api/v1/patients/{id}/first-health-check` | clinical-controller | firstCheck |
| `POST` | `/api/v1/visits` | clinical-controller | visit |
| `POST` | `/api/v1/visits/{id}/end` | clinical-controller | end |
| `POST` | `/api/v1/visits/{id}/diagnoses` | clinical-controller | diagnosis |
| `POST` | `/api/v1/patients` | clinical-controller | patient |
| `POST` | `/api/v1/patients/{id}/undo-merge` | clinical-controller | undo |
| `POST` | `/api/v1/patients/{id}/treatments` | clinical-controller | treatments |
| `POST` | `/api/v1/patients/{id}/observations` | clinical-controller | observations |
| `POST` | `/api/v1/patients/{id}/national-id` | clinical-controller | national |
| `POST` | `/api/v1/patients/{id}/identifiers` | clinical-controller | identifier |
| `POST` | `/api/v1/patients/{id}/first-record/complete` | clinical-controller | complete |
| `POST` | `/api/v1/patients/{id}/files` | clinical-controller | upload |
| `POST` | `/api/v1/patients/{id}/conditions` | clinical-controller | conditions |
| `POST` | `/api/v1/patients/{id}/check-results` | clinical-controller | check |
| `POST` | `/api/v1/patients/{id}/break-glass` | clinical-controller | breakGlass |
| `POST` | `/api/v1/patients/merge` | clinical-controller | merge |
| `POST` | `/api/v1/handovers` | clinical-controller | handover |
| `POST` | `/api/v1/handovers/{id}/confirm` | clinical-controller | confirm |
| `POST` | `/api/v1/diagnoses/{id}/entered-in-error` | clinical-controller | enteredError |
| `POST` | `/api/v1/cases/{id}/patients` | clinical-controller | link |
| `PATCH` | `/api/v1/patients/{id}/blood-type` | clinical-controller | blood |
| `GET` | `/api/v1/patients/{id}` | clinical-controller | record |
| `GET` | `/api/v1/patients/{id}/first-record/missing` | clinical-controller | missing |
| `GET` | `/api/v1/patients/search` | clinical-controller | search_1 |
| `GET` | `/api/v1/hospital/lab/pending` | clinical-controller | lab |
| `GET` | `/api/v1/hospital/handovers` | clinical-controller | handovers |
| `GET` | `/api/v1/files/{id}` | clinical-controller | download |
| `PUT` | `/api/v1/devices/current/push-token` | device-controller | push |
| `PUT` | `/api/v1/crew/pin` | device-controller | pin |
| `POST` | `/api/v1/devices/{id}/block` | device-controller | Block a lost or stolen device |
| `POST` | `/api/v1/crew/pin/verify` | device-controller | verify |
| `GET` | `/api/v1/devices` | device-controller | The caller's own devices |
| `PUT` | `/api/v1/cases/{id}/triage-answers` | call-centre-controller | Save triage answers |
| `POST` | `/api/v1/hospital-requests/{id}/cancel` | call-centre-controller | Cancel a waiting hospital request |
| `POST` | `/api/v1/cases` | call-centre-controller | Create a case |
| `POST` | `/api/v1/cases/{id}/ready` | call-centre-controller | Mark the case ready for a hospital (urgency_set) |
| `POST` | `/api/v1/cases/{id}/hospital-requests` | call-centre-controller | Send the case to a hospital |
| `POST` | `/api/v1/cases/{id}/close` | call-centre-controller | Close the case |
| `POST` | `/api/v1/calls` | call-centre-controller | Start a 999 call |
| `POST` | `/api/v1/app-requests/{callId}/take` | call-centre-controller | Take a citizen SOS |
| `PATCH` | `/api/v1/cases/{id}/priority` | call-centre-controller | Override the priority |
| `PATCH` | `/api/v1/calls/{id}` | call-centre-controller | End a call without a case |
| `GET` | `/api/v1/triage/questions` | call-centre-controller | Active triage questions of a model |
| `GET` | `/api/v1/geo/search` | call-centre-controller | Search areas and landmarks by name |
| `GET` | `/api/v1/geo/pin-circle` | call-centre-controller | Pin circle clipped to mapped areas |
| `GET` | `/api/v1/geo/find-area` | call-centre-controller | Area, locality and state at a pin |
| `GET` | `/api/v1/geo/areas-near-pin` | call-centre-controller | Areas within a radius of the pin |
| `GET` | `/api/v1/cases/{id}/nearest-hospitals` | call-centre-controller | Nearest hospitals for the case |
| `GET` | `/api/v1/cases/duplicates` | call-centre-controller | Possible duplicate cases |
| `PUT` | `/api/v1/cases/{id}/mci-tag` | ops-controller | Set a case's START colour |
| `PUT` | `/api/v1/admin/triage-instructions/{id}` | ops-controller | Edit an instruction card |
| `GET` | `/api/v1/admin/hospitals/{id}/capabilities` | ops-controller | Hospital capabilities |
| `PUT` | `/api/v1/admin/hospitals/{id}/capabilities` | ops-controller | Replace hospital capabilities |
| `POST` | `/api/v1/sms/inbound` | ops-controller | Inbound SMS from the gateway |
| `GET` | `/api/v1/qa/reviews` | ops-controller | Recent reviews |
| `POST` | `/api/v1/qa/reviews` | ops-controller | Review a call |
| `GET` | `/api/v1/incidents` | ops-controller | Incidents in my states |
| `POST` | `/api/v1/incidents` | ops-controller | Open a mass-casualty incident |
| `POST` | `/api/v1/incidents/{id}/close` | ops-controller | Close an incident |
| `POST` | `/api/v1/incidents/{id}/cases` | ops-controller | Add a case to an incident |
| `POST` | `/api/v1/dispatches/{id}/alerts` | ops-controller | Raise a pre-arrival alert |
| `POST` | `/api/v1/dispatch-alerts/{id}/acknowledge` | ops-controller | Acknowledge a pre-arrival alert |
| `POST` | `/api/v1/cross-state-approvals/{id}/reject` | ops-controller | Reject a cross-state request |
| `POST` | `/api/v1/cross-state-approvals/{id}/approve` | ops-controller | Approve a cross-state request |
| `POST` | `/api/v1/cases/{id}/reassign` | ops-controller | Reassign a case to another agent |
| `POST` | `/api/v1/cases/{id}/outcome` | ops-controller | Record the patient outcome |
| `POST` | `/api/v1/cases/{id}/cross-state-approvals` | ops-controller | Ask a supervisor for a cross-state hospital |
| `POST` | `/api/v1/app-requests/{callId}/reassign` | ops-controller | Reassign a citizen SOS to another agent |
| `GET` | `/api/v1/admin/triage-instructions` | ops-controller | Instruction cards (admin) |
| `POST` | `/api/v1/admin/triage-instructions` | ops-controller | Create an instruction card |
| `GET` | `/api/v1/supervisor/approvals` | ops-controller | Pending cross-state requests |
| `GET` | `/api/v1/supervisor/agents` | ops-controller | Agents today |
| `GET` | `/api/v1/qa/sample` | ops-controller | Calls to review |
| `GET` | `/api/v1/incidents/{id}` | ops-controller | Incident board |
| `GET` | `/api/v1/hospital/arrivals` | ops-controller | Ambulances coming to my hospital |
| `GET` | `/api/v1/fhir/Encounter/{id}` | ops-controller | Case as a FHIR R4 Bundle |
| `GET` | `/api/v1/cases/{id}/jobs` | ops-controller | Ambulance jobs on a case |
| `GET` | `/api/v1/cases/{id}/instructions` | ops-controller | Pre-arrival instructions for a case |
| `GET` | `/api/v1/cases/{id}/cross-state-hospitals` | ops-controller | Hospitals in other states |
| `GET` | `/api/v1/cases/{id}/ambulance-options` | ops-controller | Available ambulances ranked by ETA |
| `PUT` | `/api/v1/admin/users/{id}/scopes` | admin-controller | scopes |
| `PUT` | `/api/v1/admin/ambulances/{id}/wialon` | admin-controller | wialon |
| `GET` | `/api/v1/admin/users` | admin-controller | users |
| `POST` | `/api/v1/admin/users` | admin-controller | user |
| `POST` | `/api/v1/admin/users/{id}/unlock` | admin-controller | Unlock an account locked after wrong passwords |
| `POST` | `/api/v1/admin/users/{id}/reset-password` | admin-controller | Reset a user's password |
| `POST` | `/api/v1/admin/users/{id}/enable` | admin-controller | enable |
| `POST` | `/api/v1/admin/users/{id}/disable` | admin-controller | disable |
| `GET` | `/api/v1/admin/triage-questions` | admin-controller | triageQuestions |
| `POST` | `/api/v1/admin/triage-questions` | admin-controller | triageQuestion |
| `GET` | `/api/v1/admin/lists/{code}/items` | admin-controller | items |
| `POST` | `/api/v1/admin/lists/{code}/items` | admin-controller | item |
| `GET` | `/api/v1/admin/landmarks` | admin-controller | landmarks |
| `POST` | `/api/v1/admin/landmarks` | admin-controller | landmark |
| `POST` | `/api/v1/admin/landmarks/{id}/reject` | admin-controller | reject_1 |
| `POST` | `/api/v1/admin/landmarks/{id}/approve` | admin-controller | approve_1 |
| `GET` | `/api/v1/admin/hospitals` | admin-controller | hospitals |
| `POST` | `/api/v1/admin/hospitals` | admin-controller | hospital |
| `POST` | `/api/v1/admin/devices/{id}/revoke` | admin-controller | Log a device out without blocking it |
| `GET` | `/api/v1/admin/areas` | admin-controller | areas |
| `POST` | `/api/v1/admin/areas` | admin-controller | area |
| `POST` | `/api/v1/admin/areas/import` | admin-controller | Import areas from a GeoJSON FeatureCollection |
| `GET` | `/api/v1/admin/ambulances` | admin-controller | ambulances_1 |
| `POST` | `/api/v1/admin/ambulances` | admin-controller | ambulance_1 |
| `GET` | `/api/v1/admin/users/{id}` | admin-controller | userDetail |
| `PATCH` | `/api/v1/admin/users/{id}` | admin-controller | user_1 |
| `GET` | `/api/v1/admin/triage-questions/{id}` | admin-controller | triageQuestionDetail |
| `PATCH` | `/api/v1/admin/triage-questions/{id}` | admin-controller | Edit or disable a triage question |
| `PATCH` | `/api/v1/admin/settings/{key}` | admin-controller | setting |
| `PATCH` | `/api/v1/admin/lists/{code}/items/{id}` | admin-controller | item_1 |
| `GET` | `/api/v1/admin/landmarks/{id}` | admin-controller | landmarkDetail |
| `PATCH` | `/api/v1/admin/landmarks/{id}` | admin-controller | landmark_1 |
| `GET` | `/api/v1/admin/hospitals/{id}` | admin-controller | hospitalDetail |
| `PATCH` | `/api/v1/admin/hospitals/{id}` | admin-controller | hospital_1 |
| `GET` | `/api/v1/admin/areas/{id}` | admin-controller | areaDetail |
| `PATCH` | `/api/v1/admin/areas/{id}` | admin-controller | area_1 |
| `GET` | `/api/v1/admin/ambulances/{id}` | admin-controller | ambulanceDetail |
| `PATCH` | `/api/v1/admin/ambulances/{id}` | admin-controller | ambulance_3 |
| `GET` | `/api/v1/admin/waivers` | admin-controller | Waived ambulance charges (read-only) |
| `GET` | `/api/v1/admin/triage-questions/{id}/history` | admin-controller | Change history of a triage question |
| `GET` | `/api/v1/admin/trackers` | admin-controller | trackers |
| `GET` | `/api/v1/admin/settings` | admin-controller | settings |
| `GET` | `/api/v1/admin/settings/{key}/history` | admin-controller | settingsHistory |
| `GET` | `/api/v1/admin/localities` | admin-controller | Localities for area and hospital forms |
| `GET` | `/api/v1/admin/lists` | admin-controller | lists |
| `GET` | `/api/v1/admin/devices` | admin-controller | Search devices of any user |
| `GET` | `/api/v1/admin/access-log` | admin-controller | access |
| `GET` | `/api/v1/hospitals/{id}/recommended-checks` | hospital-operations-controller | checks |
| `POST` | `/api/v1/hospitals/{id}/recommended-checks` | hospital-operations-controller | check_1 |
| `GET` | `/api/v1/ambulances` | hospital-operations-controller | ambulances |
| `POST` | `/api/v1/ambulances` | hospital-operations-controller | ambulance |
| `PATCH` | `/api/v1/hospitals/{id}/status` | hospital-operations-controller | status_1 |
| `PATCH` | `/api/v1/hospitals/{id}/recommended-checks/{checkId}` | hospital-operations-controller | check_2 |
| `PATCH` | `/api/v1/ambulances/{id}` | hospital-operations-controller | ambulance_2 |
| `GET` | `/api/v1/search` | hospital-operations-controller | search |
| `GET` | `/api/v1/hospitals/{id}/status-history` | hospital-operations-controller | history |
| `GET` | `/api/v1/ambulances/{id}/qr.png` | hospital-operations-controller | qr |
| `GET` | `/api/v1/hospital/tariffs` | billing-controller | hospitalTariffs |
| `POST` | `/api/v1/hospital/tariffs` | billing-controller | hospitalTariff |
| `POST` | `/api/v1/charges/{id}/waive` | billing-controller | waive |
| `POST` | `/api/v1/charges/{id}/payments` | billing-controller | payment |
| `GET` | `/api/v1/admin/tariffs` | billing-controller | adminTariffs |
| `POST` | `/api/v1/admin/tariffs` | billing-controller | adminTariff |
| `PATCH` | `/api/v1/hospital/tariffs/{id}` | billing-controller | hospitalEdit |
| `PATCH` | `/api/v1/admin/tariffs/{id}` | billing-controller | adminEdit |
| `GET` | `/api/v1/payments/{id}/receipt.pdf` | billing-controller | receipt |
| `GET` | `/api/v1/hospital/charges` | billing-controller | charges_1 |
| `GET` | `/api/v1/cases/{id}/charges` | billing-controller | caseCharges |
| `POST` | `/api/v1/hospital-requests/{id}/refuse` | dispatch-controller | refuse |
| `POST` | `/api/v1/hospital-requests/{id}/accept` | dispatch-controller | accept |
| `POST` | `/api/v1/dispatches/{id}/status` | dispatch-controller | status |
| `POST` | `/api/v1/dispatches/{id}/phone-calls` | dispatch-controller | phone |
| `POST` | `/api/v1/dispatches/{id}/confirm` | dispatch-controller | confirm_1 |
| `POST` | `/api/v1/dispatches/{id}/cancel` | dispatch-controller | cancel_1 |
| `POST` | `/api/v1/crew/shifts` | dispatch-controller | shift |
| `POST` | `/api/v1/crew/shifts/current/join` | dispatch-controller | join |
| `POST` | `/api/v1/crew/shifts/current/end` | dispatch-controller | end_1 |
| `POST` | `/api/v1/crew/gps` | dispatch-controller | gps |
| `POST` | `/api/v1/cases/{id}/dispatches` | dispatch-controller | dispatch |
| `GET` | `/api/v1/hospital/requests` | dispatch-controller | requests_1 |
| `GET` | `/api/v1/hospital/incoming` | dispatch-controller | incoming |
| `GET` | `/api/v1/hospital/dispatches/unconfirmed` | dispatch-controller | unconfirmed |
| `GET` | `/api/v1/hospital/ambulances` | dispatch-controller | ambulances_3 |
| `GET` | `/api/v1/crew/job` | dispatch-controller | job |
| `POST` | `/api/v1/citizens/verify-id-card` | citizen-controller | verifyId |
| `POST` | `/api/v1/citizen/sign-up/start` | citizen-controller | start |
| `POST` | `/api/v1/citizen/sign-up/finish` | citizen-controller | finish |
| `GET` | `/api/v1/citizen/requests` | citizen-controller | requests |
| `POST` | `/api/v1/citizen/requests` | citizen-controller | sos |
| `POST` | `/api/v1/citizen/dependants` | citizen-controller | dependant |
| `POST` | `/api/v1/citizen-dependants/{id}/verify` | citizen-controller | verifyDependant |
| `POST` | `/api/v1/app-requests/{callId}/close` | citizen-controller | Close a citizen SOS without a case |
| `POST` | `/api/v1/admin/citizens/{userId}/unsuspend` | citizen-controller | unsuspend |
| `POST` | `/api/v1/admin/citizens/{userId}/suspend` | citizen-controller | suspend |
| `GET` | `/api/v1/citizen/requests/{id}` | citizen-controller | status_2 |
| `GET` | `/api/v1/citizen/me` | citizen-controller | me_1 |
| `GET` | `/api/v1/citizen/history` | citizen-controller | history_1 |
| `GET` | `/api/v1/calls` | read-controller | Calls (read-only, system administrator) |
| `GET` | `/api/v1/calls/{id}` | read-controller | One call (read-only, system administrator) |
| `GET` | `/api/v1/supervisor/overview` | read-controller | Supervisor numbers per state |
| `GET` | `/api/v1/states` | read-controller | states |
| `GET` | `/api/v1/hospitals` | read-controller | hospitals_1 |
| `GET` | `/api/v1/cases/{id}` | read-controller | Case detail |
| `GET` | `/api/v1/cases/open` | read-controller | Open cases queue |
| `GET` | `/api/v1/app-requests` | read-controller | Citizen SOS requests waiting for an agent |
| `POST` | `/api/v1/auth/verify` | auth-controller | verify_1 |
| `POST` | `/api/v1/auth/reset-password` | auth-controller | reset |
| `POST` | `/api/v1/auth/resend` | auth-controller | resend |
| `POST` | `/api/v1/auth/refresh` | auth-controller | refresh |
| `POST` | `/api/v1/auth/logout` | auth-controller | logout |
| `POST` | `/api/v1/auth/login` | auth-controller | login |
| `POST` | `/api/v1/auth/forgot-password` | auth-controller | forgot |
| `POST` | `/api/v1/auth/change-password` | auth-controller | change |
| `GET` | `/v3/asyncapi` | live-contract | asyncApi |
| `GET` | `/health` | health-controller | health |
| `GET` | `/dev/sms/latest` | dev-sms-controller | latest |
| `GET` | `/dev/sms/latest-text` | dev-sms-controller | latestText |
| `GET` | `/api/v1/reports/{name}/export` | report-controller | export |
| `GET` | `/api/v1/reports/response-times` | report-controller | responseTimes |
| `GET` | `/api/v1/reports/patients` | report-controller | patients |
| `GET` | `/api/v1/reports/hospital-requests` | report-controller | hospitalRequests |
| `GET` | `/api/v1/reports/charges` | report-controller | charges |
| `GET` | `/api/v1/reports/cases` | report-controller | cases |
| `GET` | `/api/v1/reports/call-centre` | report-controller | callCentre |
| `GET` | `/api/v1/reports/ambulances` | report-controller | ambulances_2 |
| `GET` | `/api/v1/dashboard` | report-controller | dashboard |
| `GET` | `/api/v1/me` | me-controller | me |

## clinical-controller

### `PUT /api/v1/patients/{id}/first-health-check`

Operation ID: `firstCheck`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |
| `Idempotency-Key` | header | string | no |  |

**Request body** (required)

- `application/json`: [FirstCheck](#firstcheck)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/visits`

Operation ID: `visit`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `Idempotency-Key` | header | string | no |  |

**Request body** (required)

- `application/json`: [Link](#link)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/visits/{id}/end`

Operation ID: `end`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |
| `Idempotency-Key` | header | string | no |  |

**Request body** (required)

- `application/json`: [EndVisit](#endvisit)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/visits/{id}/diagnoses`

Operation ID: `diagnosis`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |
| `Idempotency-Key` | header | string | no |  |

**Request body** (required)

- `application/json`: [Diagnosis](#diagnosis)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/patients`

Operation ID: `patient`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `Idempotency-Key` | header | string | no |  |

**Request body** (required)

- `application/json`: [Patient](#patient)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/patients/{id}/undo-merge`

Operation ID: `undo`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |
| `Idempotency-Key` | header | string | no |  |

**Request body** (required)

- `application/json`: [Reason](#reason)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/patients/{id}/treatments`

Operation ID: `treatments`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |
| `Idempotency-Key` | header | string | no |  |

**Request body** (required)

- `application/json`: [Treatment](#treatment)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/patients/{id}/observations`

Operation ID: `observations`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |
| `Idempotency-Key` | header | string | no |  |

**Request body** (required)

- `application/json`: [Observation](#observation)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/patients/{id}/national-id`

Operation ID: `national`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |
| `Idempotency-Key` | header | string | no |  |

**Request body** (required)

- `application/json`: [NationalId](#nationalid)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/patients/{id}/identifiers`

Operation ID: `identifier`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |
| `Idempotency-Key` | header | string | no |  |

**Request body** (required)

- `application/json`: [Identifier](#identifier)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/patients/{id}/first-record/complete`

Operation ID: `complete`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |
| `Idempotency-Key` | header | string | no |  |

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/patients/{id}/files`

Operation ID: `upload`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |
| `kind` | query | string | no |  |
| `Idempotency-Key` | header | string | no |  |

**Request body**

- `multipart/form-data`:
  - `file`: string(binary) (required)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/patients/{id}/conditions`

Operation ID: `conditions`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |
| `Idempotency-Key` | header | string | no |  |

**Request body** (required)

- `application/json`: [Condition](#condition)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/patients/{id}/check-results`

Operation ID: `check`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |
| `Idempotency-Key` | header | string | no |  |

**Request body** (required)

- `application/json`: [CheckResult](#checkresult)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/patients/{id}/break-glass`

Operation ID: `breakGlass`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |
| `Idempotency-Key` | header | string | no |  |

**Request body** (required)

- `application/json`: [Reason](#reason)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/patients/merge`

Operation ID: `merge`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `Idempotency-Key` | header | string | no |  |

**Request body** (required)

- `application/json`: [Merge](#merge)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/handovers`

Operation ID: `handover`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `Idempotency-Key` | header | string | no |  |

**Request body** (required)

- `application/json`: [Handover](#handover)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/handovers/{id}/confirm`

Operation ID: `confirm`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |
| `Idempotency-Key` | header | string | no |  |

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/diagnoses/{id}/entered-in-error`

Operation ID: `enteredError`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |
| `Idempotency-Key` | header | string | no |  |

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/cases/{id}/patients`

Operation ID: `link`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |
| `Idempotency-Key` | header | string | no |  |

**Request body** (required)

- `application/json`: [Link](#link)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `PATCH /api/v1/patients/{id}/blood-type`

Operation ID: `blood`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |
| `Idempotency-Key` | header | string | no |  |

**Request body** (required)

- `application/json`: [BloodType](#bloodtype)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `GET /api/v1/patients/{id}`

Operation ID: `record`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `GET /api/v1/patients/{id}/first-record/missing`

Operation ID: `missing`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `GET /api/v1/patients/search`

Operation ID: `search_1`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `q` | query | string | no |  |
| `phone` | query | string | no |  |
| `idValue` | query | string | no |  |
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |

**Responses**

- `200` OK — `application/json` → [Page](#page)

---

### `GET /api/v1/hospital/lab/pending`

Operation ID: `lab`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |

**Responses**

- `200` OK — `application/json` → [Page](#page)

---

### `GET /api/v1/hospital/handovers`

Operation ID: `handovers`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `status` | query | string | no |  |
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |

**Responses**

- `200` OK — `application/json` → [Page](#page)

---

### `GET /api/v1/files/{id}`

Operation ID: `download`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → string(byte)

---

## device-controller

### `PUT /api/v1/devices/current/push-token`

Operation ID: `push`

**Request body** (required)

- `application/json`: [Push](#push)

**Responses**

- `200` OK — `application/json` → map<string, boolean>

---

### `PUT /api/v1/crew/pin`

Operation ID: `pin`

**Request body** (required)

- `application/json`: [Pin](#pin)

**Responses**

- `200` OK — `application/json` → map<string, boolean>

---

### `POST /api/v1/devices/{id}/block`

**Block a lost or stolen device**

Blocks the device and revokes its sessions. SYSTEM_ADMIN: any device. HOSPITAL_ER: crew devices of the own hospital.

Operation ID: `block`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [Block](#block)

**Responses**

- `200` OK — `application/json` → [Blocked](#blocked)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/crew/pin/verify`

Operation ID: `verify`

**Request body** (required)

- `application/json`: [Pin](#pin)

**Responses**

- `200` OK — `application/json` → map<string, boolean>

---

### `GET /api/v1/devices`

**The caller's own devices**

Admins find other users' devices with GET /api/v1/admin/devices.

Operation ID: `list`

**Responses**

- `200` OK — `application/json` → [OwnDeviceView](#owndeviceview)[]
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

## call-centre-controller

### `PUT /api/v1/cases/{id}/triage-answers`

**Save triage answers**

Replaces the given answers and sets the priority automatically unless it was overridden manually.

Operation ID: `answers`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [Answer](#answer)[]

**Responses**

- `200` OK — `application/json` → [CaseState](#casestate)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Concurrent change or record no longer available: CONFLICT, CALL_UNAVAILABLE or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/hospital-requests/{id}/cancel`

**Cancel a waiting hospital request**

Operation ID: `cancel`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → [HospitalRequestCancelled](#hospitalrequestcancelled)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Concurrent change or record no longer available: CONFLICT, CALL_UNAVAILABLE or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/cases`

**Create a case**

State comes from stateId, the call, or the agent's only state. The pin must lie in that state when it is inside a mapped area. emergencyTypeCode is a code of the emergency_types list.

Operation ID: `create`

**Request body** (required)

- `application/json`: [Case](#case)

**Responses**

- `200` OK — `application/json` → [CaseCreated](#casecreated)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Concurrent change or record no longer available: CONFLICT, CALL_UNAVAILABLE or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/cases/{id}/ready`

**Mark the case ready for a hospital (urgency_set)**

Operation ID: `ready`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → [CaseState](#casestate)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Concurrent change or record no longer available: CONFLICT, CALL_UNAVAILABLE or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/cases/{id}/hospital-requests`

**Send the case to a hospital**

The hospital answers before deadlineAt. A not_working ER needs overrideReason; a hospital in another state needs crossStateReason and is allowed for CALL_SUPERVISOR only (database rule).

Operation ID: `request`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [Request](#request)

**Responses**

- `200` OK — `application/json` → [HospitalRequestSent](#hospitalrequestsent)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Concurrent change or record no longer available: CONFLICT, CALL_UNAVAILABLE or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/cases/{id}/close`

**Close the case**

closingReason is a code of the closing_reasons list (e.g. advice given, treated at scene).

Operation ID: `close`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [Close](#close)

**Responses**

- `200` OK — `application/json` → [CaseState](#casestate)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Concurrent change or record no longer available: CONFLICT, CALL_UNAVAILABLE or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/calls`

**Start a 999 call**

Records the incoming call for the agent. Link it to a case with POST /cases (callId) or end it with PATCH /calls/{id}.

Operation ID: `call`

**Request body** (required)

- `application/json`: [Call](#call)

**Responses**

- `200` OK — `application/json` → [CallView](#callview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Concurrent change or record no longer available: CONFLICT, CALL_UNAVAILABLE or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/app-requests/{callId}/take`

**Take a citizen SOS**

Assigns the waiting app request to the agent; then create its case with POST /cases (callId) or close it with POST /app-requests/{callId}/close.

Operation ID: `take`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `callId` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → [CallTaken](#calltaken)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Concurrent change or record no longer available: CONFLICT, CALL_UNAVAILABLE or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `PATCH /api/v1/cases/{id}/priority`

**Override the priority**

A reason is required and recorded in the priority history.

Operation ID: `priority`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [Priority](#priority)

**Responses**

- `200` OK — `application/json` → [CaseState](#casestate)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Concurrent change or record no longer available: CONFLICT, CALL_UNAVAILABLE or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `PATCH /api/v1/calls/{id}`

**End a call without a case**

result is a call result (e.g. prank, not_emergency, duplicate, dropped, information_only, passed_to_other_agency); in_progress keeps it open. Refused once a case exists (CALL_HAS_CASE).

Operation ID: `callUpdate`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [CallUpdate](#callupdate)

**Responses**

- `200` OK — `application/json` → [CallView](#callview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Concurrent change or record no longer available: CONFLICT, CALL_UNAVAILABLE or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/triage/questions`

**Active triage questions of a model**

Operation ID: `questions`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `model` | query | string | no |  |
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `questionCode`, `modelVersion` | no | Default: question order of the model |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |

**Responses**

- `200` OK — `application/json` → [ApiPageTriageQuestion](#apipagetriagequestion)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/geo/search`

**Search areas and landmarks by name**

Operation ID: `search_2`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `q` | query | string | yes | Area or landmark name, Arabic or English |
| `lon` | query | number(double) | no | With lat: rank nearer places first |
| `lat` | query | number(double) | no |  |
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `score`, `distanceM`, `nameAr`, `nameEn` | no | Default: best match, then nearest |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |

**Responses**

- `200` OK — `application/json` → [ApiPagePlaceMatch](#apipageplacematch)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/geo/pin-circle`

**Pin circle clipped to mapped areas**

GeoJSON of the circle around the pin, clipped to active areas in the agent's states. 404 when the pin is outside every mapped area.

Operation ID: `circle`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `lon` | query | number(double) | yes |  |
| `lat` | query | number(double) | yes |  |
| `radius` | query | integer(int32) | no | Metres |

**Responses**

- `200` OK — `application/json` → [GeoShape](#geoshape)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Pin is outside every mapped area: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/geo/find-area`

**Area, locality and state at a pin**

Operation ID: `find`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `lon` | query | number(double) | yes |  |
| `lat` | query | number(double) | yes |  |
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `areaNameAr`, `areaNameEn`, `areaLevel` | no |  |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |

**Responses**

- `200` OK — `application/json` → [ApiPageAreaMatch](#apipageareamatch)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/geo/areas-near-pin`

**Areas within a radius of the pin**

Operation ID: `near`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `lon` | query | number(double) | yes |  |
| `lat` | query | number(double) | yes |  |
| `radius` | query | integer(int32) | no | Metres |
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `distanceM`, `areaNameAr`, `areaNameEn` | no | Default: nearest first |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |

**Responses**

- `200` OK — `application/json` → [ApiPageNearbyArea](#apipagenearbyarea)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/cases/{id}/nearest-hospitals`

**Nearest hospitals for the case**

Up to 3 hospitals in the case's state, nearest first, with ER status and ambulances available now.

Operation ID: `nearest`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → [NearestHospital](#nearesthospital)[]
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/cases/duplicates`

**Possible duplicate cases**

Open cases with the same caller phone or near the pin (setting duplicates.radius_m, duplicates.window_minutes).

Operation ID: `duplicates`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `phone` | query | string | no | Caller phone; phone or lon/lat is required |
| `lon` | query | number(double) | no |  |
| `lat` | query | number(double) | no |  |
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `distanceM`, `caseNumber`, `priority` | no | Default: same phone first, then nearest |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |

**Responses**

- `200` OK — `application/json` → [ApiPageDuplicateCase](#apipageduplicatecase)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

## ops-controller

### `PUT /api/v1/cases/{id}/mci-tag`

**Set a case's START colour**

red, yellow, green or black; the case must belong to an incident.

Operation ID: `mciTag`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [MciTag](#mcitag)

**Responses**

- `200` OK — `application/json` → [MciTagged](#mcitagged)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Concurrent change or record no longer available: CONFLICT, CALL_UNAVAILABLE or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `PUT /api/v1/admin/triage-instructions/{id}`

**Edit an instruction card**

Replaces the card's text; status active publishes it to agents.

Operation ID: `updateInstruction`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [InstructionInput](#instructioninput)

**Responses**

- `200` OK — `application/json` → [InstructionCard](#instructioncard)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/admin/hospitals/{id}/capabilities`

**Hospital capabilities**

Codes from list hospital_capabilities (cath lab, stroke unit, CT, ICU, burns, obstetrics…).

Operation ID: `hospitalCapabilities`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → [Capability](#capability)[]
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `PUT /api/v1/admin/hospitals/{id}/capabilities`

**Replace hospital capabilities**

Send the full list; codes must be active items of list hospital_capabilities.

Operation ID: `setCapabilities`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [Capabilities](#capabilities)

**Responses**

- `200` OK — `application/json` → [Capability](#capability)[]
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/sms/inbound`

**Inbound SMS from the gateway**

Called by the SMS gateway for the SOS short code, with header X-Sms-Secret. Creates an SMS SOS in the citizen queue (or adds to the caller's open one) and replies to the sender.

Operation ID: `inboundSms`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `X-Sms-Secret` | header | string | no |  |

**Request body** (required)

- `application/json`: [InboundSms](#inboundsms)

**Responses**

- `200` OK — `application/json` → [InboundAccepted](#inboundaccepted)

---

### `GET /api/v1/qa/reviews`

**Recent reviews**

The last 100 reviews of calls in my states.

Operation ID: `qaReviews`

**Responses**

- `200` OK — `application/json` → [QaReview](#qareview)[]
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/qa/reviews`

**Review a call**

Score 0-100, protocol followed, time target met. One review per call per reviewer (409 CONFLICT on a second).

Operation ID: `qaReview`

**Request body** (required)

- `application/json`: [QaInput](#qainput)

**Responses**

- `200` OK — `application/json` → [QaReview](#qareview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Concurrent change or record no longer available: CONFLICT, CALL_UNAVAILABLE or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/incidents`

**Incidents in my states**

Open incidents, or all=true for the last 100 including closed.

Operation ID: `incidents`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `all` | query | boolean | no |  |

**Responses**

- `200` OK — `application/json` → [IncidentSummary](#incidentsummary)[]
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/incidents`

**Open a mass-casualty incident**

The state comes from the location (or the agent's only state).

Operation ID: `createIncident`

**Request body** (required)

- `application/json`: [NewIncident](#newincident)

**Responses**

- `200` OK — `application/json` → [IncidentSummary](#incidentsummary)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Concurrent change or record no longer available: CONFLICT, CALL_UNAVAILABLE or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/incidents/{id}/close`

**Close an incident**

Supervisor only.

Operation ID: `closeIncident`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → [IncidentSummary](#incidentsummary)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Concurrent change or record no longer available: CONFLICT, CALL_UNAVAILABLE or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/incidents/{id}/cases`

**Add a case to an incident**

Same state, incident open.

Operation ID: `addIncidentCase`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [AddCase](#addcase)

**Responses**

- `200` OK — `application/json` → [IncidentSummary](#incidentsummary)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Concurrent change or record no longer available: CONFLICT, CALL_UNAVAILABLE or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/dispatches/{id}/alerts`

**Raise a pre-arrival alert**

Crew on the job's shift flag a stroke, STEMI, trauma, sepsis, cardiac arrest or obstetric patient. The receiving ER gets job.alert on its hospital channel.

Operation ID: `raiseAlert`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [RaiseAlert](#raisealert)

**Responses**

- `200` OK — `application/json` → [DispatchAlert](#dispatchalert)

---

### `POST /api/v1/dispatch-alerts/{id}/acknowledge`

**Acknowledge a pre-arrival alert**

Hospital ER of the receiving hospital.

Operation ID: `acknowledgeAlert`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → [DispatchAlert](#dispatchalert)

---

### `POST /api/v1/cross-state-approvals/{id}/reject`

**Reject a cross-state request**

A note is required.

Operation ID: `reject`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [Decision](#decision)

**Responses**

- `200` OK — `application/json` → [CrossStateApproval](#crossstateapproval)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Concurrent change or record no longer available: CONFLICT, CALL_UNAVAILABLE or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/cross-state-approvals/{id}/approve`

**Approve a cross-state request**

Sends the hospital request as the supervisor with the agent's reason.

Operation ID: `approve`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body**

- `application/json`: [Decision](#decision)

**Responses**

- `200` OK — `application/json` → [CrossStateApproval](#crossstateapproval)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Concurrent change or record no longer available: CONFLICT, CALL_UNAVAILABLE or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/cases/{id}/reassign`

**Reassign a case to another agent**

Supervisor only. The new agent must be an active call-centre user who covers the case's state. The reason is stored in the access log.

Operation ID: `reassignCase`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [Reassign](#reassign)

**Responses**

- `200` OK — `application/json` → [Reassigned](#reassigned)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Concurrent change or record no longer available: CONFLICT, CALL_UNAVAILABLE or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/cases/{id}/outcome`

**Record the patient outcome**

Receiving hospital staff (ER, records staff, doctor): admitted, discharged, transferred, died or left without care. A later call replaces it.

Operation ID: `outcome`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [OutcomeInput](#outcomeinput)

**Responses**

- `200` OK — `application/json` → [Outcome](#outcome)

---

### `POST /api/v1/cases/{id}/cross-state-approvals`

**Ask a supervisor for a cross-state hospital**

One pending request per case. The supervisor approves (the hospital request is sent) or rejects with a note.

Operation ID: `askCrossState`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [CrossStateAsk](#crossstateask)

**Responses**

- `200` OK — `application/json` → [CrossStateApproval](#crossstateapproval)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Concurrent change or record no longer available: CONFLICT, CALL_UNAVAILABLE or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/app-requests/{callId}/reassign`

**Reassign a citizen SOS to another agent**

Supervisor only; for an SOS still waiting or taken. The reason is stored in the access log.

Operation ID: `reassignSos`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `callId` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [Reassign](#reassign)

**Responses**

- `200` OK — `application/json` → [Reassigned](#reassigned)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Concurrent change or record no longer available: CONFLICT, CALL_UNAVAILABLE or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/admin/triage-instructions`

**Instruction cards (admin)**

Every card, active and inactive.

Operation ID: `instructions`

**Responses**

- `200` OK — `application/json` → [InstructionCard](#instructioncard)[]
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/admin/triage-instructions`

**Create an instruction card**

New cards are inactive unless status is given. Arabic and English steps must have the same count.

Operation ID: `createInstruction`

**Request body** (required)

- `application/json`: [InstructionInput](#instructioninput)

**Responses**

- `200` OK — `application/json` → [InstructionCard](#instructioncard)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/supervisor/approvals`

**Pending cross-state requests**

Supervisor: requests for cases in my states.

Operation ID: `approvals`

**Responses**

- `200` OK — `application/json` → [CrossStateApproval](#crossstateapproval)[]
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/supervisor/agents`

**Agents today**

Calls answered, cases created, average answer time and open work per agent in the supervisor's states (Khartoum day).

Operation ID: `agents`

**Responses**

- `200` OK — `application/json` → [AgentToday](#agenttoday)[]
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/qa/sample`

**Calls to review**

A random sample (size 1-50) of finished calls from the last 30 days in my states that I have not reviewed.

Operation ID: `qaSample`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `size` | query | integer(int32) | no |  |

**Responses**

- `200` OK — `application/json` → [QaCandidate](#qacandidate)[]
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/incidents/{id}`

**Incident board**

Cases with their START colour and hospital, and the load per hospital.

Operation ID: `incident`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → [IncidentBoard](#incidentboard)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/hospital/arrivals`

**Ambulances coming to my hospital**

Hospital ER: active jobs for cases accepted by this hospital, with last position, ETA and alerts.

Operation ID: `arrivals`

**Responses**

- `200` OK — `application/json` → [Arrival](#arrival)[]

---

### `GET /api/v1/fhir/Encounter/{id}`

**Case as a FHIR R4 Bundle**

Encounter, Patient and vital-sign Observations (LOINC) for a hospital's own case. Patient reads follow the patient access rules and are logged.

Operation ID: `fhirEncounter`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/fhir+json` → map<string, any>, `application/json` → map<string, any>

---

### `GET /api/v1/cases/{id}/jobs`

**Ambulance jobs on a case**

Status steps, crew with phone numbers, last GPS point with its age, phone-call log, ETA, and confirmationLate when the crew has not confirmed in time. Call centre, system admin (read-only) and the case's hospital ER.

Operation ID: `caseDispatches`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → [CaseDispatch](#casedispatch)[]
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/cases/{id}/instructions`

**Pre-arrival instructions for a case**

Active cards for the case's emergency type and priority (a card with no type or priority applies to all). Drafts stay inactive until the clinical lead approves them.

Operation ID: `caseInstructions`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → [InstructionCard](#instructioncard)[]
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/cases/{id}/cross-state-hospitals`

**Hospitals in other states**

The 10 nearest hospitals outside the case's state, with ER status, free ambulances and capabilities.

Operation ID: `crossStateHospitals`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → [CrossStateHospital](#crossstatehospital)[]
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/cases/{id}/ambulance-options`

**Available ambulances ranked by ETA**

Ambulances available in the case's state (hospital ER: own hospital), ranked by time to the case pin. Start point: GPS from the last 10 minutes, else the ambulance's hospital. etaMethod road = OSRM routing, estimate = straight line × 1.4 at 40 km/h. Ambulances with no crew on shift sort last.

Operation ID: `ambulanceOptions`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → [AmbulanceOption](#ambulanceoption)[]
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

## admin-controller

### `PUT /api/v1/admin/users/{id}/scopes`

Operation ID: `scopes`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [ScopeInput](#scopeinput)[]

**Responses**

- `200` OK — `application/json` → [ScopeView](#scopeview)[]
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `PUT /api/v1/admin/ambulances/{id}/wialon`

Operation ID: `wialon`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [WialonLink](#wialonlink)

**Responses**

- `200` OK — `application/json` → [AmbulanceView](#ambulanceview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/admin/users`

Operation ID: `users`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `username`, `fullNameAr`, `fullNameEn`, `phone`, `roleCode`, `status`, `createdAt` | no |  |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |
| `includeTotal` | query | boolean | no | true adds totalElements (one extra count query) |
| `search` | query | string | no | Names, phone or username |
| `roleCode` | query | string | no |  |
| `stateId` | query | string(uuid) | no |  |
| `hospitalId` | query | string(uuid) | no |  |
| `ids` | query | string | no | Comma-separated user ids (1-100) to resolve names, e.g. waivedBy or updatedBy values |

**Responses**

- `200` OK — `application/json` → [ApiPageUserView](#apipageuserview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/admin/users`

Operation ID: `user`

**Request body** (required)

- `application/json`: [UserCreate](#usercreate)

**Responses**

- `201` Created — `application/json` → [UserCreated](#usercreated)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/admin/users/{id}/unlock`

**Unlock an account locked after wrong passwords**

Clears the lock and wrong-password count. Calling it on an unlocked account changes nothing.

Operation ID: `unlock`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → [UserView](#userview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/admin/users/{id}/reset-password`

**Reset a user's password**

Old password stops working, all sessions end, mustChangePassword is set and a reset code is sent by SMS. The user sets a new password with POST /api/v1/auth/reset-password.

Operation ID: `resetPassword`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body**

- `application/json`: [ActionReason](#actionreason)

**Responses**

- `200` OK — `application/json` → [PasswordResetIssued](#passwordresetissued)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/admin/users/{id}/enable`

Operation ID: `enable`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → [UserView](#userview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/admin/users/{id}/disable`

Operation ID: `disable`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body**

- `application/json`: [ActionReason](#actionreason)

**Responses**

- `200` OK — `application/json` → [UserView](#userview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/admin/triage-questions`

Operation ID: `triageQuestions`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `sortOrder`, `questionCode`, `modelVersion`, `status`, `createdAt` | no |  |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |
| `includeTotal` | query | boolean | no | true adds totalElements (one extra count query) |
| `triageModel` | query | string | no |  |
| `modelVersion` | query | string | no |  |
| `status` | query | string enum: `active`, `inactive` | no |  |
| `search` | query | string | no |  |

**Responses**

- `200` OK — `application/json` → [ApiPageTriageQuestionView](#apipagetriagequestionview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/admin/triage-questions`

Operation ID: `triageQuestion`

**Request body** (required)

- `application/json`: [TriageQuestionCreate](#triagequestioncreate)

**Responses**

- `201` Created — `application/json` → [TriageQuestionView](#triagequestionview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/admin/lists/{code}/items`

Operation ID: `items`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `code` | path | string | yes |  |
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `code`, `nameAr`, `nameEn`, `status`, `sortOrder`, `createdAt` | no |  |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |
| `includeTotal` | query | boolean | no | true adds totalElements (one extra count query) |
| `search` | query | string | no |  |
| `status` | query | string enum: `active`, `inactive` | no |  |

**Responses**

- `200` OK — `application/json` → [ApiPageListItemView](#apipagelistitemview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/admin/lists/{code}/items`

Operation ID: `item`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `code` | path | string | yes |  |

**Request body** (required)

- `application/json`: [ListItemCreate](#listitemcreate)

**Responses**

- `201` Created — `application/json` → [ListItemView](#listitemview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/admin/landmarks`

Operation ID: `landmarks`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `nameAr`, `nameEn`, `status`, `type`, `createdAt` | no |  |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |
| `includeTotal` | query | boolean | no | true adds totalElements (one extra count query) |
| `search` | query | string | no |  |
| `status` | query | string enum: `pending`, `approved`, `rejected` | no |  |

**Responses**

- `200` OK — `application/json` → [ApiPageLandmarkView](#apipagelandmarkview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/admin/landmarks`

Operation ID: `landmark`

**Request body** (required)

- `application/json`: [LandmarkCreate](#landmarkcreate)

**Responses**

- `201` Created — `application/json` → [LandmarkView](#landmarkview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/admin/landmarks/{id}/reject`

Operation ID: `reject_1`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → [LandmarkView](#landmarkview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/admin/landmarks/{id}/approve`

Operation ID: `approve_1`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → [LandmarkView](#landmarkview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/admin/hospitals`

Operation ID: `hospitals`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `nameAr`, `nameEn`, `code`, `erStatus`, `createdAt` | no |  |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |
| `includeTotal` | query | boolean | no | true adds totalElements (one extra count query) |
| `search` | query | string | no |  |
| `stateId` | query | string(uuid) | no |  |
| `localityId` | query | string(uuid) | no |  |

**Responses**

- `200` OK — `application/json` → [ApiPageHospitalView](#apipagehospitalview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/admin/hospitals`

Operation ID: `hospital`

**Request body** (required)

- `application/json`: [HospitalCreate](#hospitalcreate)

**Responses**

- `201` Created — `application/json` → [HospitalView](#hospitalview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/admin/devices/{id}/revoke`

**Log a device out without blocking it**

Revokes every active session on the device. The owner can sign in again on it.

Operation ID: `revoke`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body**

- `application/json`: [ActionReason](#actionreason)

**Responses**

- `200` OK — `application/json` → [SessionsRevoked](#sessionsrevoked)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/admin/areas`

Operation ID: `areas`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `nameAr`, `nameEn`, `level`, `status`, `createdAt` | no |  |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |
| `includeTotal` | query | boolean | no | true adds totalElements (one extra count query) |
| `search` | query | string | no |  |
| `localityId` | query | string(uuid) | no |  |
| `stateId` | query | string(uuid) | no |  |

**Responses**

- `200` OK — `application/json` → [ApiPageAreaView](#apipageareaview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/admin/areas`

Operation ID: `area`

**Request body** (required)

- `application/json`: [AreaCreate](#areacreate)

**Responses**

- `201` Created — `application/json` → [AreaView](#areaview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/admin/areas/import`

**Import areas from a GeoJSON FeatureCollection**

Field name file. Use dryRun=true first to preview the report without saving; at most 5 MB and 1000 features. Each feature's properties use the AreaCreate fields except boundary, which is the feature geometry. Valid rows are saved; rejected rows are reported.

Operation ID: `importAreas`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `dryRun` | query | boolean | no | true: check every row exactly as a real import would (database rules, overlaps, duplicates), save nothing and return the same report |

**Request body**

- `multipart/form-data`:
  - `file`: string(binary) (required)

**Responses**

- `200` OK — `application/json` → [Report](#report)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `413` Upload larger than allowed: FILE_TOO_LARGE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/admin/ambulances`

Operation ID: `ambulances_1`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `plateNumber`, `type`, `status`, `createdAt` | no |  |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |
| `includeTotal` | query | boolean | no | true adds totalElements (one extra count query) |
| `search` | query | string | no | Plate number contains |
| `hospitalId` | query | string(uuid) | no |  |
| `status` | query | string enum: `available`, `busy`, `not_working` | no |  |

**Responses**

- `200` OK — `application/json` → [ApiPageAmbulanceView](#apipageambulanceview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/admin/ambulances`

Operation ID: `ambulance_1`

**Request body** (required)

- `application/json`: [AmbulanceCreate](#ambulancecreate)

**Responses**

- `201` Created — `application/json` → [AmbulanceView](#ambulanceview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/admin/users/{id}`

Operation ID: `userDetail`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → [UserDetail](#userdetail)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `PATCH /api/v1/admin/users/{id}`

Operation ID: `user_1`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [UserEdit](#useredit)

**Responses**

- `200` OK — `application/json` → [UserView](#userview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/admin/triage-questions/{id}`

Operation ID: `triageQuestionDetail`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → [TriageQuestionView](#triagequestionview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `PATCH /api/v1/admin/triage-questions/{id}`

**Edit or disable a triage question**

Set status to inactive to disable it; new cases stop offering it. Existing answers are kept.

Operation ID: `triageQuestion_1`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [TriageQuestionEdit](#triagequestionedit)

**Responses**

- `200` OK — `application/json` → [TriageQuestionView](#triagequestionview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `PATCH /api/v1/admin/settings/{key}`

Operation ID: `setting`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `key` | path | string | yes |  |

**Request body** (required)

- `application/json`: [SettingChange](#settingchange)

**Responses**

- `200` OK — `application/json` → [SettingView](#settingview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `PATCH /api/v1/admin/lists/{code}/items/{id}`

Operation ID: `item_1`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `code` | path | string | yes |  |
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [ListItemEdit](#listitemedit)

**Responses**

- `200` OK — `application/json` → [ListItemView](#listitemview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/admin/landmarks/{id}`

Operation ID: `landmarkDetail`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → [LandmarkView](#landmarkview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `PATCH /api/v1/admin/landmarks/{id}`

Operation ID: `landmark_1`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [LandmarkEdit](#landmarkedit)

**Responses**

- `200` OK — `application/json` → [LandmarkView](#landmarkview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/admin/hospitals/{id}`

Operation ID: `hospitalDetail`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → [HospitalView](#hospitalview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `PATCH /api/v1/admin/hospitals/{id}`

Operation ID: `hospital_1`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [HospitalEdit](#hospitaledit)

**Responses**

- `200` OK — `application/json` → [HospitalView](#hospitalview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/admin/areas/{id}`

Operation ID: `areaDetail`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → [AreaView](#areaview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `PATCH /api/v1/admin/areas/{id}`

Operation ID: `area_1`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [AreaEdit](#areaedit)

**Responses**

- `200` OK — `application/json` → [AreaView](#areaview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/admin/ambulances/{id}`

Operation ID: `ambulanceDetail`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → [AmbulanceView](#ambulanceview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `PATCH /api/v1/admin/ambulances/{id}`

Operation ID: `ambulance_3`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [AmbulanceEdit](#ambulanceedit)

**Responses**

- `200` OK — `application/json` → [AmbulanceView](#ambulanceview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/admin/waivers`

**Waived ambulance charges (read-only)**

Limited to the admin's report scope (state or national). Waivers are created by hospital staff; admins cannot create or approve them.

Operation ID: `waivers`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `waivedAt`, `total`, `hospitalId` | no |  |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |
| `includeTotal` | query | boolean | no | true adds totalElements (one extra count query) |
| `stateId` | query | string(uuid) | no |  |
| `hospitalId` | query | string(uuid) | no |  |
| `from` | query | string(date-time) | no | Waived at or after |
| `to` | query | string(date-time) | no | Waived at or before |

**Responses**

- `200` OK — `application/json` → [ApiPageWaiverView](#apipagewaiverview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/admin/triage-questions/{id}/history`

**Change history of a triage question**

Who changed it, when, and the values before and after each change.

Operation ID: `triageHistory`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `occurredAt` | no |  |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |
| `includeTotal` | query | boolean | no | true adds totalElements (one extra count query) |

**Responses**

- `200` OK — `application/json` → [ApiPageTriageHistoryView](#apipagetriagehistoryview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/admin/trackers`

Operation ID: `trackers`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `plateNumber`, `status`, `wialonUnitId`, `createdAt` | no |  |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |
| `includeTotal` | query | boolean | no | true adds totalElements (one extra count query) |
| `hospitalId` | query | string(uuid) | no |  |
| `status` | query | string enum: `silent`, `no_data_yet`, `not_linked`, `ok` | no |  |

**Responses**

- `200` OK — `application/json` → [ApiPageTrackerView](#apipagetrackerview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/admin/settings`

Operation ID: `settings`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `key`, `value`, `valueType`, `updatedAt` | no |  |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |
| `includeTotal` | query | boolean | no | true adds totalElements (one extra count query) |

**Responses**

- `200` OK — `application/json` → [ApiPageSettingView](#apipagesettingview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/admin/settings/{key}/history`

Operation ID: `settingsHistory`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `key` | path | string | yes |  |
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `changedAt` | no |  |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |
| `includeTotal` | query | boolean | no | true adds totalElements (one extra count query) |

**Responses**

- `200` OK — `application/json` → [ApiPageSettingHistoryView](#apipagesettinghistoryview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/admin/localities`

**Localities for area and hospital forms**

Use with GET /api/v1/states (shared contract) for the state picker.

Operation ID: `localities`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `nameAr`, `nameEn`, `createdAt` | no |  |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |
| `includeTotal` | query | boolean | no | true adds totalElements (one extra count query) |
| `stateId` | query | string(uuid) | no |  |
| `status` | query | string enum: `active`, `inactive` | no |  |
| `search` | query | string | no |  |

**Responses**

- `200` OK — `application/json` → [ApiPageLocalityView](#apipagelocalityview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/admin/lists`

Operation ID: `lists`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `code`, `nameAr`, `nameEn` | no |  |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |
| `includeTotal` | query | boolean | no | true adds totalElements (one extra count query) |

**Responses**

- `200` OK — `application/json` → [ApiPageListTypeView](#apipagelisttypeview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/admin/devices`

**Search devices of any user**

Find a lost phone by owner, app or blocked state, then block it (POST /api/v1/devices/{id}/block) or only log it out (POST /api/v1/admin/devices/{id}/revoke).

Operation ID: `devices`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `createdAt`, `lastSeenAt`, `clientApp`, `username` | no |  |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |
| `includeTotal` | query | boolean | no | true adds totalElements (one extra count query) |
| `search` | query | string | no | Username, names or phone of the owner |
| `userId` | query | string(uuid) | no |  |
| `clientApp` | query | string enum: `staff_web`, `crew_app`, `citizen_app` | no |  |
| `blocked` | query | boolean | no |  |

**Responses**

- `200` OK — `application/json` → [ApiPageDeviceView](#apipagedeviceview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/admin/access-log`

Operation ID: `access`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `occurredAt`, `action`, `entityType`, `userId` | no |  |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |
| `includeTotal` | query | boolean | no | true adds totalElements (one extra count query) |
| `userId` | query | string(uuid) | no |  |
| `action` | query | string | no |  |
| `entityType` | query | string | no |  |
| `entityId` | query | string(uuid) | no |  |
| `from` | query | string(date-time) | no |  |
| `to` | query | string(date-time) | no |  |
| `denied` | query | boolean | no | true: only refusals (reason starts with DENIED), e.g. a 403 outside the caller's scope |

**Responses**

- `200` OK — `application/json` → [ApiPageAccessLogView](#apipageaccesslogview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

## hospital-operations-controller

### `GET /api/v1/hospitals/{id}/recommended-checks`

Operation ID: `checks`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |
| `q` | query | map<string, string> | yes |  |

**Responses**

- `200` OK — `application/json` → [Page](#page)

---

### `POST /api/v1/hospitals/{id}/recommended-checks`

Operation ID: `check_1`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: map<string, any>

**Responses**

- `201` Created — `application/json` → map<string, any>

---

### `GET /api/v1/ambulances`

Operation ID: `ambulances`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `q` | query | map<string, string> | yes |  |

**Responses**

- `200` OK — `application/json` → [Page](#page)

---

### `POST /api/v1/ambulances`

Operation ID: `ambulance`

**Request body** (required)

- `application/json`: map<string, any>

**Responses**

- `201` Created — `application/json` → map<string, any>

---

### `PATCH /api/v1/hospitals/{id}/status`

Operation ID: `status_1`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [HospitalStatusChange](#hospitalstatuschange)

**Responses**

- `200` OK — `application/json` → [HospitalView](#hospitalview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `PATCH /api/v1/hospitals/{id}/recommended-checks/{checkId}`

Operation ID: `check_2`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |
| `checkId` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: map<string, any>

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `PATCH /api/v1/ambulances/{id}`

Operation ID: `ambulance_2`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: map<string, any>

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `GET /api/v1/search`

Operation ID: `search`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `search` | query | string | yes | Arabic or English place name |
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `nameAr`, `nameEn`, `kind` | no |  |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |

**Responses**

- `200` OK — `application/json` → [ApiPagePlaceView](#apipageplaceview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Wrong credentials or code, or missing/expired token: INVALID_CREDENTIALS, INVALID_CHALLENGE, UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Account disabled, password change required or role not allowed. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or SMS service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/hospitals/{id}/status-history`

Operation ID: `history`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `changedAt`, `erStatus` | no |  |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |
| `includeTotal` | query | boolean | no | true adds totalElements (one extra count query) |

**Responses**

- `200` OK — `application/json` → [ApiPageHospitalStatusHistoryView](#apipagehospitalstatushistoryview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/ambulances/{id}/qr.png`

Operation ID: `qr`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` Crew shift QR code image — `image/png` → string(binary)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

## billing-controller

### `GET /api/v1/hospital/tariffs`

Operation ID: `hospitalTariffs`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `validFrom`, `validTo`, `baseFee`, `perKmFee`, `ambulanceType`, `status`, `createdAt` | no |  |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |
| `includeTotal` | query | boolean | no | true adds totalElements (one extra count query) |

**Responses**

- `200` OK — `application/json` → [ApiPageTariffView](#apipagetariffview)

---

### `POST /api/v1/hospital/tariffs`

Operation ID: `hospitalTariff`

**Request body** (required)

- `application/json`: [Tariff](#tariff)

**Responses**

- `200` OK — `application/json` → [TariffView](#tariffview)

---

### `POST /api/v1/charges/{id}/waive`

Operation ID: `waive`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |
| `Idempotency-Key` | header | string | yes |  |

**Request body** (required)

- `application/json`: [Waive](#waive)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/charges/{id}/payments`

Operation ID: `payment`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |
| `Idempotency-Key` | header | string | yes |  |

**Request body** (required)

- `application/json`: [Payment](#payment)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `GET /api/v1/admin/tariffs`

Operation ID: `adminTariffs`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `validFrom`, `validTo`, `baseFee`, `perKmFee`, `ambulanceType`, `status`, `createdAt` | no |  |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |
| `includeTotal` | query | boolean | no | true adds totalElements (one extra count query) |

**Responses**

- `200` OK — `application/json` → [ApiPageTariffView](#apipagetariffview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/admin/tariffs`

State tariff (stateId) or national tariff (no stateId); hospitalId is refused. baseFee is required. Omitted ambulanceType means all types. validTo must not be before validFrom.

Operation ID: `adminTariff`

**Request body** (required)

- `application/json`: [Tariff](#tariff)

**Responses**

- `200` OK — `application/json` → [TariffView](#tariffview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `PATCH /api/v1/hospital/tariffs/{id}`

Operation ID: `hospitalEdit`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [Tariff](#tariff)

**Responses**

- `200` OK — `application/json` → [TariffView](#tariffview)

---

### `PATCH /api/v1/admin/tariffs/{id}`

Omitted fields keep their current values.

Operation ID: `adminEdit`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [Tariff](#tariff)

**Responses**

- `200` OK — `application/json` → [TariffView](#tariffview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Duplicate value or concurrent change: CONFLICT or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/payments/{id}/receipt.pdf`

Operation ID: `receipt`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/pdf` → string(byte)

---

### `GET /api/v1/hospital/charges`

Operation ID: `charges_1`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `status` | query | string | no |  |
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |

**Responses**

- `200` OK — `application/json` → [Page](#page)

---

### `GET /api/v1/cases/{id}/charges`

Operation ID: `caseCharges`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |

**Responses**

- `200` OK — `application/json` → [Page](#page)

---

## dispatch-controller

### `POST /api/v1/hospital-requests/{id}/refuse`

Operation ID: `refuse`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [Refuse](#refuse)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/hospital-requests/{id}/accept`

Operation ID: `accept`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/dispatches/{id}/status`

Operation ID: `status`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |
| `Idempotency-Key` | header | string | yes |  |

**Request body** (required)

- `application/json`: [Status](#status)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/dispatches/{id}/phone-calls`

Operation ID: `phone`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [Phone](#phone)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/dispatches/{id}/confirm`

Operation ID: `confirm_1`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |
| `Idempotency-Key` | header | string | yes |  |

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/dispatches/{id}/cancel`

Operation ID: `cancel_1`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [Cancel](#cancel)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/crew/shifts`

Operation ID: `shift`

**Request body** (required)

- `application/json`: [Shift](#shift)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/crew/shifts/current/join`

Operation ID: `join`

**Request body** (required)

- `application/json`: [Shift](#shift)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/crew/shifts/current/end`

Operation ID: `end_1`

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/crew/gps`

Operation ID: `gps`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `Idempotency-Key` | header | string | yes |  |

**Request body** (required)

- `application/json`: [Point](#point)[]

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `POST /api/v1/cases/{id}/dispatches`

Operation ID: `dispatch`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [Send](#send)

**Responses**

- `200` OK — `application/json` → map<string, any>

---

### `GET /api/v1/hospital/requests`

Operation ID: `requests_1`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |

**Responses**

- `200` OK — `application/json` → [Page](#page)

---

### `GET /api/v1/hospital/incoming`

Operation ID: `incoming`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |

**Responses**

- `200` OK — `application/json` → [Page](#page)

---

### `GET /api/v1/hospital/dispatches/unconfirmed`

Operation ID: `unconfirmed`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |

**Responses**

- `200` OK — `application/json` → [Page](#page)

---

### `GET /api/v1/hospital/ambulances`

Operation ID: `ambulances_3`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |

**Responses**

- `200` OK — `application/json` → [Page](#page)

---

### `GET /api/v1/crew/job`

Operation ID: `job`

**Responses**

- `200` OK — `application/json` → map<string, any>

---

## citizen-controller

### `POST /api/v1/citizens/verify-id-card`

Operation ID: `verifyId`

**Request body** (required)

- `application/json`: [IdCard](#idcard)

**Responses**

- `200` OK — `application/json` → object

---

### `POST /api/v1/citizen/sign-up/start`

Operation ID: `start`

**Request body** (required)

- `application/json`: [Start](#start)

**Responses**

- `200` OK — `application/json` → object

---

### `POST /api/v1/citizen/sign-up/finish`

Operation ID: `finish`

**Request body** (required)

- `application/json`: [Finish](#finish)

**Responses**

- `200` OK — `application/json` → object

---

### `GET /api/v1/citizen/requests`

Operation ID: `requests`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |

**Responses**

- `200` OK — `application/json` → [Page](#page)

---

### `POST /api/v1/citizen/requests`

Operation ID: `sos`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `Idempotency-Key` | header | string | no |  |

**Request body** (required)

- `application/json`: [Sos](#sos)

**Responses**

- `200` OK — `application/json` → object

---

### `POST /api/v1/citizen/dependants`

Operation ID: `dependant`

**Request body** (required)

- `application/json`: [Dependant](#dependant)

**Responses**

- `200` OK — `application/json` → object

---

### `POST /api/v1/citizen-dependants/{id}/verify`

Operation ID: `verifyDependant`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → object

---

### `POST /api/v1/app-requests/{callId}/close`

**Close a citizen SOS without a case**

Agents and supervisors; an SOS taken by another agent can be closed only by a supervisor.

Operation ID: `close_1`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `callId` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [SosClose](#sosclose)

**Responses**

- `200` OK — `application/json` → [AppRequestClosed](#apprequestclosed)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `409` Concurrent change or record no longer available: CONFLICT, CALL_UNAVAILABLE or a specific code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/admin/citizens/{userId}/unsuspend`

Operation ID: `unsuspend`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `userId` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → object

---

### `POST /api/v1/admin/citizens/{userId}/suspend`

Operation ID: `suspend`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `userId` | path | string(uuid) | yes |  |

**Request body** (required)

- `application/json`: [Suspend](#suspend)

**Responses**

- `200` OK — `application/json` → object

---

### `GET /api/v1/citizen/requests/{id}`

Operation ID: `status_2`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → object

---

### `GET /api/v1/citizen/me`

Operation ID: `me_1`

**Responses**

- `200` OK — `application/json` → object

---

### `GET /api/v1/citizen/history`

Operation ID: `history_1`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `patientId` | query | string(uuid) | no |  |
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |

**Responses**

- `200` OK — `application/json` → object

---

## read-controller

### `GET /api/v1/calls`

**Calls (read-only, system administrator)**

999 phone calls and citizen-app SOS in the admin's report scope, newest first. Writes stay with the call centre.

Operation ID: `calls`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `startedAt`, `result`, `channel`, `stateCode` | no | Default: newest call first |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |

**Responses**

- `200` OK — `application/json` → [ApiPageCallRecord](#apipagecallrecord)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/calls/{id}`

**One call (read-only, system administrator)**

403 OUTSIDE_SCOPE (logged) when the call's state is outside the admin's report scope.

Operation ID: `call_1`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → [CallRecord](#callrecord)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/supervisor/overview`

**Supervisor numbers per state**

Operation ID: `overview`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `stateCode`, `item`, `itemCount` | no |  |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |

**Responses**

- `200` OK — `application/json` → [ApiPageOverviewItem](#apipageoverviewitem)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/states`

Operation ID: `states`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `code`, `nameAr`, `nameEn`, `createdAt` | no |  |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |

**Responses**

- `200` OK — `application/json` → [ApiPageStateView](#apipagestateview)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Wrong credentials or code, or missing/expired token: INVALID_CREDENTIALS, INVALID_CHALLENGE, UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Account disabled, password change required or role not allowed. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or SMS service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/hospitals`

Operation ID: `hospitals_1`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `nameAr`, `nameEn`, `code`, `erStatus`, `createdAt` | no |  |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |

**Responses**

- `200` OK — `application/json` → [ApiPageHospitalSummary](#apipagehospitalsummary)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Wrong credentials or code, or missing/expired token: INVALID_CREDENTIALS, INVALID_CHALLENGE, UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Account disabled, password change required or role not allowed. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or SMS service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/cases/{id}`

**Case detail**

Case with steps, priority changes and hospital requests. Call centre: cases in the agent's states; hospital ER: own hospital; system admin: read-only, within its report scope. callId and callerPhone name the call the case came from.

Operation ID: `caseById`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `id` | path | string(uuid) | yes |  |

**Responses**

- `200` OK — `application/json` → [CaseDetail](#casedetail)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/cases/open`

**Open cases queue**

Call centre: open cases in the agent's states, P1 first then oldest. Hospital ER: open cases of the own hospital. System admin: read-only, within its report scope.

Operation ID: `cases_1`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `priority`, `caseNumber`, `createdAt`, `step` | no | Default: P1 first, then oldest |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |
| `priority` | query | string enum: `P1`, `P2`, `P3`, `P4` | no |  |
| `step` | query | string enum: `call_received`, `urgency_set`, `request_sent`, `hospital_accepted`, `ambulance_sent`, `on_scene`, `transporting`, `handed_over` | no |  |
| `source` | query | string enum: `phone`, `app`, `sms` | no | phone = 999 call, app = citizen app, sms = SMS short code |
| `incidentId` | query | string(uuid) | no |  |

**Responses**

- `200` OK — `application/json` → [ApiPageOpenCase](#apipageopencase)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/app-requests`

**Citizen SOS requests waiting for an agent**

Requests in the agent's states plus requests whose pin is outside every mapped state (stateCode null).

Operation ID: `requests_2`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `page` | query | integer(int32) | no |  |
| `size` | query | integer(int32) | no |  |
| `sort` | query | string enum: `startedAt`, `stateCode` | no | Default: longest waiting first (oldest SOS on top) |
| `direction` | query | string enum: `asc`, `desc`, `default` | no |  |

**Responses**

- `200` OK — `application/json` → [ApiPageAppRequest](#apipageapprequest)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or state scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

## auth-controller

### `POST /api/v1/auth/verify`

Consumes the SMS code and starts a session. For a staff_web device login (clientApp and deviceId sent at login) the refresh token is set as the HttpOnly, Secure, SameSite=Strict cookie emr_refresh (path /api/v1/auth, 12 hours) and refreshToken in the body is null. Mobile apps receive refreshToken in the body.

Operation ID: `verify_1`

**Request body** (required)

- `application/json`: [Verify](#verify)

**Responses**

- `200` OK — `application/json` → [LoginTokens](#logintokens)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Wrong credentials or code, or missing/expired token: INVALID_CREDENTIALS, INVALID_CHALLENGE, UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Account disabled, password change required or role not allowed. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `423` Account locked after wrong passwords: ACCOUNT_LOCKED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `429` Too many attempts or SMS codes: AUTH_RATE_LIMIT, SMS_RATE_LIMIT, RESEND_WAIT, RESEND_LIMIT. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or SMS service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/auth/reset-password`

Operation ID: `reset`

**Request body** (required)

- `application/json`: [Reset](#reset)

**Responses**

- `204` No Content
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Wrong credentials or code, or missing/expired token: INVALID_CREDENTIALS, INVALID_CHALLENGE, UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Account disabled, password change required or role not allowed. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `423` Account locked after wrong passwords: ACCOUNT_LOCKED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `429` Too many attempts or SMS codes: AUTH_RATE_LIMIT, SMS_RATE_LIMIT, RESEND_WAIT, RESEND_LIMIT. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or SMS service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/auth/resend`

Operation ID: `resend`

**Request body** (required)

- `application/json`: [Resend](#resend)

**Responses**

- `200` OK — `application/json` → [Challenge](#challenge)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Wrong credentials or code, or missing/expired token: INVALID_CREDENTIALS, INVALID_CHALLENGE, UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Account disabled, password change required or role not allowed. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `423` Account locked after wrong passwords: ACCOUNT_LOCKED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `429` Too many attempts or SMS codes: AUTH_RATE_LIMIT, SMS_RATE_LIMIT, RESEND_WAIT, RESEND_LIMIT. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or SMS service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/auth/refresh`

Mobile: send refreshToken in the body. Browser: send no body; the emr_refresh cookie is used and the X-Client-App: staff_web header is required (blocks cross-site requests).

Operation ID: `refresh`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `X-Client-App` | header | string | no | Required as staff_web when refreshing with the cookie |

**Request body**

- `application/json`: [Refresh](#refresh)

**Responses**

- `200` OK — `application/json` → [AccessToken](#accesstoken)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Wrong credentials or code, or missing/expired token: INVALID_CREDENTIALS, INVALID_CHALLENGE, UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Account disabled, password change required or role not allowed. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `423` Account locked after wrong passwords: ACCOUNT_LOCKED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `429` Too many attempts or SMS codes: AUTH_RATE_LIMIT, SMS_RATE_LIMIT, RESEND_WAIT, RESEND_LIMIT. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or SMS service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/auth/logout`

Operation ID: `logout`

**Responses**

- `204` No Content
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Wrong credentials or code, or missing/expired token: INVALID_CREDENTIALS, INVALID_CHALLENGE, UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Account disabled, password change required or role not allowed. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `423` Account locked after wrong passwords: ACCOUNT_LOCKED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `429` Too many attempts or SMS codes: AUTH_RATE_LIMIT, SMS_RATE_LIMIT, RESEND_WAIT, RESEND_LIMIT. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or SMS service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/auth/login`

Checks the password. When the app's SMS second factor is on (crew_app and citizen_app; settings auth.sms_second_factor.*) an SMS code is sent and step is sms_code. When it is off (staff_web by default) the session starts at once: step signed_in, no SMS sent, and a staff_web browser gets the emr_refresh cookie as after /auth/verify.

Operation ID: `login`

**Request body** (required)

- `application/json`: [Login](#login)

**Responses**

- `200` OK — `application/json` → [LoginResult](#loginresult)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Wrong credentials or code, or missing/expired token: INVALID_CREDENTIALS, INVALID_CHALLENGE, UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Account disabled, password change required or role not allowed. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `423` Account locked after wrong passwords: ACCOUNT_LOCKED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `429` Too many attempts or SMS codes: AUTH_RATE_LIMIT, SMS_RATE_LIMIT, RESEND_WAIT, RESEND_LIMIT. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or SMS service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/auth/forgot-password`

Operation ID: `forgot`

**Request body** (required)

- `application/json`: [Forgot](#forgot)

**Responses**

- `202` Accepted — `application/json` → [ResetRequested](#resetrequested)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Wrong credentials or code, or missing/expired token: INVALID_CREDENTIALS, INVALID_CHALLENGE, UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Account disabled, password change required or role not allowed. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `423` Account locked after wrong passwords: ACCOUNT_LOCKED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `429` Too many attempts or SMS codes: AUTH_RATE_LIMIT, SMS_RATE_LIMIT, RESEND_WAIT, RESEND_LIMIT. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or SMS service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `POST /api/v1/auth/change-password`

Operation ID: `change`

**Request body** (required)

- `application/json`: [Change](#change)

**Responses**

- `204` No Content
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Wrong credentials or code, or missing/expired token: INVALID_CREDENTIALS, INVALID_CHALLENGE, UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Account disabled, password change required or role not allowed. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `423` Account locked after wrong passwords: ACCOUNT_LOCKED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `429` Too many attempts or SMS codes: AUTH_RATE_LIMIT, SMS_RATE_LIMIT, RESEND_WAIT, RESEND_LIMIT. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or SMS service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

## live-contract

### `GET /v3/asyncapi`

Operation ID: `asyncApi`

**Responses**

- `200` OK — `application/json` → map<string, any>

---

## health-controller

### `GET /health`

Operation ID: `health`

**Responses**

- `200` OK — `application/json` → object

---

## dev-sms-controller

### `GET /dev/sms/latest`

Operation ID: `latest`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `phone` | query | string | yes |  |

**Responses**

- `200` OK — `application/json` → [Message](#message)

---

### `GET /dev/sms/latest-text`

Operation ID: `latestText`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `phone` | query | string | yes |  |

**Responses**

- `200` OK — `application/json` → map<string, string>

---

## report-controller

### `GET /api/v1/reports/{name}/export`

Operation ID: `export`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `name` | path | string enum: `response-times`, `hospital-requests`, `call-centre`, `ambulances`, `cases`, `charges`, `patients` | yes |  |
| `from` | query | string(date) | no | First day, Khartoum time; default 29 days before today |
| `to` | query | string(date) | no | Last day, Khartoum time; default today; at most 5 years after from |
| `stateId` | query | string(uuid) | no | Limit to one state inside the caller's scope |
| `hospitalId` | query | string(uuid) | no |  |
| `priority` | query | string enum: `P1`, `P2`, `P3`, `P4` | no |  |
| `bucket` | query | string enum: `hour`, `day` | no | Time bucket. call-centre: default day. response-times: omit for one row per priority and stage over the whole period; set it for a trend (hour: at most 31 days, day: at most 366 days) |
| `format` | query | string enum: `csv`, `pdf` | yes |  |

**Responses**

- `200` Report file — `text/csv` → string(binary), `application/pdf` → string(binary)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `404` Record not found: NOT_FOUND. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/reports/response-times`

Operation ID: `responseTimes`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `from` | query | string(date) | no | First day, Khartoum time; default 29 days before today |
| `to` | query | string(date) | no | Last day, Khartoum time; default today; at most 5 years after from |
| `stateId` | query | string(uuid) | no | Limit to one state inside the caller's scope |
| `hospitalId` | query | string(uuid) | no |  |
| `priority` | query | string enum: `P1`, `P2`, `P3`, `P4` | no |  |
| `bucket` | query | string enum: `hour`, `day` | no | Time bucket. call-centre: default day. response-times: omit for one row per priority and stage over the whole period; set it for a trend (hour: at most 31 days, day: at most 366 days) |

**Responses**

- `200` OK — `application/json` → [ResponseTimesReport](#responsetimesreport)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/reports/patients`

Operation ID: `patients`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `from` | query | string(date) | no | First day, Khartoum time; default 29 days before today |
| `to` | query | string(date) | no | Last day, Khartoum time; default today; at most 5 years after from |
| `stateId` | query | string(uuid) | no | Limit to one state inside the caller's scope |
| `hospitalId` | query | string(uuid) | no |  |
| `priority` | query | string enum: `P1`, `P2`, `P3`, `P4` | no |  |
| `bucket` | query | string enum: `hour`, `day` | no | Time bucket. call-centre: default day. response-times: omit for one row per priority and stage over the whole period; set it for a trend (hour: at most 31 days, day: at most 366 days) |

**Responses**

- `200` OK — `application/json` → [PatientsReport](#patientsreport)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/reports/hospital-requests`

Operation ID: `hospitalRequests`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `from` | query | string(date) | no | First day, Khartoum time; default 29 days before today |
| `to` | query | string(date) | no | Last day, Khartoum time; default today; at most 5 years after from |
| `stateId` | query | string(uuid) | no | Limit to one state inside the caller's scope |
| `hospitalId` | query | string(uuid) | no |  |
| `priority` | query | string enum: `P1`, `P2`, `P3`, `P4` | no |  |
| `bucket` | query | string enum: `hour`, `day` | no | Time bucket. call-centre: default day. response-times: omit for one row per priority and stage over the whole period; set it for a trend (hour: at most 31 days, day: at most 366 days) |

**Responses**

- `200` OK — `application/json` → [HospitalRequestsReport](#hospitalrequestsreport)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/reports/charges`

Operation ID: `charges`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `from` | query | string(date) | no | First day, Khartoum time; default 29 days before today |
| `to` | query | string(date) | no | Last day, Khartoum time; default today; at most 5 years after from |
| `stateId` | query | string(uuid) | no | Limit to one state inside the caller's scope |
| `hospitalId` | query | string(uuid) | no |  |
| `priority` | query | string enum: `P1`, `P2`, `P3`, `P4` | no |  |
| `bucket` | query | string enum: `hour`, `day` | no | Time bucket. call-centre: default day. response-times: omit for one row per priority and stage over the whole period; set it for a trend (hour: at most 31 days, day: at most 366 days) |

**Responses**

- `200` OK — `application/json` → [ChargesReport](#chargesreport)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/reports/cases`

Operation ID: `cases`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `from` | query | string(date) | no | First day, Khartoum time; default 29 days before today |
| `to` | query | string(date) | no | Last day, Khartoum time; default today; at most 5 years after from |
| `stateId` | query | string(uuid) | no | Limit to one state inside the caller's scope |
| `hospitalId` | query | string(uuid) | no |  |
| `priority` | query | string enum: `P1`, `P2`, `P3`, `P4` | no |  |
| `bucket` | query | string enum: `hour`, `day` | no | Time bucket. call-centre: default day. response-times: omit for one row per priority and stage over the whole period; set it for a trend (hour: at most 31 days, day: at most 366 days) |

**Responses**

- `200` OK — `application/json` → [CasesReport](#casesreport)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/reports/call-centre`

Operation ID: `callCentre`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `from` | query | string(date) | no | First day, Khartoum time; default 29 days before today |
| `to` | query | string(date) | no | Last day, Khartoum time; default today; at most 5 years after from |
| `stateId` | query | string(uuid) | no | Limit to one state inside the caller's scope |
| `hospitalId` | query | string(uuid) | no |  |
| `priority` | query | string enum: `P1`, `P2`, `P3`, `P4` | no |  |
| `bucket` | query | string enum: `hour`, `day` | no | Time bucket. call-centre: default day. response-times: omit for one row per priority and stage over the whole period; set it for a trend (hour: at most 31 days, day: at most 366 days) |

**Responses**

- `200` OK — `application/json` → [CallCentreReport](#callcentrereport)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/reports/ambulances`

Operation ID: `ambulances_2`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `from` | query | string(date) | no | First day, Khartoum time; default 29 days before today |
| `to` | query | string(date) | no | Last day, Khartoum time; default today; at most 5 years after from |
| `stateId` | query | string(uuid) | no | Limit to one state inside the caller's scope |
| `hospitalId` | query | string(uuid) | no |  |
| `priority` | query | string enum: `P1`, `P2`, `P3`, `P4` | no |  |
| `bucket` | query | string enum: `hour`, `day` | no | Time bucket. call-centre: default day. response-times: omit for one row per priority and stage over the whole period; set it for a trend (hour: at most 31 days, day: at most 366 days) |

**Responses**

- `200` OK — `application/json` → [AmbulancesReport](#ambulancesreport)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

### `GET /api/v1/dashboard`

openCases, waitingRequests, availableAmbulances and trackers are current values (state/hospital filters apply). response and charges use the from/to period. Same scope rules and limits as the reports.

Operation ID: `dashboard`

**Parameters**

| Name | In | Type | Required | Description |
|---|---|---|---|---|
| `from` | query | string(date) | no | First day, Khartoum time; default today |
| `to` | query | string(date) | no | Last day, Khartoum time; default today |
| `stateId` | query | string(uuid) | no | Limit to one state inside the caller's scope; omit for all states in scope |
| `hospitalId` | query | string(uuid) | no | Limit to one hospital |

**Responses**

- `200` OK — `application/json` → [DashboardReport](#dashboardreport)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Missing, expired or revoked access token: UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Role or scope does not allow this: FORBIDDEN, OUTSIDE_SCOPE. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or dependent service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

## me-controller

### `GET /api/v1/me`

Operation ID: `me`

**Responses**

- `200` OK — `application/json` → [Me](#me)
- `400` Invalid input: VALIDATION_ERROR or a specific rule code. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `401` Wrong credentials or code, or missing/expired token: INVALID_CREDENTIALS, INVALID_CHALLENGE, UNAUTHORIZED. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `403` Account disabled, password change required or role not allowed. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)
- `503` Database or SMS service unavailable; retry later. Body has code, message_ar, message_en, reference and time. — `application/json` → [ApiError](#apierror)

---

## Schemas

### AccessLogView

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | integer(int64) |  |  |
| `occurredAt` | string(date-time) |  |  |
| `userId` | string(uuid) |  |  |
| `roleCode` | string |  |  |
| `action` | string |  |  |
| `entityType` | string |  |  |
| `entityId` | string(uuid) |  |  |
| `denied` | boolean |  | true when the request was refused (403 outside the caller's scope or role). Free-text reasons are never listed |

### AccessToken

New access token for the session

| Field | Type | Required | Description |
|---|---|---|---|
| `accessToken` | string |  |  |

### ActionReason

Optional written reason for a destructive admin action; stored in the access log

| Field | Type | Required | Description |
|---|---|---|---|
| `reason` | string |  |  |

### AddCase

| Field | Type | Required | Description |
|---|---|---|---|
| `caseId` | string(uuid) | yes |  |

### AgentToday

One agent's work today in the supervisor's states

| Field | Type | Required | Description |
|---|---|---|---|
| `agentId` | string(uuid) |  |  |
| `nameAr` | string |  |  |
| `nameEn` | string |  |  |
| `role` | string enum: `CALL_CENTRE`, `CALL_SUPERVISOR` |  |  |
| `callsAnswered` | integer(int32) |  |  |
| `casesCreated` | integer(int32) |  |  |
| `avgAnswerSeconds` | integer(int32) |  |  |
| `openCases` | integer(int32) |  |  |
| `openSos` | integer(int32) |  |  |

### AmbulanceCreate

New ambulance.

| Field | Type | Required | Description |
|---|---|---|---|
| `type` | string enum: `basic`, `advanced` | yes |  |
| `status` | string enum: `available`, `busy`, `not_working` |  |  |
| `recordStatus` | string enum: `active`, `inactive` |  |  |
| `hospitalId` | string(uuid) | yes |  |
| `plateNumber` | string | yes | Unique plate number |
| `equipment` | string[] |  |  |
| `notWorkingReason` | string enum: `repair`, `fuel`, `no_crew`, `security`, `other` |  | Required when status is not_working; must be null otherwise |

### AmbulanceEdit

Change one or more ambulance fields.

| Field | Type | Required | Description |
|---|---|---|---|
| `type` | string enum: `basic`, `advanced` |  |  |
| `status` | string enum: `available`, `busy`, `not_working` |  |  |
| `recordStatus` | string enum: `active`, `inactive` |  |  |
| `hospitalId` | string(uuid) |  |  |
| `plateNumber` | string |  |  |
| `equipment` | string[] |  |  |
| `notWorkingReason` | string enum: `repair`, `fuel`, `no_crew`, `security`, `other` |  | Required when status is not_working; must be null otherwise |

### AmbulanceOption

An available ambulance ranked by estimated time to the case pin

| Field | Type | Required | Description |
|---|---|---|---|
| `ambulanceId` | string(uuid) |  |  |
| `plateNumber` | string |  |  |
| `type` | string enum: `basic`, `advanced` |  |  |
| `hospitalId` | string(uuid) |  |  |
| `hospitalNameAr` | string |  |  |
| `hospitalNameEn` | string |  |  |
| `crewOnShift` | integer(int32) |  |  |
| `etaSeconds` | integer(int32) |  |  |
| `distanceM` | integer(int32) |  |  |
| `etaMethod` | string enum: `road`, `estimate` |  |  |
| `positionSource` | string enum: `tracker`, `phone`, `hospital` |  | Where the start point came from; hospital = no fresh GPS |
| `positionAgeSeconds` | integer(int32) |  |  |

### AmbulancesReport

| Field | Type | Required | Description |
|---|---|---|---|
| `report` | string |  |  |
| `timezone` | string |  |  |
| `from` | string(date) |  |  |
| `to` | string(date) |  |  |
| `labels` | map<string, [Label](#label)> |  |  |
| `sections` | [AmbulancesSections](#ambulancessections) |  |  |

### AmbulancesSections

| Field | Type | Required | Description |
|---|---|---|---|
| `jobs` | [JobRow](#jobrow)[] |  |  |
| `trackers` | [TrackerRow](#trackerrow)[] |  |  |

### AmbulanceStatusCount

| Field | Type | Required | Description |
|---|---|---|---|
| `hospitalId` | string(uuid) |  |  |
| `status` | string enum: `available`, `busy`, `not_working` |  |  |
| `count` | integer(int64) |  |  |

### AmbulanceView

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `hospitalId` | string(uuid) |  |  |
| `plateNumber` | string |  |  |
| `type` | string |  |  |
| `equipment` | string[] |  |  |
| `status` | string |  |  |
| `notWorkingReason` | string |  |  |
| `recordStatus` | string |  |  |
| `wialonUnitId` | integer(int64) |  |  |
| `createdAt` | string(date-time) |  |  |
| `updatedAt` | string(date-time) |  |  |

### Answer

| Field | Type | Required | Description |
|---|---|---|---|
| `questionCode` | string | yes |  |
| `answerValue` | string | yes |  |

### ApiError

Bilingual error body returned with every 4xx/5xx response.

| Field | Type | Required | Description |
|---|---|---|---|
| `code` | string enum: `ACCOUNT_DISABLED`, `ACCOUNT_LOCKED`, `AGENT_INVALID`, `ALERT_ALREADY_ACKNOWLEDGED`, `AMBULANCE_AVAILABLE`, `AMBULANCE_NO_CREW`, `AMBULANCE_REASON_INVALID`, `AMBULANCE_REASON_REQUIRED`, `AMBULANCE_UNAVAILABLE`, `ANSWER_TOO_LATE`, `APPROVAL_NOT_PENDING`, `APP_REQUEST_TAKE_REQUIRED`, `APP_UPDATE_REQUIRED`, `AREA_OVERLAP`, `AUTH_RATE_LIMIT`, `CALL_HAS_CASE`, `CALL_NOT_FINISHED`, `CALL_STATE_MISMATCH`, `CALL_UNAVAILABLE`, `CAPABILITY_INVALID`, `CASE_CLOSED`, `CASE_HAS_NO_CALL`, `CASE_NOT_IN_INCIDENT`, `CASE_NOT_READY`, `CHARGE_NOT_PAYABLE`, `CHARGE_NOT_WAIVABLE`, `CHECK_INVALID`, `CITIZEN_HISTORY_NOT_VERIFIED`, `CITIZEN_ID_ACCOUNT_EXISTS`, `CITIZEN_OPEN_REQUESTS`, `CITIZEN_PHONE_ACCOUNT_EXISTS`, `CITIZEN_SUSPENDED`, `CLINICAL_CONTEXT_INVALID`, `CODE_EXPIRED`, `CONFLICT`, `CROSS_STATE_REASON_REQUIRED`, `DATABASE_RULE`, `DATABASE_UNAVAILABLE`, `DEVICE_BLOCKED`, `DEVICE_INVALID`, `DEVICE_REQUIRED`, `DISPATCH_NOT_ACTIVE`, `ER_BEDS_INVALID`, `FILE_STORAGE_UNAVAILABLE`, `FILE_TOO_LARGE`, `FILE_TYPE_INVALID`, `FIRST_RECORD_INCOMPLETE`, `FORBIDDEN`, `HOSPITAL_OVERRIDE_REQUIRED`, `IDEMPOTENCY_CONFLICT`, `IDEMPOTENCY_KEY_INVALID`, `IMPORT_EXISTS`, `IMPORT_ROW_INVALID`, `IMPORT_UNREADABLE`, `INCIDENT_CLOSED`, `INCIDENT_OTHER_STATE`, `INTERNAL_ERROR`, `INVALID_CHALLENGE`, `INVALID_CODE`, `INVALID_CREDENTIALS`, `INVALID_GEOMETRY`, `JOB_STEP_INVALID`, `LOCATION_STATE_MISMATCH`, `MEDICINE_INVALID`, `NATIONAL_ID_CONFLICT`, `NOT_FOUND`, `OUTSIDE_SCOPE`, `PASSWORD_CHANGE_REQUIRED`, `PASSWORD_POLICY`, `PATIENT_ACCESS_DENIED`, `PAYMENT_TOO_HIGH`, `PHONE_INVALID`, `PHONE_IN_USE`, `PIN_INVALID`, `PIN_LOCKED`, `PRIORITY_REASON_REQUIRED`, `PROD_TOOL_REFUSED`, `QR_FAILED`, `RECEIPT_UNAVAILABLE`, `REFUSE_REASON_INVALID`, `REPORT_FILTER_INVALID`, `REPORT_UNAVAILABLE`, `REQUEST_ALREADY_ANSWERED`, `RESEND_LIMIT`, `RESEND_WAIT`, `RESET_ASK_ADMIN`, `RESET_REQUESTED`, `SAME_STATE_HOSPITAL`, `SCOPE_HOSPITAL_ONLY`, `SCOPE_NATIONAL_ONLY`, `SCOPE_NOT_ALLOWED`, `SCOPE_ONE_HOSPITAL`, `SCOPE_STATE_ONLY`, `SCOPE_SUPERVISOR_ONLY`, `SCOPE_TARGET_INVALID`, `SCOPE_TYPE_INVALID`, `SESSION_IDLE`, `SESSION_INVALID`, `SETTING_BOOLEAN`, `SETTING_INTEGER`, `SETTING_PHONE_DIGITS`, `SETTING_PRIORITY`, `SETTING_RANGE`, `SHIFT_ALREADY_ACTIVE`, `SHIFT_FULL`, `SHIFT_HAS_JOB`, `SIGNUP_RATE_LIMIT`, `SMS_NOT_CONFIGURED`, `SMS_NOT_FOUND`, `SMS_RATE_LIMIT`, `SMS_UNAVAILABLE`, `STATE_REQUIRED`, `STATUS_TIME_INVALID`, `SUBSCRIPTION_LIMIT`, `SYSTEM_LIST_ADD`, `SYSTEM_LIST_LABELS_ONLY`, `TARIFF_SCOPE_INVALID`, `TRIAGE_MODEL_INVALID`, `UNAUTHORIZED`, `USERNAME_INVALID`, `USERNAME_TAKEN`, `VALIDATION_ERROR`, `WARD_BEDS_INVALID`, `WIALON_LINKED`, `WRONG_CLIENT_APP` | yes | Error code; the full list is the bilingual message catalogue. Show message_ar/message_en, branch on code. |
| `message_ar` | string | yes | Arabic message for the user |
| `message_en` | string | yes | English message for the user |
| `reference` | string |  | Support reference for this failure |
| `time` | string(date-time) | yes |  |
| `fieldErrors` | [FieldError](#fielderror)[] |  | Present when specific input fields failed; show each message under its field |

### ApiPageAccessLogView

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [AccessLogView](#accesslogview)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageAmbulanceView

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [AmbulanceView](#ambulanceview)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageAppRequest

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [AppRequest](#apprequest)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageAreaMatch

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [AreaMatch](#areamatch)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageAreaView

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [AreaView](#areaview)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageCallRecord

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [CallRecord](#callrecord)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageDeviceView

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [DeviceView](#deviceview)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageDuplicateCase

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [DuplicateCase](#duplicatecase)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageHospitalStatusHistoryView

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [HospitalStatusHistoryView](#hospitalstatushistoryview)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageHospitalSummary

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [HospitalSummary](#hospitalsummary)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageHospitalView

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [HospitalView](#hospitalview)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageLandmarkView

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [LandmarkView](#landmarkview)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageListItemView

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [ListItemView](#listitemview)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageListTypeView

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [ListTypeView](#listtypeview)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageLocalityView

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [LocalityView](#localityview)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageNearbyArea

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [NearbyArea](#nearbyarea)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageOpenCase

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [OpenCase](#opencase)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageOverviewItem

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [OverviewItem](#overviewitem)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPagePlaceMatch

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [PlaceMatch](#placematch)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPagePlaceView

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [PlaceView](#placeview)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageSettingHistoryView

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [SettingHistoryView](#settinghistoryview)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageSettingView

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [SettingView](#settingview)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageStateView

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [StateView](#stateview)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageTariffView

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [TariffView](#tariffview)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageTrackerView

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [TrackerView](#trackerview)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageTriageHistoryView

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [TriageHistoryView](#triagehistoryview)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageTriageQuestion

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [TriageQuestion](#triagequestion)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageTriageQuestionView

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [TriageQuestionView](#triagequestionview)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageUserView

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [UserView](#userview)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### ApiPageWaiverView

One page of results. Request the next page while hasNext is true.

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | [WaiverView](#waiverview)[] | yes |  |
| `page` | integer(int32) |  | Zero-based page number |
| `size` | integer(int32) |  | Requested page size |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  | All matching rows; only when includeTotal=true was requested (one extra count query) |

### AppRequest

Citizen SOS waiting for an agent. stateCode is null when the pin is outside every mapped state; such requests are visible to all agents.

| Field | Type | Required | Description |
|---|---|---|---|
| `callId` | string(uuid) |  |  |
| `stateCode` | string |  |  |
| `callerPhone` | string |  |  |
| `startedAt` | string(date-time) |  |  |
| `waitingSeconds` | integer(int32) |  |  |
| `lon` | number(double) |  | Null for an SMS SOS (no GPS): the agent pins the place on the map from what the caller says |
| `lat` | number(double) |  |  |
| `accuracyM` | number(double) |  |  |
| `note` | string |  |  |
| `takenBy` | string(uuid) |  | Agent who took this SOS; null while waiting. Agents see only waiting SOS and their own; supervisors see all |
| `channel` | string enum: `app`, `sms` |  | app = citizen app with GPS, sms = SMS short code (text only) |

### AppRequestClosed

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `result` | string |  |  |

### AreaCreate

New area. The boundary must be valid and must not overlap another active area of the same level.

| Field | Type | Required | Description |
|---|---|---|---|
| `level` | string enum: `area`, `block` |  | block requires parentAreaId |
| `status` | string enum: `active`, `inactive` |  |  |
| `boundary` | [GeoShape](#geoshape) | yes |  |
| `nameAr` | string | yes | Non-blank text, at most 2000 characters |
| `nameEn` | string | yes | Non-blank text, at most 2000 characters |
| `localityId` | string(uuid) | yes |  |
| `parentAreaId` | string(uuid) |  |  |
| `otherNames` | string[] |  |  |

### AreaEdit

Change one or more area fields; same rules as creation.

| Field | Type | Required | Description |
|---|---|---|---|
| `level` | string enum: `area`, `block` |  |  |
| `status` | string enum: `active`, `inactive` |  |  |
| `boundary` | [GeoShape](#geoshape) |  |  |
| `nameAr` | string |  | Non-blank text, at most 2000 characters |
| `nameEn` | string |  | Non-blank text, at most 2000 characters |
| `localityId` | string(uuid) |  |  |
| `parentAreaId` | string(uuid) |  | null removes the parent |
| `otherNames` | string[] |  |  |

### AreaMatch

| Field | Type | Required | Description |
|---|---|---|---|
| `areaId` | string(uuid) |  |  |
| `areaNameAr` | string |  |  |
| `areaNameEn` | string |  |  |
| `areaLevel` | string enum: `area`, `block` |  |  |
| `localityId` | string(uuid) |  |  |
| `localityNameAr` | string |  |  |
| `localityNameEn` | string |  |  |
| `stateId` | string(uuid) |  |  |
| `stateCode` | string |  |  |
| `stateNameAr` | string |  |  |
| `stateNameEn` | string |  |  |

### AreaRow

| Field | Type | Required | Description |
|---|---|---|---|
| `areaId` | string(uuid) |  |  |
| `count` | integer(int64) |  |  |
| `boundary` | [GeoShape](#geoshape) |  |  |

### AreaView

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `localityId` | string(uuid) |  |  |
| `parentAreaId` | string(uuid) |  |  |
| `level` | string |  |  |
| `nameAr` | string |  |  |
| `nameEn` | string |  |  |
| `otherNames` | string[] |  |  |
| `boundary` | [GeoShape](#geoshape) |  |  |
| `source` | string enum: `osm`, `client`, `admin`, `import` |  |  |
| `status` | string |  |  |
| `createdAt` | string(date-time) |  |  |
| `updatedAt` | string(date-time) |  |  |

### Arrival

An ambulance coming to this hospital, with ETA and open alerts

| Field | Type | Required | Description |
|---|---|---|---|
| `dispatchId` | string(uuid) |  |  |
| `caseId` | string(uuid) |  |  |
| `caseNumber` | string |  |  |
| `priority` | string |  |  |
| `status` | string |  |  |
| `plateNumber` | string |  |  |
| `lastPosition` | [Position](#position) |  |  |
| `etaSeconds` | integer(int32) |  |  |
| `etaMethod` | string |  |  |
| `alerts` | [DispatchAlert](#dispatchalert)[] |  |  |

### AverageResponse

| Field | Type | Required | Description |
|---|---|---|---|
| `averageResponseMinutes` | number |  |  |

### Block

| Field | Type | Required | Description |
|---|---|---|---|
| `reason` | string | yes |  |

### Blocked

| Field | Type | Required | Description |
|---|---|---|---|
| `blocked` | boolean |  | Device blocked and its sessions revoked |

### BloodType

| Field | Type | Required | Description |
|---|---|---|---|
| `bloodType` | string | yes |  |

### Call

| Field | Type | Required | Description |
|---|---|---|---|
| `callerPhone` | string |  |  |

### CallCentreReport

| Field | Type | Required | Description |
|---|---|---|---|
| `report` | string |  |  |
| `timezone` | string |  |  |
| `from` | string(date) |  |  |
| `to` | string(date) |  |  |
| `labels` | map<string, [Label](#label)> |  |  |
| `sections` | [CallCentreSections](#callcentresections) |  |  |

### CallCentreSections

| Field | Type | Required | Description |
|---|---|---|---|
| `calls` | [CallRow](#callrow)[] |  |  |

### CallRecord

A 999 phone call or a citizen-app SOS, as a system administrator reads it (read-only, report scope). stateId is the call's own state, else its case's; null only for national admins

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `channel` | string enum: `phone`, `app` |  | phone = 999 call, app = citizen-app SOS |
| `callerPhone` | string |  |  |
| `startedAt` | string(date-time) |  |  |
| `answeredAt` | string(date-time) |  |  |
| `endedAt` | string(date-time) |  |  |
| `result` | string enum: `in_progress`, `case_created`, `duplicate`, `not_emergency`, `dropped`, `prank`, `information_only`, `passed_to_other_agency` |  |  |
| `notes` | string |  |  |
| `stateId` | string(uuid) |  |  |
| `stateCode` | string |  |  |
| `agentId` | string(uuid) |  |  |
| `agentNameAr` | string |  |  |
| `agentNameEn` | string |  |  |
| `caseId` | string(uuid) |  | Set when the call became a case |
| `caseNumber` | string |  |  |

### CallRow

| Field | Type | Required | Description |
|---|---|---|---|
| `period` | string |  | Start of the hour or day, Khartoum time |
| `agentId` | string(uuid) |  |  |
| `channel` | string |  |  |
| `result` | string |  |  |
| `count` | integer(int64) |  |  |
| `averageAnswerMinutes` | number |  |  |

### CallTaken

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `stateId` | string(uuid) |  |  |
| `agentId` | string(uuid) |  |  |

### CallUpdate

| Field | Type | Required | Description |
|---|---|---|---|
| `result` | string | yes |  |
| `notes` | string |  |  |

### CallView

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `stateId` | string(uuid) |  |  |
| `result` | string enum: `in_progress`, `case_created`, `prank`, `not_emergency`, `duplicate`, `dropped`, `information_only`, `passed_to_other_agency` |  |  |

### Cancel

| Field | Type | Required | Description |
|---|---|---|---|
| `reason` | string | yes |  |

### Capabilities

| Field | Type | Required | Description |
|---|---|---|---|
| `capabilities` | string[] | yes |  |

### Capability

| Field | Type | Required | Description |
|---|---|---|---|
| `code` | string |  |  |
| `nameAr` | string |  |  |
| `nameEn` | string |  |  |

### Case

| Field | Type | Required | Description |
|---|---|---|---|
| `callId` | string(uuid) |  |  |
| `stateId` | string(uuid) |  |  |
| `emergencyTypeCode` | string |  |  |
| `complaint` | string |  |  |
| `lon` | number(double) |  |  |
| `lat` | number(double) |  |  |
| `pinRadiusM` | integer(int32) |  |  |
| `landmarkId` | string(uuid) |  |  |
| `directions` | string |  |  |
| `patientsCount` | integer(int32) |  |  |
| `triageModel` | string |  |  |

### CaseCreated

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `caseNumber` | string |  |  |
| `stateId` | string(uuid) |  |  |
| `priority` | string |  |  |
| `step` | string |  |  |
| `longitude` | number(double) |  |  |
| `latitude` | number(double) |  |  |

### CaseDetail

Case with its step, priority and hospital-request history

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `caseNumber` | string |  |  |
| `stateId` | string(uuid) |  |  |
| `hospitalId` | string(uuid) |  |  |
| `emergencyTypeCode` | string |  |  |
| `complaint` | string |  |  |
| `priority` | string |  |  |
| `step` | string |  |  |
| `longitude` | number(double) |  |  |
| `latitude` | number(double) |  |  |
| `pinRadiusM` | integer(int32) |  |  |
| `directions` | string |  |  |
| `patientsCount` | integer(int32) |  |  |
| `createdAt` | string(date-time) |  |  |
| `updatedAt` | string(date-time) |  |  |
| `callId` | string(uuid) |  | The call this case came from |
| `callerPhone` | string |  |  |
| `stepsHistory` | [StepEvent](#stepevent)[] |  |  |
| `priorityHistory` | [PriorityChange](#prioritychange)[] |  |  |
| `hospitalRequests` | [CaseHospitalRequest](#casehospitalrequest)[] |  |  |
| `incidentId` | string(uuid) |  |  |
| `mciTag` | string enum: `red`, `yellow`, `green`, `black` |  |  |
| `outcome` | [Outcome](#outcome) |  | Patient outcome recorded by the receiving hospital |

### CaseDispatch

An ambulance job on the case, for the call centre's tracking view

| Field | Type | Required | Description |
|---|---|---|---|
| `dispatchId` | string(uuid) |  |  |
| `ambulanceId` | string(uuid) |  |  |
| `plateNumber` | string |  |  |
| `hospitalId` | string(uuid) |  |  |
| `status` | string enum: `sent`, `confirmed`, `en_route`, `on_scene`, `leaving_scene`, `at_hospital`, `completed`, `cancelled` |  |  |
| `sentAt` | string(date-time) |  |  |
| `confirmDeadlineAt` | string(date-time) |  |  |
| `confirmedAt` | string(date-time) |  |  |
| `confirmedVia` | string |  |  |
| `completedAt` | string(date-time) |  |  |
| `cancelReason` | string |  |  |
| `confirmationLate` | boolean |  | Sent and not confirmed after the confirm deadline: call the crew by phone |
| `events` | [JobEvent](#jobevent)[] |  |  |
| `crew` | [CrewMember](#crewmember)[] |  |  |
| `lastPosition` | [Position](#position) |  |  |
| `phoneCalls` | [PhoneCall](#phonecall)[] |  |  |
| `etaSeconds` | integer(int32) |  | Seconds to the case pin (before on scene) or to the hospital (after) |
| `etaMethod` | string enum: `road`, `estimate` |  |  |

### CaseHospitalRequest

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `hospitalId` | string(uuid) |  |  |
| `hospitalNameAr` | string |  |  |
| `hospitalNameEn` | string |  |  |
| `status` | string |  |  |
| `sentAt` | string(date-time) |  |  |
| `deadlineAt` | string(date-time) |  |  |
| `distanceM` | number(double) |  |  |
| `answeredAt` | string(date-time) |  |  |
| `refuseReasonCode` | string |  | Code from list hospital_refuse_reasons when status is refused |
| `refuseReasonAr` | string |  |  |
| `refuseReasonEn` | string |  |  |
| `refuseNote` | string |  | Free text the hospital added to the reason |

### CasesReport

| Field | Type | Required | Description |
|---|---|---|---|
| `report` | string |  |  |
| `timezone` | string |  |  |
| `from` | string(date) |  |  |
| `to` | string(date) |  |  |
| `labels` | map<string, [Label](#label)> |  |  |
| `sections` | [CasesSections](#casessections) |  |  |

### CasesSections

| Field | Type | Required | Description |
|---|---|---|---|
| `types` | [TypeRow](#typerow)[] |  |  |
| `areas` | [AreaRow](#arearow)[] |  |  |
| `closing` | [ClosingRow](#closingrow)[] |  |  |

### CaseState

Case state after a change

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `stateId` | string(uuid) |  |  |
| `priority` | string |  |  |
| `prioritySource` | string enum: `auto`, `manual`, `danger_score` |  |  |
| `step` | string |  |  |
| `hospitalId` | string(uuid) |  |  |

### Challenge

| Field | Type | Required | Description |
|---|---|---|---|
| `challengeId` | string(uuid) |  |  |
| `expiresAt` | string(date-time) |  |  |

### Change

| Field | Type | Required | Description |
|---|---|---|---|
| `oldPassword` | string | yes |  |
| `newPassword` | string | yes |  |

### ChargeRow

| Field | Type | Required | Description |
|---|---|---|---|
| `hospitalId` | string(uuid) |  |  |
| `currency` | string |  |  |
| `status` | string |  |  |
| `count` | integer(int64) |  |  |
| `charged` | number |  |  |
| `paid` | number |  |  |

### ChargesReport

| Field | Type | Required | Description |
|---|---|---|---|
| `report` | string |  |  |
| `timezone` | string |  |  |
| `from` | string(date) |  |  |
| `to` | string(date) |  |  |
| `labels` | map<string, [Label](#label)> |  |  |
| `sections` | [ChargesSections](#chargessections) |  |  |

### ChargesSections

| Field | Type | Required | Description |
|---|---|---|---|
| `charges` | [ChargeRow](#chargerow)[] |  |  |
| `payments` | [PaymentRow](#paymentrow)[] |  |  |

### CheckResult

| Field | Type | Required | Description |
|---|---|---|---|
| `checkCode` | string | yes |  |
| `resultValue` | string | yes |  |
| `resultUnit` | string |  |  |

### Close

| Field | Type | Required | Description |
|---|---|---|---|
| `closingReason` | string | yes |  |

### ClosingRow

| Field | Type | Required | Description |
|---|---|---|---|
| `closingReason` | string |  |  |
| `count` | integer(int64) |  |  |

### Condition

| Field | Type | Required | Description |
|---|---|---|---|
| `kind` | string | yes |  |
| `name` | string | yes |  |
| `note` | string |  |  |

### CrewMember

| Field | Type | Required | Description |
|---|---|---|---|
| `userId` | string(uuid) |  |  |
| `role` | string enum: `driver`, `paramedic` |  |  |
| `nameAr` | string |  |  |
| `nameEn` | string |  |  |
| `phone` | string |  |  |

### CrossStateApproval

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `caseId` | string(uuid) |  |  |
| `caseNumber` | string |  |  |
| `hospitalId` | string(uuid) |  |  |
| `hospitalNameAr` | string |  |  |
| `hospitalNameEn` | string |  |  |
| `reason` | string |  |  |
| `requestedBy` | string(uuid) |  |  |
| `requestedAt` | string(date-time) |  |  |
| `status` | string enum: `pending`, `approved`, `rejected` |  |  |
| `decidedBy` | string(uuid) |  |  |
| `decidedAt` | string(date-time) |  |  |
| `decisionNote` | string |  |  |
| `requestId` | string(uuid) |  | The hospital request created on approval |

### CrossStateAsk

| Field | Type | Required | Description |
|---|---|---|---|
| `hospitalId` | string(uuid) | yes |  |
| `reason` | string | yes |  |

### CrossStateHospital

| Field | Type | Required | Description |
|---|---|---|---|
| `hospitalId` | string(uuid) |  |  |
| `code` | string |  |  |
| `nameAr` | string |  |  |
| `nameEn` | string |  |  |
| `stateCode` | string |  |  |
| `erStatus` | string |  |  |
| `availableAmbulances` | integer(int32) |  | Ambulances available now |
| `distanceM` | number(double) |  |  |
| `capabilities` | string[] |  |  |

### DashboardChargeRow

| Field | Type | Required | Description |
|---|---|---|---|
| `hospitalId` | string(uuid) |  |  |
| `currency` | string |  |  |
| `charged` | number |  |  |
| `paid` | number |  |  |
| `waived` | integer(int64) |  |  |
| `noTariff` | integer(int64) |  |  |

### DashboardReport

| Field | Type | Required | Description |
|---|---|---|---|
| `report` | string |  |  |
| `timezone` | string |  |  |
| `from` | string(date) |  |  |
| `to` | string(date) |  |  |
| `labels` | map<string, [Label](#label)> |  |  |
| `sections` | [DashboardSections](#dashboardsections) |  |  |
| `refreshSeconds` | integer(int32) |  | Suggested refresh interval |

### DashboardSections

| Field | Type | Required | Description |
|---|---|---|---|
| `ambulancesByStatus` | [AmbulanceStatusCount](#ambulancestatuscount)[] |  | Active ambulances by current status per hospital |
| `targets` | [TargetRow](#targetrow)[] |  |  |
| `openCases` | [PriorityCount](#prioritycount)[] |  |  |
| `response` | [AverageResponse](#averageresponse)[] |  |  |
| `waitingRequests` | [HospitalCount](#hospitalcount)[] |  |  |
| `availableAmbulances` | [HospitalCount](#hospitalcount)[] |  |  |
| `trackers` | [TrackerRow](#trackerrow)[] |  |  |
| `charges` | [DashboardChargeRow](#dashboardchargerow)[] |  |  |

### Decision

| Field | Type | Required | Description |
|---|---|---|---|
| `note` | string |  |  |

### Dependant

| Field | Type | Required | Description |
|---|---|---|---|
| `childNationalId` | string | yes |  |
| `relation` | string | yes |  |

### DeviceView

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `userId` | string(uuid) |  |  |
| `username` | string |  |  |
| `fullNameAr` | string |  |  |
| `fullNameEn` | string |  |  |
| `roleCode` | string |  |  |
| `clientApp` | string enum: `staff_web`, `crew_app`, `citizen_app` |  |  |
| `appVersion` | string |  |  |
| `blockedAt` | string(date-time) |  |  |
| `blockReason` | string |  |  |
| `createdAt` | string(date-time) |  |  |
| `lastSeenAt` | string(date-time) |  |  |
| `pushRegistered` | boolean |  |  |
| `activeSessions` | integer(int64) |  | Unrevoked, unexpired sessions on this device |

### Diagnosis

| Field | Type | Required | Description |
|---|---|---|---|
| `icd10Code` | string | yes |  |
| `description` | string | yes |  |
| `kind` | string | yes |  |

### DispatchAlert

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `dispatchId` | string(uuid) |  |  |
| `type` | string |  |  |
| `note` | string |  |  |
| `raisedAt` | string(date-time) |  |  |
| `acknowledgedAt` | string(date-time) |  |  |
| `acknowledgedBy` | string(uuid) |  |  |

### DuplicateCase

| Field | Type | Required | Description |
|---|---|---|---|
| `caseId` | string(uuid) |  |  |
| `caseNumber` | string |  |  |
| `priority` | string |  |  |
| `step` | string |  |  |
| `samePhone` | boolean |  |  |
| `distanceM` | number(double) |  |  |

### EndVisit

| Field | Type | Required | Description |
|---|---|---|---|
| `endType` | string | yes |  |
| `transferHospitalId` | string(uuid) |  |  |
| `note` | string |  |  |

### FieldError

One rejected input field

| Field | Type | Required | Description |
|---|---|---|---|
| `field` | string | yes | Request field, query parameter or form property name, e.g. phone or answers |
| `code` | string enum: `REQUIRED`, `INVALID`, `NOT_ALLOWED` | yes |  |
| `message_ar` | string | yes |  |
| `message_en` | string | yes |  |

### Finish

| Field | Type | Required | Description |
|---|---|---|---|
| `challengeId` | string(uuid) | yes |  |
| `code` | string | yes |  |
| `nationalId` | string | yes |  |
| `fullNameAr` | string | yes |  |
| `fullNameEn` | string |  |  |
| `password` | string | yes |  |

### FirstCheck

| Field | Type | Required | Description |
|---|---|---|---|
| `heightCm` | number | yes |  |
| `weightKg` | number | yes |  |
| `allergiesReviewed` | boolean |  |  |
| `chronicReviewed` | boolean |  |  |
| `medicinesReviewed` | boolean |  |  |

### Forgot

| Field | Type | Required | Description |
|---|---|---|---|
| `username` | string | yes |  |
| `clientApp` | string |  | staff_web: no self-service reset; the reply tells the user to ask an administrator |

### GeoPoint

GeoJSON Point in WGS84: coordinates are [longitude, latitude]

| Field | Type | Required | Description |
|---|---|---|---|
| `type` | string enum: `Point` | yes |  |
| `coordinates` | number(double)[] | yes |  |

### GeoShape

GeoJSON Polygon or MultiPolygon in WGS84; stored as MultiPolygon

| Field | Type | Required | Description |
|---|---|---|---|
| `type` | string enum: `Polygon`, `MultiPolygon` | yes |  |
| `coordinates` | any[][] | yes | Nested GeoJSON coordinate arrays (rings of [longitude, latitude] positions) |

### Handover

| Field | Type | Required | Description |
|---|---|---|---|
| `caseId` | string(uuid) | yes |  |
| `dispatchId` | string(uuid) | yes |  |
| `patientId` | string(uuid) | yes |  |
| `summary` | string | yes |  |

### HospitalCount

| Field | Type | Required | Description |
|---|---|---|---|
| `hospitalId` | string(uuid) |  |  |
| `count` | integer(int64) |  |  |

### HospitalCreate

New hospital record.

| Field | Type | Required | Description |
|---|---|---|---|
| `location` | [GeoPoint](#geopoint) | yes |  |
| `type` | string enum: `government`, `private`, `military`, `ngo`, `other` | yes |  |
| `code` | string | yes | Unique hospital code, e.g. KH-101 |
| `phone` | string |  |  |
| `nameAr` | string | yes | Non-blank text, at most 2000 characters |
| `nameEn` | string | yes | Non-blank text, at most 2000 characters |
| `localityId` | string(uuid) | yes |  |
| `recordStatus` | string enum: `active`, `inactive` |  |  |

### HospitalEdit

Change one or more hospital record fields. ER status and beds use PATCH /api/v1/hospitals/{id}/status.

| Field | Type | Required | Description |
|---|---|---|---|
| `location` | [GeoPoint](#geopoint) |  |  |
| `type` | string enum: `government`, `private`, `military`, `ngo`, `other` |  |  |
| `code` | string |  |  |
| `phone` | string |  | null removes the phone |
| `nameAr` | string |  | Non-blank text, at most 2000 characters |
| `nameEn` | string |  | Non-blank text, at most 2000 characters |
| `localityId` | string(uuid) |  |  |
| `recordStatus` | string enum: `active`, `inactive` |  |  |

### HospitalLoad

| Field | Type | Required | Description |
|---|---|---|---|
| `hospitalId` | string(uuid) |  |  |
| `nameAr` | string |  |  |
| `nameEn` | string |  |  |
| `red` | integer(int32) |  |  |
| `yellow` | integer(int32) |  |  |
| `green` | integer(int32) |  |  |
| `black` | integer(int32) |  |  |
| `untagged` | integer(int32) |  |  |

### HospitalRequestCancelled

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `caseId` | string(uuid) |  |  |
| `status` | string |  |  |

### HospitalRequestSent

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `caseId` | string(uuid) |  |  |
| `hospitalId` | string(uuid) |  |  |
| `status` | string enum: `waiting`, `accepted`, `refused`, `timed_out`, `cancelled` |  |  |
| `deadlineAt` | string(date-time) |  | Hospital must answer before this time |
| `distanceM` | number(double) |  |  |

### HospitalRequestsReport

| Field | Type | Required | Description |
|---|---|---|---|
| `report` | string |  |  |
| `timezone` | string |  |  |
| `from` | string(date) |  |  |
| `to` | string(date) |  |  |
| `labels` | map<string, [Label](#label)> |  |  |
| `sections` | [HospitalRequestsSections](#hospitalrequestssections) |  |  |

### HospitalRequestsSections

| Field | Type | Required | Description |
|---|---|---|---|
| `requests` | [RequestRow](#requestrow)[] |  |  |
| `rates` | [RateRow](#raterow)[] |  |  |

### HospitalStatusChange

ER status and bed counts. Free beds cannot exceed total beds.

| Field | Type | Required | Description |
|---|---|---|---|
| `erStatus` | string enum: `working`, `partly_working`, `not_working` |  |  |
| `erBedsTotal` | integer(int32) |  |  |
| `erBedsFree` | integer(int32) |  |  |
| `wardBedsTotal` | integer(int32) |  |  |
| `wardBedsFree` | integer(int32) |  |  |

### HospitalStatusHistoryView

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | integer(int64) |  |  |
| `hospitalId` | string(uuid) |  |  |
| `erStatus` | string |  |  |
| `erBedsTotal` | integer(int32) |  |  |
| `erBedsFree` | integer(int32) |  |  |
| `wardBedsTotal` | integer(int32) |  |  |
| `wardBedsFree` | integer(int32) |  |  |
| `changedAt` | string(date-time) |  |  |
| `changedBy` | string(uuid) |  |  |

### HospitalSummary

Hospital the caller may see: admins all active hospitals, call centre its states, hospital roles their own

| Field | Type | Required | Description |
|---|---|---|---|
| `hospitalId` | string(uuid) |  |  |
| `code` | string |  |  |
| `nameAr` | string |  |  |
| `nameEn` | string |  |  |
| `stateCode` | string |  |  |
| `erStatus` | string enum: `working`, `partly_working`, `not_working` |  |  |
| `erBedsFree` | integer(int32) |  |  |
| `statusUpdatedAt` | string(date-time) |  |  |

### HospitalView

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `code` | string |  |  |
| `nameAr` | string |  |  |
| `nameEn` | string |  |  |
| `type` | string |  |  |
| `localityId` | string(uuid) |  |  |
| `stateId` | string(uuid) |  |  |
| `location` | [GeoPoint](#geopoint) |  |  |
| `phone` | string |  |  |
| `erStatus` | string |  |  |
| `erBedsTotal` | integer(int32) |  |  |
| `erBedsFree` | integer(int32) |  |  |
| `wardBedsTotal` | integer(int32) |  |  |
| `wardBedsFree` | integer(int32) |  |  |
| `statusUpdatedAt` | string(date-time) |  |  |
| `statusUpdatedBy` | string(uuid) |  |  |
| `recordStatus` | string |  |  |
| `createdAt` | string(date-time) |  |  |
| `updatedAt` | string(date-time) |  |  |

### IdCard

| Field | Type | Required | Description |
|---|---|---|---|
| `nationalId` | string | yes |  |

### Identifier

| Field | Type | Required | Description |
|---|---|---|---|
| `type` | string | yes |  |
| `value` | string | yes |  |

### InboundAccepted

| Field | Type | Required | Description |
|---|---|---|---|
| `callId` | string(uuid) |  |  |
| `result` | string enum: `created`, `duplicate` |  |  |

### InboundSms

| Field | Type | Required | Description |
|---|---|---|---|
| `from` | string | yes |  |
| `text` | string | yes |  |

### IncidentBoard

Mass-casualty board: every case, colour counts and how patients are spread across hospitals

| Field | Type | Required | Description |
|---|---|---|---|
| `incident` | [IncidentSummary](#incidentsummary) |  |  |
| `cases` | [IncidentCase](#incidentcase)[] |  |  |
| `hospitals` | [HospitalLoad](#hospitalload)[] |  |  |

### IncidentCase

| Field | Type | Required | Description |
|---|---|---|---|
| `caseId` | string(uuid) |  |  |
| `caseNumber` | string |  |  |
| `priority` | string |  |  |
| `step` | string |  |  |
| `mciTag` | string |  |  |
| `hospitalId` | string(uuid) |  |  |
| `hospitalNameEn` | string |  |  |
| `hospitalNameAr` | string |  |  |

### IncidentSummary

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `title` | string |  |  |
| `stateCode` | string |  |  |
| `status` | string enum: `open`, `closed` |  |  |
| `lon` | number(double) |  |  |
| `lat` | number(double) |  |  |
| `createdAt` | string(date-time) |  |  |
| `closedAt` | string(date-time) |  |  |
| `cases` | integer(int32) |  |  |
| `red` | integer(int32) |  |  |
| `yellow` | integer(int32) |  |  |
| `green` | integer(int32) |  |  |
| `black` | integer(int32) |  |  |
| `untagged` | integer(int32) |  |  |

### InstructionCard

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `emergencyTypeCode` | string |  |  |
| `priority` | string |  |  |
| `titleAr` | string |  |  |
| `titleEn` | string |  |  |
| `stepsAr` | string[] |  |  |
| `stepsEn` | string[] |  |  |
| `sortOrder` | integer(int32) |  |  |
| `status` | string enum: `active`, `inactive` |  |  |
| `updatedAt` | string(date-time) |  |  |

### InstructionInput

| Field | Type | Required | Description |
|---|---|---|---|
| `emergencyTypeCode` | string |  |  |
| `priority` | string |  |  |
| `titleAr` | string | yes |  |
| `titleEn` | string | yes |  |
| `stepsAr` | string[] | yes |  |
| `stepsEn` | string[] | yes |  |
| `sortOrder` | integer(int32) |  |  |
| `status` | string |  |  |

### JobEvent

| Field | Type | Required | Description |
|---|---|---|---|
| `status` | string |  |  |
| `occurredAt` | string(date-time) |  |  |

### JobRow

| Field | Type | Required | Description |
|---|---|---|---|
| `ambulanceId` | string(uuid) |  |  |
| `hospitalId` | string(uuid) |  |  |
| `jobs` | integer(int64) |  |  |
| `busyHours` | number |  |  |
| `distanceKm` | number |  |  |
| `gpsDistanceKm` | number |  |  |
| `estimatedDistanceKm` | number |  |  |
| `unconfirmed` | integer(int64) |  |  |
| `phoneBackups` | number |  |  |

### Label

Arabic and English name of a code or hospital id used in the report

| Field | Type | Required | Description |
|---|---|---|---|
| `ar` | string |  |  |
| `en` | string |  |  |

### LandmarkCreate

New landmark; created approved.

| Field | Type | Required | Description |
|---|---|---|---|
| `location` | [GeoPoint](#geopoint) | yes |  |
| `type` | string enum: `mosque`, `church`, `market`, `school`, `university`, `hospital`, `clinic`, `police_station`, `petrol_station`, `bus_station`, `bridge`, `government_office`, `other` | yes |  |
| `nameAr` | string | yes | Non-blank text, at most 2000 characters |
| `nameEn` | string | yes | Non-blank text, at most 2000 characters |
| `otherNames` | string[] |  |  |

### LandmarkEdit

Change one or more landmark fields.

| Field | Type | Required | Description |
|---|---|---|---|
| `location` | [GeoPoint](#geopoint) |  |  |
| `type` | string enum: `mosque`, `church`, `market`, `school`, `university`, `hospital`, `clinic`, `police_station`, `petrol_station`, `bus_station`, `bridge`, `government_office`, `other` |  |  |
| `nameAr` | string |  | Non-blank text, at most 2000 characters |
| `nameEn` | string |  | Non-blank text, at most 2000 characters |
| `otherNames` | string[] |  |  |

### LandmarkView

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `areaId` | string(uuid) |  |  |
| `type` | string |  |  |
| `nameAr` | string |  |  |
| `nameEn` | string |  |  |
| `otherNames` | string[] |  |  |
| `location` | [GeoPoint](#geopoint) |  |  |
| `status` | string enum: `pending`, `approved`, `rejected` |  |  |
| `approvedBy` | string(uuid) |  |  |
| `approvedAt` | string(date-time) |  |  |
| `createdAt` | string(date-time) |  |  |
| `updatedAt` | string(date-time) |  |  |

### Link

| Field | Type | Required | Description |
|---|---|---|---|
| `patientId` | string(uuid) | yes |  |

### ListItemCreate

New item in a custom (non-system) list.

| Field | Type | Required | Description |
|---|---|---|---|
| `status` | string enum: `active`, `inactive` |  |  |
| `code` | string | yes |  |
| `sortOrder` | integer(int32) |  |  |
| `nameAr` | string | yes | Non-blank text, at most 2000 characters |
| `nameEn` | string | yes | Non-blank text, at most 2000 characters |

### ListItemEdit

Change list item fields. System lists allow only nameAr and nameEn.

| Field | Type | Required | Description |
|---|---|---|---|
| `status` | string enum: `active`, `inactive` |  |  |
| `code` | string |  |  |
| `sortOrder` | integer(int32) |  |  |
| `nameAr` | string |  | Non-blank text, at most 2000 characters |
| `nameEn` | string |  | Non-blank text, at most 2000 characters |

### ListItemView

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `listCode` | string |  |  |
| `code` | string |  |  |
| `nameAr` | string |  |  |
| `nameEn` | string |  |  |
| `sortOrder` | integer(int32) |  |  |
| `status` | string |  |  |
| `createdAt` | string(date-time) |  |  |
| `updatedAt` | string(date-time) |  |  |

### ListTypeView

| Field | Type | Required | Description |
|---|---|---|---|
| `code` | string |  |  |
| `nameAr` | string |  |  |
| `nameEn` | string |  |  |
| `isSystem` | boolean |  |  |

### LocalityView

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `stateId` | string(uuid) |  |  |
| `nameAr` | string |  |  |
| `nameEn` | string |  |  |
| `status` | string enum: `active`, `inactive` |  |  |
| `createdAt` | string(date-time) |  |  |

### Login

| Field | Type | Required | Description |
|---|---|---|---|
| `username` | string | yes |  |
| `password` | string | yes |  |
| `deviceType` | string | yes |  |
| `clientApp` | string |  |  |
| `deviceId` | string(uuid) |  |  |
| `appVersion` | string |  |  |

### LoginResult

step sms_code: send the code to /auth/verify (challengeId, expiresAt set). step signed_in: the app's SMS second factor is off (staff_web by default) and the session has started: accessToken is set; a staff_web browser gets the refresh token as the emr_refresh cookie (refreshToken null), mobile apps in the body.

| Field | Type | Required | Description |
|---|---|---|---|
| `step` | string enum: `sms_code`, `signed_in` |  |  |
| `challengeId` | string(uuid) |  |  |
| `expiresAt` | string(date-time) |  |  |
| `accessToken` | string |  |  |
| `refreshToken` | string |  |  |
| `mustChangePassword` | boolean |  |  |

### LoginTokens

| Field | Type | Required | Description |
|---|---|---|---|
| `accessToken` | string |  |  |
| `refreshToken` | string |  | Mobile apps only. Null for staff_web device logins: the browser receives it as the HttpOnly emr_refresh cookie instead. |
| `mustChangePassword` | boolean |  |  |

### MciTag

| Field | Type | Required | Description |
|---|---|---|---|
| `tag` | string | yes |  |

### MciTagged

| Field | Type | Required | Description |
|---|---|---|---|
| `caseId` | string(uuid) |  |  |
| `mciTag` | string enum: `red`, `yellow`, `green`, `black` |  |  |
| `incidentId` | string(uuid) |  |  |

### Me

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `username` | string |  |  |
| `fullNameAr` | string |  |  |
| `fullNameEn` | string |  |  |
| `role` | string |  |  |
| `preferredLanguage` | string |  |  |
| `scopes` | [Scope](#scope)[] |  |  |
| `stateCodes` | string[] |  |  |
| `mustChangePassword` | boolean |  |  |

### Merge

| Field | Type | Required | Description |
|---|---|---|---|
| `keepId` | string(uuid) | yes |  |
| `mergeId` | string(uuid) | yes |  |
| `reason` | string | yes |  |

### Message

| Field | Type | Required | Description |
|---|---|---|---|
| `code` | string |  |  |
| `expiresAt` | string(date-time) |  |  |

### NationalId

| Field | Type | Required | Description |
|---|---|---|---|
| `nationalId` | string | yes |  |
| `verified` | boolean |  |  |

### NearbyArea

| Field | Type | Required | Description |
|---|---|---|---|
| `areaId` | string(uuid) |  |  |
| `areaNameAr` | string |  |  |
| `areaNameEn` | string |  |  |
| `distanceM` | number(double) |  |  |

### NearestHospital

| Field | Type | Required | Description |
|---|---|---|---|
| `hospitalId` | string(uuid) |  |  |
| `code` | string |  |  |
| `nameAr` | string |  |  |
| `nameEn` | string |  |  |
| `erStatus` | string enum: `working`, `partly_working`, `not_working` |  |  |
| `availableAmbulances` | integer(int32) |  | Ambulances available now |
| `distanceM` | number(double) |  |  |
| `isOutOfDate` | boolean |  | ER status not updated recently (setting hospital.status_stale_hours) |
| `latitude` | number(double) |  |  |
| `longitude` | number(double) |  |  |
| `capabilities` | string[] |  | Capability codes (list hospital_capabilities), e.g. CATH_LAB, STROKE_UNIT |

### NewIncident

| Field | Type | Required | Description |
|---|---|---|---|
| `title` | string | yes |  |
| `lon` | number(double) | yes |  |
| `lat` | number(double) | yes |  |

### Observation

| Field | Type | Required | Description |
|---|---|---|---|
| `observedAt` | string(date-time) | yes |  |
| `caseId` | string(uuid) |  |  |
| `visitId` | string(uuid) |  |  |
| `heartRate` | integer(int32) |  |  |
| `respRate` | integer(int32) |  |  |
| `spo2` | integer(int32) |  |  |
| `onOxygen` | boolean |  |  |
| `systolic` | integer(int32) |  |  |
| `diastolic` | integer(int32) |  |  |
| `temperatureC` | number |  |  |
| `consciousness` | string |  |  |
| `bloodGlucoseMmol` | number |  |  |
| `painScore` | integer(int32) |  |  |
| `correctsId` | integer(int64) |  |  |
| `note` | string |  |  |

### OpenCase

Open case in the caller's states (queue row)

| Field | Type | Required | Description |
|---|---|---|---|
| `caseId` | string(uuid) |  |  |
| `caseNumber` | string |  |  |
| `stateCode` | string |  |  |
| `priority` | string enum: `P1`, `P2`, `P3`, `P4` |  |  |
| `step` | string enum: `call_received`, `urgency_set`, `request_sent`, `hospital_accepted`, `ambulance_sent`, `on_scene`, `transporting`, `handed_over`, `closed` |  |  |
| `complaint` | string |  |  |
| `createdAt` | string(date-time) |  |  |
| `waitingSeconds` | integer(int32) |  | Seconds since the case was created |
| `source` | string enum: `phone`, `app`, `sms` |  | Where the case came from |
| `requestDeadlineAt` | string(date-time) |  | Earliest deadline of a hospital request still waiting; warn when under a minute |
| `dispatchUnconfirmed` | boolean |  | An ambulance was sent and the crew has not confirmed within the confirm time |
| `incidentId` | string(uuid) |  |  |
| `mciTag` | string enum: `red`, `yellow`, `green`, `black` |  | START colour in a mass-casualty incident |

### Outcome

| Field | Type | Required | Description |
|---|---|---|---|
| `caseId` | string(uuid) |  |  |
| `outcome` | string |  |  |
| `outcomeAt` | string(date-time) |  |  |
| `note` | string |  |  |
| `recordedAt` | string(date-time) |  |  |

### OutcomeInput

| Field | Type | Required | Description |
|---|---|---|---|
| `outcome` | string | yes |  |
| `outcomeAt` | string(date-time) | yes |  |
| `note` | string |  |  |

### OverviewItem

| Field | Type | Required | Description |
|---|---|---|---|
| `stateCode` | string |  |  |
| `item` | string enum: `open_cases_p1`, `open_cases_total`, `waiting_for_hospital`, `requests_waiting`, `refused_or_timed_out_last_hour`, `jobs_not_confirmed`, `app_requests_waiting`, `manual_priority_changes_24h` |  | jobs_not_confirmed and app_requests_waiting are national counts (not limited to stateCode) |
| `itemCount` | integer(int32) |  |  |

### OwnDeviceView

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `clientApp` | string |  |  |
| `appVersion` | string |  |  |
| `blockedAt` | string(date-time) |  |  |
| `createdAt` | string(date-time) |  |  |
| `lastSeenAt` | string(date-time) |  |  |
| `pushRegistered` | boolean |  |  |

### Page

| Field | Type | Required | Description |
|---|---|---|---|
| `content` | map<string, any>[] |  |  |
| `page` | integer(int32) |  |  |
| `size` | integer(int32) |  |  |
| `hasNext` | boolean |  |  |
| `totalElements` | integer(int64) |  |  |

### PasswordResetIssued

Old password stops working and every session ends. Web staff (SMS second factor off): a one-time temporary password, shown once, changed at next sign-in. Mobile users: an SMS code; they set a new password with /api/v1/auth/reset-password.

| Field | Type | Required | Description |
|---|---|---|---|
| `userId` | string(uuid) |  |  |
| `method` | string enum: `temporary_password`, `sms` |  |  |
| `challengeId` | string(uuid) |  |  |
| `expiresAt` | string(date-time) |  |  |
| `temporaryPassword` | string |  | Method temporary_password only. Shown once; never stored or logged |

### Patient

| Field | Type | Required | Description |
|---|---|---|---|
| `nationalId` | string |  |  |
| `temporary` | boolean |  |  |
| `temporaryLabel` | string |  |  |
| `estimatedAge` | integer(int32) |  |  |
| `birthDate` | string(date) |  |  |
| `fullNameAr` | string | yes |  |
| `fullNameEn` | string |  |  |
| `sex` | string | yes |  |
| `phone` | string |  |  |
| `motherName` | string |  |  |

### PatientRow

| Field | Type | Required | Description |
|---|---|---|---|
| `hospitalId` | string(uuid) |  |  |
| `category` | string |  |  |
| `count` | integer(int64) |  |  |

### PatientsReport

| Field | Type | Required | Description |
|---|---|---|---|
| `report` | string |  |  |
| `timezone` | string |  |  |
| `from` | string(date) |  |  |
| `to` | string(date) |  |  |
| `labels` | map<string, [Label](#label)> |  |  |
| `sections` | [PatientsSections](#patientssections) |  |  |

### PatientsSections

| Field | Type | Required | Description |
|---|---|---|---|
| `counts` | [PatientRow](#patientrow)[] |  |  |

### Payment

| Field | Type | Required | Description |
|---|---|---|---|
| `amount` | number | yes |  |
| `method` | string | yes |  |
| `reference` | string |  |  |

### PaymentRow

| Field | Type | Required | Description |
|---|---|---|---|
| `hospitalId` | string(uuid) |  |  |
| `currency` | string |  |  |
| `method` | string |  |  |
| `count` | integer(int64) |  |  |
| `paid` | number |  |  |

### Phone

| Field | Type | Required | Description |
|---|---|---|---|
| `calledNumber` | string |  |  |
| `result` | string | yes |  |
| `note` | string |  |  |

### PhoneCall

| Field | Type | Required | Description |
|---|---|---|---|
| `calledAt` | string(date-time) |  |  |
| `calledNumber` | string |  |  |
| `result` | string |  |  |
| `note` | string |  |  |

### Pin

| Field | Type | Required | Description |
|---|---|---|---|
| `oldPin` | string |  |  |
| `pin` | string | yes |  |

### PlaceMatch

| Field | Type | Required | Description |
|---|---|---|---|
| `kind` | string enum: `area`, `landmark` |  |  |
| `id` | string(uuid) |  |  |
| `nameAr` | string |  |  |
| `nameEn` | string |  |  |
| `score` | number(double) |  |  |
| `distanceM` | number(double) |  |  |
| `location` | [GeoPoint](#geopoint) |  |  |

### PlaceView

Active area or approved landmark matching the search

| Field | Type | Required | Description |
|---|---|---|---|
| `kind` | string enum: `area`, `landmark` |  |  |
| `id` | string(uuid) |  |  |
| `nameAr` | string |  |  |
| `nameEn` | string |  |  |
| `longitude` | number(double) |  |  |
| `latitude` | number(double) |  |  |
| `createdAt` | string(date-time) |  |  |

### Point

| Field | Type | Required | Description |
|---|---|---|---|
| `clientPointId` | string(uuid) | yes |  |
| `recordedAt` | string(date-time) | yes |  |
| `lon` | number(double) | yes |  |
| `lat` | number(double) | yes |  |
| `accuracyM` | number(float) |  |  |
| `speedKmh` | number(float) |  |  |
| `headingDeg` | number(float) |  |  |

### Position

Last known ambulance position. source tracker = Wialon, phone = crew app. ageSeconds tells how fresh it is

| Field | Type | Required | Description |
|---|---|---|---|
| `lon` | number(double) |  |  |
| `lat` | number(double) |  |  |
| `recordedAt` | string(date-time) |  |  |
| `source` | string |  |  |
| `ageSeconds` | integer(int32) |  |  |

### Priority

| Field | Type | Required | Description |
|---|---|---|---|
| `priority` | string | yes |  |
| `reason` | string | yes |  |

### PriorityChange

| Field | Type | Required | Description |
|---|---|---|---|
| `oldPriority` | string |  |  |
| `newPriority` | string |  |  |
| `source` | string |  |  |
| `reason` | string |  |  |
| `changedBy` | string(uuid) |  |  |
| `changedAt` | string(date-time) |  |  |

### PriorityCount

| Field | Type | Required | Description |
|---|---|---|---|
| `priority` | string |  |  |
| `count` | integer(int64) |  |  |

### Push

| Field | Type | Required | Description |
|---|---|---|---|
| `pushToken` | string | yes |  |

### QaCandidate

A finished call not yet reviewed by the caller

| Field | Type | Required | Description |
|---|---|---|---|
| `callId` | string(uuid) |  |  |
| `channel` | string enum: `phone`, `app`, `sms` |  |  |
| `startedAt` | string(date-time) |  |  |
| `answeredAt` | string(date-time) |  |  |
| `endedAt` | string(date-time) |  |  |
| `result` | string |  |  |
| `stateCode` | string |  |  |
| `agentId` | string(uuid) |  |  |
| `caseId` | string(uuid) |  |  |
| `caseNumber` | string |  |  |
| `priority` | string |  |  |
| `secondsToConfirmed` | integer(int32) |  | Seconds from call start to ambulance confirmed |

### QaInput

| Field | Type | Required | Description |
|---|---|---|---|
| `callId` | string(uuid) | yes |  |
| `score` | integer(int32) | yes |  |
| `protocolFollowed` | boolean | yes |  |
| `timeTargetMet` | boolean | yes |  |
| `notes` | string |  |  |

### QaReview

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `callId` | string(uuid) |  |  |
| `reviewerId` | string(uuid) |  |  |
| `score` | integer(int32) |  |  |
| `protocolFollowed` | boolean |  |  |
| `timeTargetMet` | boolean |  |  |
| `notes` | string |  |  |
| `createdAt` | string(date-time) |  |  |

### RaiseAlert

| Field | Type | Required | Description |
|---|---|---|---|
| `type` | string | yes |  |
| `note` | string |  |  |

### RateRow

| Field | Type | Required | Description |
|---|---|---|---|
| `hospitalId` | string(uuid) |  |  |
| `sent` | integer(int64) |  |  |
| `accepted` | integer(int64) |  |  |
| `acceptanceRate` | number |  | Percent |

### Reason

| Field | Type | Required | Description |
|---|---|---|---|
| `reason` | string | yes |  |

### Reassign

| Field | Type | Required | Description |
|---|---|---|---|
| `agentId` | string(uuid) | yes |  |
| `reason` | string | yes |  |

### Reassigned

| Field | Type | Required | Description |
|---|---|---|---|
| `callId` | string(uuid) |  |  |
| `caseId` | string(uuid) |  |  |
| `agentId` | string(uuid) |  |  |

### Refresh

| Field | Type | Required | Description |
|---|---|---|---|
| `refreshToken` | string | yes |  |

### Refuse

| Field | Type | Required | Description |
|---|---|---|---|
| `reasonCode` | string | yes |  |
| `note` | string |  |  |

### Report

| Field | Type | Required | Description |
|---|---|---|---|
| `imported` | integer(int32) |  |  |
| `skipped` | integer(int32) |  |  |
| `errors` | [RowError](#rowerror)[] |  |  |

### Request

| Field | Type | Required | Description |
|---|---|---|---|
| `hospitalId` | string(uuid) | yes |  |
| `choiceReason` | string |  |  |
| `overrideReason` | string |  |  |
| `crossStateReason` | string |  |  |

### RequestRow

| Field | Type | Required | Description |
|---|---|---|---|
| `hospitalId` | string(uuid) |  |  |
| `status` | string |  |  |
| `refuseReason` | string |  |  |
| `count` | integer(int64) |  |  |

### Resend

| Field | Type | Required | Description |
|---|---|---|---|
| `challengeId` | string(uuid) | yes |  |

### Reset

| Field | Type | Required | Description |
|---|---|---|---|
| `challengeId` | string(uuid) | yes |  |
| `code` | string | yes |  |
| `newPassword` | string | yes |  |

### ResetRequested

Always returned, for known and unknown usernames alike. For clientApp staff_web there is no self-service reset: challengeId and expiresAt are null and the message says to ask an administrator.

| Field | Type | Required | Description |
|---|---|---|---|
| `challengeId` | string(uuid) |  |  |
| `expiresAt` | string(date-time) |  |  |
| `message_ar` | string |  |  |
| `message_en` | string |  |  |

### ResponseTimesReport

| Field | Type | Required | Description |
|---|---|---|---|
| `report` | string |  |  |
| `timezone` | string |  |  |
| `from` | string(date) |  |  |
| `to` | string(date) |  |  |
| `labels` | map<string, [Label](#label)> |  |  |
| `sections` | [ResponseTimesSections](#responsetimessections) |  |  |

### ResponseTimesSections

| Field | Type | Required | Description |
|---|---|---|---|
| `times` | [TimesRow](#timesrow)[] |  |  |
| `targets` | [TargetRow](#targetrow)[] |  |  |

### RowError

| Field | Type | Required | Description |
|---|---|---|---|
| `row` | integer(int32) |  |  |
| `reason` | [ApiError](#apierror) |  |  |

### Scope

| Field | Type | Required | Description |
|---|---|---|---|
| `type` | string |  | Deprecated: use scopeType (same value) |
| `stateId` | string(uuid) |  |  |
| `hospitalId` | string(uuid) |  |  |
| `scopeType` | string enum: `state`, `hospital`, `national` |  | Same name as in admin scope responses |

### ScopeInput

One scope. state needs stateId, hospital needs hospitalId, national needs neither. The database checks which scopes each role may hold.

| Field | Type | Required | Description |
|---|---|---|---|
| `hospitalId` | string(uuid) |  |  |
| `scopeType` | string enum: `state`, `hospital`, `national` | yes |  |
| `stateId` | string(uuid) |  |  |

### ScopeView

| Field | Type | Required | Description |
|---|---|---|---|
| `scopeType` | string enum: `state`, `hospital`, `national` |  |  |
| `stateId` | string(uuid) |  |  |
| `hospitalId` | string(uuid) |  |  |

### Send

| Field | Type | Required | Description |
|---|---|---|---|
| `ambulanceId` | string(uuid) | yes |  |

### SessionsRevoked

| Field | Type | Required | Description |
|---|---|---|---|
| `deviceId` | string(uuid) |  |  |
| `revokedSessions` | integer(int32) |  | Sessions logged out by this call |

### SettingChange

New setting value as text. The database checks the setting's type and range.

| Field | Type | Required | Description |
|---|---|---|---|
| `value` | string | yes |  |

### SettingHistoryView

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | integer(int64) |  |  |
| `key` | string |  |  |
| `oldValue` | string |  |  |
| `newValue` | string |  |  |
| `changedAt` | string(date-time) |  |  |
| `changedBy` | string(uuid) |  |  |

### SettingView

| Field | Type | Required | Description |
|---|---|---|---|
| `key` | string |  |  |
| `value` | string |  |  |
| `valueType` | string |  |  |
| `minValue` | integer(int32) |  |  |
| `maxValue` | integer(int32) |  |  |
| `descriptionAr` | string |  |  |
| `descriptionEn` | string |  |  |
| `updatedAt` | string(date-time) |  |  |
| `updatedBy` | string(uuid) |  |  |

### Shift

| Field | Type | Required | Description |
|---|---|---|---|
| `qrToken` | string | yes |  |

### Sos

| Field | Type | Required | Description |
|---|---|---|---|
| `lon` | number(double) | yes |  |
| `lat` | number(double) | yes |  |
| `accuracyM` | number(double) |  |  |
| `note` | string |  |  |

### SosClose

| Field | Type | Required | Description |
|---|---|---|---|
| `result` | string | yes |  |
| `note` | string |  |  |

### Start

| Field | Type | Required | Description |
|---|---|---|---|
| `phone` | string | yes |  |

### StateView

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `code` | string |  |  |
| `nameAr` | string |  |  |
| `nameEn` | string |  |  |
| `capitalAr` | string |  |  |
| `capitalEn` | string |  |  |

### Status

| Field | Type | Required | Description |
|---|---|---|---|
| `status` | string | yes |  |
| `statusTime` | string(date-time) | yes |  |

### StepEvent

| Field | Type | Required | Description |
|---|---|---|---|
| `step` | string |  |  |
| `occurredAt` | string(date-time) |  |  |
| `recordedAt` | string(date-time) |  |  |
| `recordedBy` | string(uuid) |  |  |

### Suspend

| Field | Type | Required | Description |
|---|---|---|---|
| `reason` | string | yes |  |

### TargetRow

Target for answered-to-on-scene minutes; admins change it in settings report.response_target_minutes.p1-p4

| Field | Type | Required | Description |
|---|---|---|---|
| `priority` | string |  |  |
| `targetMinutes` | integer(int32) |  |  |

### Tariff

| Field | Type | Required | Description |
|---|---|---|---|
| `stateId` | string(uuid) |  |  |
| `hospitalId` | string(uuid) |  |  |
| `ambulanceType` | string |  |  |
| `baseFee` | number |  |  |
| `perKmFee` | number |  |  |
| `currency` | string |  |  |
| `validFrom` | string(date) |  |  |
| `validTo` | string(date) |  |  |
| `status` | string |  |  |
| `note` | string |  |  |

### TariffView

Tariff row

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `hospitalId` | string(uuid) |  |  |
| `stateId` | string(uuid) |  |  |
| `ambulanceType` | string |  |  |
| `baseFee` | number |  |  |
| `perKmFee` | number |  |  |
| `currency` | string |  |  |
| `validFrom` | string(date) |  |  |
| `validTo` | string(date) |  |  |
| `status` | string |  |  |
| `note` | string |  |  |

### TimesRow

| Field | Type | Required | Description |
|---|---|---|---|
| `period` | string |  | Start of the hour or day (Khartoum time) when bucket is set; null for the whole period |
| `priority` | string |  |  |
| `stage` | string enum: `answered_to_created`, `created_to_accepted`, `accepted_to_sent`, `sent_to_on_scene`, `on_scene_to_at_hospital` |  |  |
| `samples` | integer(int64) |  |  |
| `medianMinutes` | number |  |  |
| `p90Minutes` | number |  |  |

### TrackerRow

| Field | Type | Required | Description |
|---|---|---|---|
| `hospitalId` | string(uuid) |  |  |
| `silentTrackers` | integer(int64) |  |  |

### TrackerView

| Field | Type | Required | Description |
|---|---|---|---|
| `ambulanceId` | string(uuid) |  |  |
| `plateNumber` | string |  |  |
| `hospitalId` | string(uuid) |  |  |
| `wialonUnitId` | integer(int64) |  |  |
| `lastWialonPointAt` | string(date-time) |  |  |
| `status` | string enum: `silent`, `no_data_yet`, `not_linked`, `ok` |  |  |
| `createdAt` | string(date-time) |  |  |

### Treatment

| Field | Type | Required | Description |
|---|---|---|---|
| `givenAt` | string(date-time) | yes |  |
| `caseId` | string(uuid) |  |  |
| `visitId` | string(uuid) |  |  |
| `kind` | string | yes |  |
| `name` | string | yes |  |
| `dose` | string |  |  |
| `route` | string |  |  |
| `note` | string |  |  |
| `correctsId` | integer(int64) |  |  |

### TriageAnswer

One answer option of a triage question

| Field | Type | Required | Description |
|---|---|---|---|
| `code` | string | yes |  |
| `ar` | string | yes |  |
| `en` | string | yes |  |

### TriageHistoryView

One change to a triage question: who, when, and the values before and after

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | integer(int64) |  |  |
| `occurredAt` | string(date-time) |  |  |
| `userId` | string(uuid) |  |  |
| `roleCode` | string |  |  |
| `action` | string enum: `create`, `update` |  |  |
| `oldValues` | [TriageQuestionView](#triagequestionview) |  |  |
| `newValues` | [TriageQuestionView](#triagequestionview) |  |  |

### TriageQuestion

| Field | Type | Required | Description |
|---|---|---|---|
| `questionCode` | string |  |  |
| `textAr` | string |  |  |
| `textEn` | string |  |  |
| `answers` | [TriageAnswer](#triageanswer)[] |  |  |
| `modelVersion` | string |  |  |

### TriageQuestionCreate

New triage question. Model, version and code together must be unique.

| Field | Type | Required | Description |
|---|---|---|---|
| `sortOrder` | integer(int32) |  |  |
| `triageModel` | string | yes |  |
| `modelVersion` | string | yes |  |
| `questionCode` | string | yes |  |
| `textAr` | string | yes | Non-blank text, at most 2000 characters |
| `textEn` | string | yes | Non-blank text, at most 2000 characters |
| `answers` | [TriageAnswer](#triageanswer)[] | yes |  |

### TriageQuestionEdit

Change triage question text, answers, order or status (inactive disables it). Model, version and code cannot change.

| Field | Type | Required | Description |
|---|---|---|---|
| `status` | string enum: `active`, `inactive` |  |  |
| `sortOrder` | integer(int32) |  |  |
| `textAr` | string |  | Non-blank text, at most 2000 characters |
| `textEn` | string |  | Non-blank text, at most 2000 characters |
| `answers` | [TriageAnswer](#triageanswer)[] |  |  |

### TriageQuestionView

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) |  |  |
| `triageModel` | string |  |  |
| `modelVersion` | string |  |  |
| `questionCode` | string |  |  |
| `textAr` | string |  |  |
| `textEn` | string |  |  |
| `answers` | [TriageAnswer](#triageanswer)[] |  |  |
| `sortOrder` | integer(int32) |  |  |
| `status` | string enum: `active`, `inactive` |  |  |
| `createdAt` | string(date-time) |  |  |
| `createdBy` | string(uuid) |  |  |
| `updatedAt` | string(date-time) |  |  |
| `updatedBy` | string(uuid) |  |  |

### TypeRow

| Field | Type | Required | Description |
|---|---|---|---|
| `emergencyTypeCode` | string |  |  |
| `count` | integer(int64) |  |  |

### UserCreate

New staff user. Sends a first-login SMS; the user sets a password with /api/v1/auth/reset-password.

| Field | Type | Required | Description |
|---|---|---|---|
| `username` | string | yes | Login name; cannot be changed later |
| `fullNameAr` | string | yes | Non-blank text, at most 2000 characters |
| `fullNameEn` | string | yes | Non-blank text, at most 2000 characters |
| `phone` | string | yes | Sudan mobile number; must be unique |
| `roleCode` | string enum: `SYSTEM_ADMIN`, `CALL_CENTRE`, `CALL_SUPERVISOR`, `HOSPITAL_ER`, `HOSPITAL_STAFF`, `DOCTOR`, `NURSE`, `LAB`, `DRIVER`, `PARAMEDIC` | yes |  |
| `preferredLanguage` | string enum: `ar`, `en` |  |  |

### UserCreated

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) | yes |  |
| `username` | string |  |  |
| `fullNameAr` | string |  |  |
| `fullNameEn` | string |  |  |
| `phone` | string |  |  |
| `roleCode` | string |  |  |
| `preferredLanguage` | string |  |  |
| `status` | string |  |  |
| `mustChangePassword` | boolean |  |  |
| `lockedUntil` | string(date-time) |  |  |
| `failedLoginCount` | integer(int32) |  |  |
| `createdAt` | string(date-time) |  |  |
| `updatedAt` | string(date-time) |  |  |
| `passwordMethod` | string enum: `temporary_password`, `sms` |  | Web staff: a one-time temporary password (show it once, with a copy button). Crew: an SMS code for /api/v1/auth/reset-password |
| `challengeId` | string(uuid) |  | First-login SMS challenge (method sms) |
| `expiresAt` | string(date-time) |  |  |
| `temporaryPassword` | string |  | Method temporary_password only. Shown once; the user must change it at first sign-in. Never stored or logged |

### UserDetail

User with current scopes

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) | yes |  |
| `username` | string |  |  |
| `fullNameAr` | string |  |  |
| `fullNameEn` | string |  |  |
| `phone` | string |  |  |
| `roleCode` | string |  |  |
| `preferredLanguage` | string |  |  |
| `status` | string enum: `active`, `disabled` |  |  |
| `mustChangePassword` | boolean |  |  |
| `lockedUntil` | string(date-time) |  |  |
| `failedLoginCount` | integer(int32) |  |  |
| `createdAt` | string(date-time) |  |  |
| `updatedAt` | string(date-time) |  |  |
| `scopes` | [ScopeView](#scopeview)[] | yes | Current scopes; send the edited list to PUT /api/v1/admin/users/{id}/scopes |

### UserEdit

Change one or more user fields. Username cannot change. Changing role re-validates scopes.

| Field | Type | Required | Description |
|---|---|---|---|
| `fullNameAr` | string |  | Non-blank text, at most 2000 characters |
| `fullNameEn` | string |  | Non-blank text, at most 2000 characters |
| `phone` | string |  |  |
| `roleCode` | string enum: `SYSTEM_ADMIN`, `CALL_CENTRE`, `CALL_SUPERVISOR`, `HOSPITAL_ER`, `HOSPITAL_STAFF`, `DOCTOR`, `NURSE`, `LAB`, `DRIVER`, `PARAMEDIC` |  |  |
| `preferredLanguage` | string enum: `ar`, `en` |  |  |

### UserView

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string(uuid) | yes |  |
| `username` | string |  |  |
| `fullNameAr` | string |  |  |
| `fullNameEn` | string |  |  |
| `phone` | string |  |  |
| `roleCode` | string |  |  |
| `preferredLanguage` | string |  |  |
| `status` | string enum: `active`, `disabled` |  |  |
| `mustChangePassword` | boolean |  |  |
| `lockedUntil` | string(date-time) |  | Set while the account is locked after wrong passwords |
| `failedLoginCount` | integer(int32) |  |  |
| `createdAt` | string(date-time) |  |  |
| `updatedAt` | string(date-time) |  |  |

### Verify

| Field | Type | Required | Description |
|---|---|---|---|
| `challengeId` | string(uuid) | yes |  |
| `code` | string | yes |  |

### Waive

| Field | Type | Required | Description |
|---|---|---|---|
| `reason` | string | yes |  |

### WaiverView

Waived ambulance charge (read-only for admins)

| Field | Type | Required | Description |
|---|---|---|---|
| `chargeId` | string(uuid) |  |  |
| `hospitalId` | string(uuid) |  |  |
| `stateId` | string(uuid) |  |  |
| `total` | number |  |  |
| `currency` | string |  |  |
| `reason` | string |  |  |
| `waivedBy` | string(uuid) |  |  |
| `waivedAt` | string(date-time) |  |  |

### WialonLink

Link a Wialon unit to the ambulance; null unlinks.

| Field | Type | Required | Description |
|---|---|---|---|
| `wialonUnitId` | integer(int64) | yes |  |
