#!/bin/bash

# THIS IS UNTESTED

# ================================
# CareConnect Backend Development Startup Script - macOS
# ================================

set -e  # Exit on error

echo "🍎 CareConnect Backend - macOS Development Setup"
echo "Loading environment variables..."

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found in current directory"
    echo "Please create a .env file based on the provided template"
    exit 1
fi

# Load environment variables from .env file
set -a  # Automatically export all variables
source .env
set +a  # Stop auto-exporting

echo "✅ Environment variables loaded successfully!"
echo "Database: $JDBC_URI"

# Verify critical variables are set
required_vars=(
    "JDBC_URI"
    "DB_USER" 
    "DB_PASSWORD"
    "SECURITY_JWT_SECRET"
    "FIREBASE_PROJECT_ID"
    "FIREBASE_SENDER_ID"
)

missing_vars=()
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -ne 0 ]; then
    echo "⚠️  Warning: The following critical environment variables are not set:"
    printf '%s\n' "${missing_vars[@]}"
    echo "Please update your .env file with the required values"
fi

echo "🚀 Starting CareConnect Backend in Development Mode..."
echo "=========================================="

# Check if Docker Desktop is running (macOS specific)
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker Desktop is not running."
    echo "Please start Docker Desktop from Applications or Launchpad"
    echo "You can also start it with: open -a Docker"
    read -p "Would you like to try opening Docker Desktop? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open -a Docker
        echo "Waiting for Docker Desktop to start..."
        sleep 15
        # Retry docker info
        if ! docker info > /dev/null 2>&1; then
            echo "❌ Docker Desktop is still not ready. Please start it manually and try again."
            exit 1
        fi
    else
        exit 1
    fi
fi

# Check if PostgreSQL container is running, start if not
echo "🐘 Checking PostgreSQL Docker container..."
if ! docker ps --format "table {{.Names}}" | grep -q "postgres_container"; then
    echo "PostgreSQL container not running. Starting it now..."

    # Check if docker-compose.yml exists
    if [ ! -f "pg_docker/docker-compose.yml" ]; then
        echo "❌ Error: pg_docker/docker-compose.yml not found"
        echo "Please ensure the PostgreSQL Docker setup is in place"
        exit 1
    fi

    # Start PostgreSQL container
    echo "Starting PostgreSQL with Docker Compose..."
    cd pg_docker
    docker-compose up -d postgres
    cd ..

    echo "⏳ Waiting for PostgreSQL to be ready..."
    sleep 10

    # Test PostgreSQL connection
    max_attempts=30
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if docker exec postgres_container pg_isready -U postgres > /dev/null 2>&1; then
            echo "✅ PostgreSQL is ready!"
            break
        fi
        echo "⏳ Waiting for PostgreSQL... (attempt $attempt/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done

    if [ $attempt -gt $max_attempts ]; then
        echo "❌ Error: PostgreSQL failed to start within expected time"
        echo "Check Docker Desktop and container logs for issues"
        exit 1
    fi
else
    echo "✅ PostgreSQL container is already running"
fi

# Run Flyway migrations
echo "🔄 Running database migrations..."
./mvnw flyway:migrate -q   -Dflyway.url=jdbc:postgresql://localhost:5432/careconnect \
                           -Dflyway.user=postgres \
                           -Dflyway.password=changeme || {
    echo "⚠️  Warning: Flyway migrations failed. Continuing with application startup..."
    echo "You may need to run migrations manually later."
}

echo "----------------------------------------"
echo "📋 Development Configuration:"
echo "- Platform: macOS"
echo "- Database: PostgreSQL (Docker)"
echo "- Profile: dev"
echo "- API Keys: Mocked"
echo "- Email: Console logging"
echo "- File Storage: Local"
echo "- Docker: Docker Desktop"
echo "----------------------------------------"

echo "🌟 Starting Spring Boot application..."
export SPRING_PROFILES_ACTIVE=dev

# Use Maven wrapper with macOS-specific JVM options if needed
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev

# Wait a few seconds for the backend to start up
sleep 6

# Automatically open Swagger UI in Chrome
open -a "Google Chrome" http://localhost:8080/swagger-ui/index.html

# Wait a few seconds for the backend to start up
sleep 6

# Automatically open Swagger UI in Chrome
open -a "Google Chrome" http://localhost:8080/swagger-ui/index.html

echo "🛑 Application stopped."
