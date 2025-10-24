@echo off
REM ================================
REM CareConnect Database Migration Script (JPA)
REM ================================

setlocal enabledelayedexpansion

echo CareConnect Database Migration (JPA-based)...
echo =============================================

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

REM JPA will handle schema creation automatically
echo JPA will handle database schema creation automatically when the application starts.
echo No manual migrations needed - schema is managed by JPA/Hibernate.

echo.
echo Database is ready for JPA schema creation!
echo Start your Spring Boot application to auto-create the schema:
echo   mvnw.cmd spring-boot:run -Dspring.profiles.active=dev

endlocal