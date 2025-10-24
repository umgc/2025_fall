@echo off
REM ================================
REM CareConnect Database Reset Script
REM ================================

setlocal enabledelayedexpansion

echo Resetting CareConnect PostgreSQL Database...
echo ===========================================

REM Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"
set "DOCKER_COMPOSE_DIR=%SCRIPT_DIR%.."

cd /d "%DOCKER_COMPOSE_DIR%"

REM Stop and remove containers
echo Stopping PostgreSQL containers...
docker compose down

REM Remove the PostgreSQL volume to completely reset the database
echo Removing PostgreSQL data volume...
docker volume rm pg_docker_postgres 2>nul || echo Volume already removed or doesn't exist

REM Start PostgreSQL again (this will recreate the database)
echo Starting fresh PostgreSQL container...
docker compose up -d postgres

REM Wait for PostgreSQL to be ready
echo Waiting for PostgreSQL to be ready...
set timeout=60
set counter=0

:wait_loop
docker exec postgres_container pg_isready -U postgres -d careconnect >nul 2>&1
if %errorlevel% equ 0 goto postgres_ready

timeout /t 2 /nobreak >nul
set /a counter+=2
if %counter% geq %timeout% (
    echo Error: PostgreSQL failed to start within %timeout% seconds
    exit /b 1
)
goto wait_loop

:postgres_ready
echo PostgreSQL is ready!
echo.
echo Database has been reset successfully!
echo You can now run your Spring Boot application with the dev profile:
echo   mvnw.cmd spring-boot:run -Dspring.profiles.active=dev
echo.
echo JPA will auto-create schema when application starts:
echo   mvnw.cmd spring-boot:run -Dspring.profiles.active=dev
echo.
echo PgAdmin is available at: http://localhost:5050
echo   Email: pgadmin4@pgadmin.org
echo   Password: admin

endlocal