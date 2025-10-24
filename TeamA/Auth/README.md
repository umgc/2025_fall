# Team A — User Authentication & RBAC (M3)

**Auth domains**
- Identity: `UserAccount { id, email, passwordHash, roles[] }`
- Tokens: short-lived **access JWT** (15m), rotating **refresh token** (7d)
- Roles: `global_admin, local_admin, caregiver, patient, viewer`
- Sessions: stateless APIs (JWT in `Authorization: Bearer`), refresh via `/auth/refresh`

**Endpoints (`/auth/*`)**
- `POST /auth/register` — create user (demo scope; hashes password)
- `POST /auth/login` — returns `accessToken` + sets `refreshToken` (HttpOnly cookie for web; JSON also allowed for mobile demo)
- `POST /auth/refresh` — rotate refresh token; new access token
- `POST /auth/logout` — invalidate refresh token

**RBAC middleware**
- Verify JWT on each request (Security filter)
- Attach `roles` claim into `SecurityContext`
- Guard routes by role (e.g., `hasRole('global_admin')`)

**Session policy**
- Access token: 15 minutes TTL
- Refresh token: 7 days TTL, single-use rotation; store server-side id
- Logout: revoke refresh token id; access token naturally expires
- Storage: in-memory for M3 demo; move to DB/Cognito in M4
