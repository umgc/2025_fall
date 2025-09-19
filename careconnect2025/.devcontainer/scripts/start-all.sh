#!/usr/bin/env bash
set -euo pipefail
mkdir -p .logs

# Start/prepare DB (already handled by docker compose in Part 3)
echo "[bootstrap] Using Postgres at localhost:5432"

# Start backend
if [ -f backend/requirements.txt ]; then
  echo "[bootstrap] Detected Python backend."
  cd backend
  python3 -m pip install --upgrade pip
  python3 -m pip install -r requirements.txt
  nohup python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8000 > ../.logs/backend.log 2>&1 &
  cd ..
elif [ -f backend/package.json ]; then
  echo "[bootstrap] Detected Node backend."
  cd backend
  npm ci
  nohup npm run dev > ../.logs/backend.log 2>&1 &
  cd ..
else
  echo "[bootstrap] No supported backend detected (need backend/requirements.txt or backend/package.json)."
fi

# Start frontend
if [ -f frontend/package.json ]; then
  cd frontend
  npm ci
  nohup npm run dev -- --host 0.0.0.0 > ../.logs/frontend.log 2>&1 &
  cd ..
else
  echo "[bootstrap] No frontend detected."
fi

echo "[bootstrap] Started. Ports: 5173 (web), 8000 (api). Check the Ports panel."
