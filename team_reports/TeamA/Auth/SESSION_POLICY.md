# Session policy (Team A · M3)

- Access token (JWT): **15 minutes** TTL; carries `sub` (email) and `roles`.
- Refresh token: **7 days** TTL; **rotating**. Server stores a random `refreshId` linked to user.
- Storage (M3): in-memory map (demo); plan: move to DB or Cognito (M4).
- Login: returns access token and sets `refreshId` as HttpOnly cookie (web) or in JSON (mobile demo).
- Refresh: requires current `refreshId` (cookie or `X-Refresh-Id` header); issues new access token and new `refreshId`; old one is revoked.
- Logout: revokes current `refreshId` and clears cookie.
- CORS: allow app origins; secure cookie flags when HTTPS is available. No secrets in repo; set `JWT_SECRET` via environment.
