#!/usr/bin/env bash
set -euo pipefail
mkdir -p .logs

# Install tools (inside Codespaces only)
sudo apt-get update -y
sudo apt-get install -y postgresql postgresql-contrib python3-pip curl >/dev/null

# Make sure Node 20 exists
if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - >/dev/null
  sudo apt-get install -y nodejs >/dev/null
fi

# Start Postgres and create db/user
sudo service postgresql start
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='careconnect'" | grep -q 1 || sudo -u postgres psql -c "CREATE USER careconnect WITH PASSWORD 'careconnect';"
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='careconnect'" | grep -q 1 || sudo -u postgres psql -c "CREATE DATABASE careconnect OWNER careconnect;"

# Point frontend to your Codespace API URL (port 8000)
if [ -n "${CODESPACE_NAME:-}" ] && [ -n "${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-}" ]; then
  API_URL="https://8000-${CODESPACE_NAME}.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
  echo "VITE_API_URL=$API_URL" > frontend/.env
fi

# Start backend (FastAPI or Node — auto-detect)
if [ -f backend/requirements.txt ]; then
  python3 -m pip install --user -r backend/requirements.txt >/dev/null
  pkill -f uvicorn || true
  nohup python3 -m uvicorn app.main:app --app-dir backend --host 0.0.0.0 --port 8000 > .logs/backend.log 2>&1 &
elif [ -f backend/package.json ]; then
  (cd backend && npm ci >/dev/null && pkill -f "node .*8000" || true && nohup npm run dev > ../.logs/backend.log 2>&1 &)
else
  echo "[backend] No backend found (need backend/requirements.txt or backend/package.json)"
fi

# Start frontend (Vite)
if [ -f frontend/package.json ]; then
  (cd frontend && npm ci >/dev/null && pkill -f vite || true && nohup npm run dev -- --host 0.0.0.0 > ../.logs/frontend.log 2>&1 &)
else
  echo "[frontend] No frontend found (need frontend/package.json)"
fi

echo "✅ Started. Open the PORTS panel and click the globe for 5173 (web) and 8000 (API)."
