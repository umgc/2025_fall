#!/bin/bash
set -e

# Database initialization script for CareConnect
echo "Initializing CareConnect database..."

# Create the careconnect database if it doesn't exist
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create extensions if needed
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS "vector";

    -- Migrations will be applied by the Spring Boot application
EOSQL

echo "Database initialization completed. Ready for Flyway migrations."