# CareConnect — Project & Code Structure

/careconnect2025
  /frontend/                     # Flutter app (patients/caregivers)
  /backend/
    /bff/                        # API-BFF (Spring Boot)
    /auth-service/               # AuthN/Z, RBAC, tokens
    /scheduler-service/          # Tasks, reminders (stub)
    /notes-service/              # Notetaker/transcripts (stub)
    /analytics-service/          # KPIs, reports (stub)
  /infra/
    docker-compose.yml           # Local MySQL + dev tools
  /docs/
    DECISIONS.md
    ENV_SETUP.md
    CLIENT_APPROVAL.md
    PII_POLICY.md
    SESSION_POLICY.md

Datastore (dev): MySQL (RDS in prod)
Media: S3 or local storage (LocalStack later)
Security: JWT access+refresh; RBAC at route & method level
