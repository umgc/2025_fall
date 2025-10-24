#!/bin/bash
# ================================
# CareConnect Database Reset Script
# ================================

set -e

echo "Resetting CareConnect PostgreSQL Database..."
echo "==========================================="

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_COMPOSE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$DOCKER_COMPOSE_DIR"

# Stop and remove containers
echo "Stopping PostgreSQL containers..."
docker compose down

# Remove the PostgreSQL volume to completely reset the database
echo "Removing PostgreSQL data volume..."
docker volume rm pg_docker_postgres 2>/dev/null || echo "Volume already removed or doesn't exist"

# Start PostgreSQL again (this will recreate the database)
echo "Starting fresh PostgreSQL container..."
docker compose up -d postgres

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
timeout=60
counter=0
while ! docker exec postgres_container pg_isready -U postgres -d careconnect > /dev/null 2>&1; do
    sleep 2
    counter=$((counter + 2))
    if [ $counter -ge $timeout ]; then
        echo "Error: PostgreSQL failed to start within $timeout seconds"
        exit 1
    fi
done

echo "PostgreSQL is ready!"
echo ""
echo "Database has been reset successfully!"
echo "You can now run your Spring Boot application with the dev profile:"
echo "  ./mvnw spring-boot:run -Dspring.profiles.active=dev"
echo ""
echo "JPA will auto-create schema when application starts:"
echo "  ./mvnw spring-boot:run -Dspring.profiles.active=dev"
echo ""
echo "PgAdmin is available at: http://localhost:5050"
echo "  Email: pgadmin4@pgadmin.org"
echo "  Password: admin"