# Dev Environment Setup (Milestone 3)

## Prereqs
- Java 17 + Maven 3.9+
- Flutter SDK 3.24+ (Dart 3.x)
- Docker Desktop (or docker engine)
- Node 18+ (optional), AWS CLI v2 (optional)

## Branch
git checkout SadinaTeamA
git pull

## Local services
docker compose -f careconnect2025/infra/docker-compose.yml up -d
# MySQL @ localhost:3306 (user: root / pass: root)
# Mailhog UI @ http://localhost:8025

## Backend
cd careconnect2025/backend/auth-service
mvn -DskipTests spring-boot:run
# Flyway will create users/roles tables from V1__auth_core.sql

## BFF
cd ../bff
mvn -DskipTests spring-boot:run

## Frontend
cd ../../frontend
flutter pub get
flutter run

## Smoke (curl)
# 1) Login demo user → access+refresh
curl -s -XPOST localhost:8080/auth/login -H 'Content-Type: application/json' \
  -d '{"email":"demo@careconnect.app","password":"Passw0rd!"}'

# 2) Use access token on BFF /me
curl -s localhost:8081/me -H "Authorization: Bearer <ACCESS_TOKEN>"

# 3) Refresh
curl -s -XPOST localhost:8080/auth/refresh -H 'Content-Type: application/json' \
  -d '{"refreshToken":"<REFRESH_TOKEN>"}'
