# Client Approval — Milestone 3 (Team A)

## Demo Script (~15 min)
1) Auth/RBAC: register + login; show role-gated action blocked for PATIENT and allowed for CAREGIVER/ADMIN.
2) Session: show access expiry → refresh token rotates → retry succeeds.
3) ASL MVP: input short sentence → ASL playback; unknown words → fingerspelling + captions.
4) PII: attempt SSN/CC in a note → UI warns; server stores redacted; logs sanitized.
5) Environment: show docker services, backend up, app running end-to-end.

## Acceptance Criteria
- AC-AUTH-01: Register/login works; RBAC enforced.
- AC-SESSION-01: Access expires; refresh rotates; retry succeeds.
- AC-ASL-01: Text→ASL renders or falls back to fingerspelling+captions.
- AC-PII-01: Logs masked; restricted patterns blocked/redacted.
- AC-ENV-01: New dev can run stack from ENV_SETUP.md.

## Sign-off
Role | Name | Signature (email ok) | Date
---|---|---|---
Client |  |  | 
PM |  |  | 
Tech Lead |  |  | 
QA Lead |  |  | 
