REM THIS IS UNTESTED.

@echo off
setlocal enabledelayedexpansion
REM ================================
REM CareConnect Backend Development Startup Script - Windows
REM ================================

echo 🪟 CareConnect Backend - Windows Development Setup
echo Loading environment variables...

REM Check if .env file exists
if not exist ".env" (
    echo ❌ Error: .env file not found in current directory
    echo Please create a .env file based on the provided template
    pause
    exit /b 1
)

REM Load environment variables from .env file
for /f "usebackq tokens=1* delims==" %%a in (".env") do (
    set "line=%%a"
    if not "!line!"=="" (
        if not "!line:~0,1!"=="#" (
            set "%%a=%%b"
        )
    )
)

echo ✅ Environment variables loaded successfully!
echo Database: %JDBC_URI%

REM Verify critical variables are set
set "missing_vars="
if "%JDBC_URI%"=="" set "missing_vars=%missing_vars% JDBC_URI"
if "%DB_USER%"=="" set "missing_vars=%missing_vars% DB_USER"
if "%DB_PASSWORD%"=="" set "missing_vars=%missing_vars% DB_PASSWORD"
if "%SECURITY_JWT_SECRET%"=="" set "missing_vars=%missing_vars% SECURITY_JWT_SECRET"
if "%FIREBASE_PROJECT_ID%"=="" set "missing_vars=%missing_vars% FIREBASE_PROJECT_ID"
if "%FIREBASE_SENDER_ID%"=="" set "missing_vars=%missing_vars% FIREBASE_SENDER_ID"

if not "%missing_vars%"=="" (
    echo ⚠️  Warning: The following critical environment variables are not set:
    echo %missing_vars%
    echo Please update your .env file with the required values
)

echo 🚀 Starting CareConnect Backend in Development Mode...
echo ==========================================

REM Check if Docker Desktop is running (Windows specific)
docker info >nul 2>&1
if errorlevel 1 (
    echo ❌ Error: Docker Desktop is not running.
    echo Please start Docker Desktop from the Start Menu or Desktop
    set /p "choice=Would you like to try starting Docker Desktop? (y/n): "
    if /i "!choice!"=="y" (
        echo Starting Docker Desktop...
        start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
        echo Waiting for Docker Desktop to start...
        timeout /t 20 /nobreak >nul
        REM Retry docker info
        docker info >nul 2>&1
        if errorlevel 1 (
            echo ❌ Docker Desktop is still not ready. Please start it manually and try again.
            pause
            exit /b 1
        )
    ) else (
        exit /b 1
    )
)

REM Check if PostgreSQL container is running
echo 🐘 Checking PostgreSQL Docker container...
docker ps --format "table {{.Names}}" | findstr "postgres_container" >nul
if errorlevel 1 (
    echo PostgreSQL container not running. Starting it now...

    REM Check if docker-compose.yml exists
    if not exist "pg_docker\docker-compose.yml" (
        echo ❌ Error: pg_docker\docker-compose.yml not found
        echo Please ensure the PostgreSQL Docker setup is in place
        pause
        exit /b 1
    )

    REM Start PostgreSQL container
    echo Starting PostgreSQL with Docker Compose...
    pushd pg_docker
    docker-compose up -d postgres
    popd

    echo ⏳ Waiting for PostgreSQL to be ready...
    timeout /t 10 /nobreak >nul

    REM Test PostgreSQL connection
    set "max_attempts=30"
    set "attempt=1"
    :wait_loop
    docker exec postgres_container pg_isready -U postgres >nul 2>&1
    if not errorlevel 1 (
        echo ✅ PostgreSQL is ready!
        goto :postgres_ready
    )
    echo ⏳ Waiting for PostgreSQL... (attempt !attempt!/!max_attempts!)
    timeout /t 2 /nobreak >nul
    set /a attempt+=1
    if !attempt! leq !max_attempts! goto :wait_loop

    echo ❌ Error: PostgreSQL failed to start within expected time
    echo Check Docker Desktop and container logs for issues
    pause
    exit /b 1
) else (
    echo ✅ PostgreSQL container is already running
)

:postgres_ready
REM Run Flyway migrations
echo 🔄 Running database migrations...
call mvnw.cmd flyway:migrate -q -Dflyway.url=jdbc:postgresql://localhost:5432/careconnect -Dflyway.user=postgres -Dflyway.password=changeme
if errorlevel 1 (
    echo ⚠️  Warning: Flyway migrations failed. Continuing with application startup...
    echo You may need to run migrations manually later.
)

echo ----------------------------------------
echo 📋 Development Configuration:
echo - Platform: Windows
echo - Database: PostgreSQL (Docker)
echo - Profile: dev
echo - API Keys: Mocked
echo - Email: Console logging
echo - File Storage: Local
echo - Docker: Docker Desktop
echo ----------------------------------------

echo 🌟 Starting Spring Boot application...
set SPRING_PROFILES_ACTIVE=dev

@REM The following lines are used to build a temporary forward-facing url
@REM for Alexa skill to call. Should be replaced when we have a constant domain avaliable
echo Setting Port
set "APP_PORT=8080"
echo Calling ngrok script
call scripts\start_ngrok.bat %APP_PORT%
if exist ".public_url" (
  set /p NGURL=<".public_url"
  echo ✅ Public URL: %NGURL%
)

REM Use Maven wrapper for Windows
call mvnw.cmd spring-boot:run -Dspring.profiles.active=dev


REM when the app stops, kill ngrok
call scripts\stop_ngrok.bat
echo 🛑 Application stopped.
pause


