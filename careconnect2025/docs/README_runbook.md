# CareConnect Demo API — Runbook (M3 W5–W6)
## Start
cd careconnect2025/backend
npm install
export HOST=0.0.0.0 PORT=8000
npm run dev
## Credentials
- patient / pass (PATIENT)
- caregiver / pass (CAREGIVER)
## Endpoints
GET /health
GET /auth/me (Basic Auth)
POST /notes {text}
GET /notes[?q=term]
POST /triggers/propose {text}
POST /pii/sanitize {text}
Notes are in-memory for demo.

## Prereqs
- Java 17 (OpenJDK 17). Verify with `java -version`. If not installed, install `openjdk-17-jdk` and set `JAVA_HOME`.
