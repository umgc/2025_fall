@echo off
REM ================================
REM CareConnect Database Dump Script
REM ================================

setlocal enabledelayedexpansion

echo Creating CareConnect Database Dump...
echo ====================================

REM Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"
set "BACKUP_DIR=%SCRIPT_DIR%..\backups"

REM Create backups directory if it doesn't exist
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

REM Generate timestamp for backup filename
for /f "tokens=1-4 delims=/ " %%a in ('date /t') do set mydate=%%d%%b%%c
for /f "tokens=1-2 delims=: " %%a in ('time /t') do set mytime=%%a%%b
set "mytime=%mytime::=%"
set "mytime=%mytime: =%"
set "TIMESTAMP=%mydate%_%mytime%"
set "BACKUP_FILE=careconnect_backup_%TIMESTAMP%.sql"
set "BACKUP_PATH=%BACKUP_DIR%\%BACKUP_FILE%"

REM Check if PostgreSQL is running
docker ps --format "table {{.Names}}" | findstr "postgres_container" >nul
if %errorlevel% neq 0 (
    echo Error: PostgreSQL container is not running.
    echo Please start it first with: cd pg_docker ^&^& docker-compose up -d postgres
    exit /b 1
)

echo Creating database dump: %BACKUP_FILE%

REM Create the database dump
docker exec postgres_container pg_dump -U postgres -d careconnect --no-password --verbose --clean --if-exists --create --format=plain > "%BACKUP_PATH%"

if %errorlevel% equ 0 (
    echo Database dump created successfully: %BACKUP_PATH%
    for %%i in ("%BACKUP_PATH%") do echo File size: %%~zi bytes

    REM Create a latest copy (Windows doesn't have symlinks easily available)
    copy "%BACKUP_PATH%" "%BACKUP_DIR%\latest.sql" >nul
    echo Latest backup copy updated: %BACKUP_DIR%\latest.sql
) else (
    echo Error: Database dump failed
    exit /b 1
)

echo.
echo To restore this backup later:
echo   docker exec -i postgres_container psql -U postgres ^< "%BACKUP_PATH%"

endlocal