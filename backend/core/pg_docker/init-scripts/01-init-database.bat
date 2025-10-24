@echo off
REM Database initialization script for CareConnect
echo Initializing CareConnect database...

REM Create extensions using psql
psql -v ON_ERROR_STOP=1 --username %POSTGRES_USER% --dbname %POSTGRES_DB% -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"; CREATE EXTENSION IF NOT EXISTS \"vector\";"

echo Database initialization completed. Ready for JPA migrations.