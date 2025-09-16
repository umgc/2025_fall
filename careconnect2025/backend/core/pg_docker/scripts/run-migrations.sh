#!/bin/bash
# ================================
# CareConnect Flyway Migration Script
# ================================

set -e

echo "Running CareConnect Flyway Migrations..."
echo "======================================="

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

cd "$PROJECT_ROOT"

# Check if PostgreSQL is running
if ! docker ps --format "table {{.Names}}" | grep -q "postgres_container"; then
    echo "Error: PostgreSQL container is not running."
    echo "Please start it first with: cd pg_docker && docker-compose up -d postgres"
    exit 1
fi

# Wait for PostgreSQL to be ready
echo "Checking PostgreSQL connectivity..."
timeout=30
counter=0
while ! docker exec postgres_container pg_isready -U postgres -d careconnect > /dev/null 2>&1; do
    sleep 2
    counter=$((counter + 2))
    if [ $counter -ge $timeout ]; then
        echo "Error: PostgreSQL is not ready after $timeout seconds"
        exit 1
    fi
done

echo "PostgreSQL is ready!"

# Run Flyway migrations
echo "Running Flyway migrations..."
./mvnw flyway:migrate \
    -Dflyway.url=jdbc:postgresql://localhost:5432/careconnect \
    -Dflyway.user=postgres \
    -Dflyway.password=changeme \
    -Dflyway.locations=filesystem:src/main/resources/db/migration

echo ""
echo "Migrations completed successfully!"
echo "You can now run your Spring Boot application:"
echo "  ./mvnw spring-boot:run -Dspring.profiles.active=dev"