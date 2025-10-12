#!/bin/bash
# ================================
# CareConnect Database Migration Script (JPA)
# ================================

set -e

echo "CareConnect Database Migration (JPA-based)..."
echo "============================================="

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

# JPA will handle schema creation automatically
echo "JPA will handle database schema creation automatically when the application starts."
echo "No manual migrations needed - schema is managed by JPA/Hibernate."

echo ""
echo "Database is ready for JPA schema creation!"
echo "Start your Spring Boot application to auto-create the schema:"
echo "  ./mvnw spring-boot:run -Dspring.profiles.active=dev"