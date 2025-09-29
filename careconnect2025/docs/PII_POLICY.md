# PII/PHI Mask & Block Policy

Never log: access/refresh tokens, SSN, credit card, Medicaid #, DOB+full name, full addresses.
Sanitization: all request/response logs must pass a sanitizer (email/phone/SSN/CC patterns).
Blocking: user-visible features (chat/notes) reject SSN/CC patterns; store only redacted; add audit entry.
Transport/At-rest: TLS-only; encrypted storage with key rotation and least-privilege IAM.
Developer discipline: no plaintext secrets in code/issues; use .env and secret stores.
