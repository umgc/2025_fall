git checkout SadinaTeamA
cd careconnect2025/backend/asl-service
./mvnw spring-boot:run
# open http://localhost:8080/v1/asl/health  → {"status":"UP"}
# POST http://localhost:8080/v1/asl/translate  body: {"text":"appointment tuesday 3pm"}
