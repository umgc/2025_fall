@echo off
ECHO =======================================
ECHO  Building Spring Boot ZIP For Aws Lambda (skipping tests)
ECHO =======================================

REM Run Maven clean and package commands, skipping tests
call mvnw.cmd clean package -DskipTests

REM Check if the build was successful
IF %ERRORLEVEL% NEQ 0 (
    ECHO.
    ECHO ********************
    ECHO * BUILD FAILED   *
    ECHO ********************
    GOTO END
)

ECHO.
ECHO ************************
ECHO * BUILD SUCCESSFUL   *
ECHO ************************
ECHO Your ZIP file is located in the 'target' directory.

:END
ECHO.
PAUSE