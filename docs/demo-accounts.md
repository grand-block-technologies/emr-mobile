# Demo Accounts

| Setting | Value |
| --- | --- |
| Password (all accounts) | `Demo-Pass-2026` |
| Web app | http://localhost:5173 |
| Backend | https://scored-rotary-lite-cam.trycloudflare.com |
| API docs (Swagger) | https://scored-rotary-lite-cam.trycloudflare.com/swagger-ui/index.html |
| Tile server | https://cursor-dam-butter-tournament.trycloudflare.com (tunnel → port 8081) |
| SMS code | `GET /dev/sms/latest?phone=<phone>`, using the account's number below |
| Switching accounts | Log out before signing in with the next account |
| Lockout | Five wrong passwords lock the account for 30 minutes |

## Accounts

| Username | Role | What you see after login | Phone |
| --- | --- | --- | --- |
| `demo.admin` | System admin | Administration (all states) | +249999990101 |
| `demo.admin.kh` | System admin | Administration, locked to Khartoum | +249999990116 |
| `demo.call1` | Call centre | Queue | +249999990102 |
| `demo.call2` | Call centre | Queue | +249999990103 |
| `demo.supervisor` | Call supervisor | Queue | +249999990112 |
| `demo.er.h1` | Hospital ER, Riyadh | Hospital emergency | +249999990104 |
| `demo.er.h2` | Hospital ER, Thawra | Hospital emergency | +249999990105 |
| `demo.er.h3` | Hospital ER, Haj Yousif | Hospital emergency | +249999990106 |
| `demo.staff.h1` | Hospital staff, Riyadh | Hospital staff | +249999990107 |
| `demo.doctor.h1` | Doctor, Riyadh | Hospital staff | +249999990113 |
| `demo.nurse.h1` | Nurse, Riyadh | Hospital staff | +249999990114 |
| `demo.lab.h1` | Lab, Riyadh | Hospital staff | +249999990115 |
| `demo.driver1` | Driver, Riyadh | Refused: phone app only | +249999990108 |
| `demo.driver2` | Driver, Thawra | Refused: phone app only | +249999990110 |
| `demo.driver3` | Driver, Haj Yousif | Refused: phone app only | +249999990111 |
| `demo.medic1` | Paramedic, Riyadh | Refused: phone app only | +249999990109 |
| `demo.citizen` | Citizen | Refused: phone app only | +249912345003 |
