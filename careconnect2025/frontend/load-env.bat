@echo off
setlocal enabledelayedexpansion
REM ================================
REM CareConnect Frontend Environment Loader (Windows)
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

REM Verify critical variables are set
set "missing_vars="
if "%CC_BASE_URL_WEB%"=="" set "missing_vars=%missing_vars% CC_BASE_URL_WEB"
if "%CC_BASE_URL_ANDROID%"=="" set "missing_vars=%missing_vars% CC_BASE_URL_ANDROID"
if "%CC_BASE_URL_OTHER%"=="" set "missing_vars=%missing_vars% CC_BASE_URL_OTHER"

if not "%missing_vars%"=="" (
    echo Warning: The following critical environment variables are not set:
    echo %missing_vars%
    echo Please update your .env file with the required values
    echo Please set the missing environment variables before starting the application
    exit /b 1
)

echo Starting CareConnect Backend...
REM Execute the passed command with loaded environment
%*
