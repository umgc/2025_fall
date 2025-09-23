# Technical Decision Rationale (Milestones 1–3)
**Goal:** Deliver a demo-ready slice (Weeks 5–6) while aligning with final architecture.

## Choices
- **Backend (Sprint demo):** Node/Express single service on :8000 for fast iteration.
- **Auth (demo):** Basic Auth with role claim to illustrate RBAC; future: JWT/OAuth2 (Keycloak/Cognito/Entra).
- **PII:** Regex-based sanitizer for email/phone/SSN; future: policy-driven + audit log.
- **Triggers:** Keyword detection -> returns calendar proposal object (AI-derived flag).
- **ASL:** Start with UI/flow prototype; future: real glossing + media pipeline.

## Tradeoffs
- In-memory notes vs persistence (speed > durability for demo).
- Basic Auth vs full OAuth (speed > production security).
- Regex PII vs full DLP (simplicity > coverage for demo).

## Links
- Runbook: README_runbook.md
- Architecture: ARCH_env.md, ARCHITECTURE.md
- Security/PII: SEC_piiconsent.md
