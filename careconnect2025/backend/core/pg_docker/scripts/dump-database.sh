#!/bin/bash
# ================================
# CareConnect Database Dump Script
# ================================

set -e

echo "Creating CareConnect Database Dump..."
echo "===================================="

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/../backups"

# Create backups directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Generate timestamp for backup filename
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="careconnect_backup_$TIMESTAMP.sql"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILE"

# Check if PostgreSQL is running
if ! docker ps --format "table {{.Names}}" | grep -q "postgres_container"; then
    echo "Error: PostgreSQL container is not running."
    echo "Please start it first with: cd pg_docker && docker-compose up -d postgres"
    exit 1
fi

echo "Creating database dump: $BACKUP_FILE"

# Create the database dump
docker exec postgres_container pg_dump \
    -U postgres \
    -d careconnect \
    --no-password \
    --verbose \
    --clean \
    --if-exists \
    --create \
    --format=plain > "$BACKUP_PATH"

if [ $? -eq 0 ]; then
    echo "Database dump created successfully: $BACKUP_PATH"
    echo "File size: $(du -h "$BACKUP_PATH" | cut -f1)"

    # Create a latest symlink
    ln -sf "$BACKUP_FILE" "$BACKUP_DIR/latest.sql"
    echo "Latest backup symlink updated: $BACKUP_DIR/latest.sql"
else
    echo "Error: Database dump failed"
    exit 1
fi

echo ""
echo "To restore this backup later:"
echo "  docker exec -i postgres_container psql -U postgres < \"$BACKUP_PATH\""