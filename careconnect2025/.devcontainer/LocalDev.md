# Local Dev (Codespaces)
1) Open this branch in a Codespace.
2) Run: `docker compose -f docker-compose.db.yml up -d`
3) Run: `bash scripts/start-all.sh`
4) In Ports tab, open **5173** (web) and **8000** (API).  
5) If API calls fail, copy the **8000** port URL and set `VITE_API_URL` in `frontend/.env` to that URL, then restart the frontend.
