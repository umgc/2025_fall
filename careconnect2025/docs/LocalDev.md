# Local Dev (Codespaces)
1) Start DB: `docker compose -f docker-compose.db.yml up -d`
2) Start API
   - Spring Boot: `./mvnw spring-boot:run -Dspring-boot.run.profiles=local`
   - Node: `npm ci && npm run dev` (PORT from .env, 8000/8010)
3) Start Frontend
   - Flutter Web: `flutter pub get && flutter run -d chrome`
   - (If using React demo) `npm ci && npm run dev -- --host`
4) Proof: put 3 screenshots in `careconnect2025/proofs/Sadina/` (backend up, frontend up, Ports panel).
