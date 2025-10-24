@echo off
setlocal enabledelayedexpansion
REM ================================
REM CareConnect Backend Environment Loader (Windows)
REM ================================

echo Loading CareConnect environment variables...

REM Check if .env file exists
if not exist ".env" (
    echo Error: .env file not found in current directory
    echo Please create a .env file based on the provided template
    exit /b 1
)

REM Load environment variables from .env file
for /f "usebackq tokens=1* delims==" %%a in (".env") do (
    set "line=%%a"
    if not "!line!"=="" (
        if not "!line:~0,1!"=="#" (
            set "%%a=%%b"
            echo Loaded: %%a
        )
    )
)

echo Environment variables loaded successfully!
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
    echo Warning: The following critical environment variables are not set:
    echo %missing_vars%
    echo Please update your .env file with the required values
    echo Please set the missing environment variables before starting the application
    exit /b 1
)

REM Check optional environment variables and report which ones are using defaults
echo.
echo Optional environment variables (not set, using defaults from application-dev.properties):
set "unset_count=0"

if "%STRIPE_SECRET_KEY%"=="" (
    echo   - STRIPE_SECRET_KEY
    set /a unset_count+=1
)
if "%DEEPSEEK_API_KEY%"=="" (
    echo   - DEEPSEEK_API_KEY
    set /a unset_count+=1
)
if "%OPENAI_API_KEY%"=="" (
    echo   - OPENAI_API_KEY
    set /a unset_count+=1
)
if "%AWS_ACCESS_KEY_ID%"=="" (
    echo   - AWS_ACCESS_KEY_ID
    set /a unset_count+=1
)
if "%AWS_SECRET_ACCESS_KEY%"=="" (
    echo   - AWS_SECRET_ACCESS_KEY
    set /a unset_count+=1
)
if "%S3_BUCKET_NAME%"=="" (
    echo   - S3_BUCKET_NAME
    set /a unset_count+=1
)
if "%FITBIT_AUTHORIZATION_URI%"=="" (
    echo   - FITBIT_AUTHORIZATION_URI
    set /a unset_count+=1
)
if "%FITBIT_TOKEN_URI%"=="" (
    echo   - FITBIT_TOKEN_URI
    set /a unset_count+=1
)
if "%FITBIT_USERINFO_URI%"=="" (
    echo   - FITBIT_USERINFO_URI
    set /a unset_count+=1
)
if "%STRIPE_API_URL%"=="" (
    echo   - STRIPE_API_URL
    set /a unset_count+=1
)

if %unset_count%==0 (
    echo   (All optional variables are set)
)
echo.

echo Starting CareConnect Backend...
REM Execute the passed command with loaded environment
%*
