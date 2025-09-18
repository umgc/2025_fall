@echo off
REM ================================
REM CareConnect Flyway Migration Script
REM ================================

setlocal enabledelayedexpansion

echo Running CareConnect Flyway Migrations...
echo =======================================

REM Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%..\.."

cd /d "%PROJECT_ROOT%"

REM Check if PostgreSQL is running
docker ps --format "table {{.Names}}" | findstr "postgres_container" >nul
if %errorlevel% neq 0 (
    echo Error: PostgreSQL container is not running.
    echo Please start it first with: cd pg_docker ^&^& docker-compose up -d postgres
    exit /b 1
)

REM Wait for PostgreSQL to be ready
echo Checking PostgreSQL connectivity...
set timeout=30
set counter=0

:wait_loop
docker exec postgres_container pg_isready -U postgres -d careconnect >nul 2>&1
if %errorlevel% equ 0 goto postgres_ready

timeout /t 2 /nobreak >nul
set /a counter+=2
if %counter% geq %timeout% (
    echo Error: PostgreSQL is not ready after %timeout% seconds
    exit /b 1
)
goto wait_loop

:postgres_ready
echo PostgreSQL is ready!

REM Run Flyway migrations
echo Running Flyway migrations...
mvnw.cmd flyway:migrate -Dflyway.url=jdbc:postgresql://localhost:5432/careconnect -Dflyway.user=postgres -Dflyway.password=changeme -Dflyway.locations=filesystem:src/main/resources/db/migration

echo.
echo Migrations completed successfully!
echo You can now run your Spring Boot application:
echo   mvnw.cmd spring-boot:run -Dspring.profiles.active=dev

endlocal