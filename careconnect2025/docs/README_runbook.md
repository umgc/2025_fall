# CareConnect Demo API — Runbook (M3 W5–W6)

## Start
```bash
cd careconnect2025/backend
npm install
export HOST=0.0.0.0 PORT=8000
npm run dev    # or npm start


2) **Architecture/Env (short)**
```bash
cat > ../docs/ARCH_env.md <<'EOF'
# Architecture & Env (Sprint Demo)

- Frontend: Flutter (target), ASL prototype planned.
- Backend (demo this sprint): Node/Express single service exposing health/auth/notes/triggers/pii.
- Longer-term: multi-service (per TDD), RBAC, consent/PII enforcement, calendar integration.
- Local Dev: Node v22, port 8000, bind 0.0.0.0 for Codespaces.
