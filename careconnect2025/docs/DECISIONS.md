# Architecture Decision Record (ADR) — CareConnect (Team A)

## ADR-0001 — Cross-platform UI: Flutter
Decision: Flutter for iOS/Android/Web; single codebase, fast theming.
Rationale: Mobile + web parity with consistent UX; rapid iteration; strong plugin ecosystem.
Consequences: Use platform channels for native gaps.

## ADR-0002 — Backend: Spring Boot microservices (API-BFF + domain services)
Decision: API-BFF aggregates downstream services; domain services per bounded context.
Rationale: Clean separation (auth, scheduler, notes/comm, analytics); scales independently.
Consequences: Service-to-service auth; centralized logging/tracing.

## ADR-0003 — AuthN/Z: JWT access + refresh; RBAC roles
Decision: Access token (~15m) + refresh (7–14d); roles = PATIENT, CAREGIVER, FAMILY_MEMBER, SUPERVISOR, ADMIN.
Rationale: Stateless mobile sessions; least-privilege enforcement.
Consequences: Token rotation on refresh; secure storage on device; key rotation policy.

## ADR-0004 — Accessibility: on-device Text→ASL MVP + pluggable engine
Decision: Local asset engine (common phrases + A–Z fingerspelling) with a provider interface to swap in an avatar SDK later.
Rationale: Delivers value now; keeps PHI on device by default.
Consequences: Ship curated clip pack; clear fallback rules (captions/fingerspelling).

## ADR-0005 — Sensitive Data Controls: detect & mask PII/PHI
Decision: Request/response sanitization; block high-risk patterns; store redacted; audit exceptions.
Rationale: HIPAA-aligned posture; eliminates accidental leakage via logs.
Consequences: Shared masking utility; dev tool logs must pass sanitizer.
