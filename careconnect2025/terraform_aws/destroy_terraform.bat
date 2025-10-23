@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION

REM ##########################################################################
REM # Script Configuration
REM ##########################################################################

REM --- Define the folders in the order they should be DESTROYED (reverse of creation) ---
SET "FOLDERS_DESTROY_ORDER=4_compute 3_database 2_general 1_s3_tfstate"

REM ##########################################################################
REM # Script Setup
REM ##########################################################################

REM --- Get the directory where this script is located ---
SET "SCRIPT_DIR=%~dp0"
REM --- Remove trailing backslash if it exists ---
IF "%SCRIPT_DIR:~-1%"=="\" SET "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

REM --- Jump over subroutines to the main execution block ---
GOTO :main

REM ##########################################################################
REM # Subroutines (Functions)
REM ##########################################################################

:print_info
    ECHO [INFO] %*
    GOTO :EOF

:print_success
    ECHO [SUCCESS] %*
    GOTO :EOF

:print_warning
    ECHO [WARNING] %*
    GOTO :EOF

:print_error
    ECHO [ERROR] %*
    GOTO :EOF

:check_fail
    REM --- Checks the ERRORLEVEL of the previous command and exits if it's not 0 ---
    IF %ERRORLEVEL% NEQ 0 (
        CALL :print_error "%~1"
        CALL :print_error "Exiting due to a critical error."
        POPD 2>NUL
        EXIT /B 1
    )
    GOTO :EOF

:destroy_in_folder
    SETLOCAL
    SET "folder_dir=%~1"
    SET "folder_name=%~2"

    CALL :print_info "=================================================="
    CALL :print_info "Destroying Terraform resources in: %folder_name%"
    CALL :print_info "=================================================="

    IF NOT EXIST "%folder_dir%\" (
        CALL :print_warning "Directory not found: %folder_dir%. Skipping."
        ENDLOCAL
        GOTO :EOF
    )

    PUSHD "%folder_dir%"

    REM --- Initialize Terraform. This is required before destroy. ---
    REM --- For all modules EXCEPT 1_s3_tfstate, we must configure the S3 backend. ---
    IF /I "%folder_name%" == "1_s3_tfstate" (
        CALL :print_info "Initializing Terraform..."
        terraform init -upgrade
    ) ELSE (
        IF DEFINED TF_BACKEND_BUCKET (
            CALL :print_info "Initializing Terraform with S3 backend bucket: %TF_BACKEND_BUCKET%"
            terraform init -upgrade -backend-config="bucket=%TF_BACKEND_BUCKET%"
        ) ELSE (
            CALL :print_error "S3 backend bucket name is not set. Cannot destroy %folder_name%."
            CALL :print_error "Make sure '1_s3_tfstate' has not been destroyed yet."
            POPD
            ENDLOCAL
            EXIT /B 1
        )
    )
    CALL :check_fail "Terraform init failed for %folder_name%."

    REM --- Run the destroy command with auto-approve ---
    CALL :print_warning "Running 'terraform destroy'..."
    terraform destroy -auto-approve

    IF %ERRORLEVEL% EQU 0 (
        CALL :print_success "Terraform destroy completed for %folder_name%."
    ) ELSE (
        CALL :print_error "Terraform destroy FAILED for %folder_name%."
        CALL :print_error "Check the output above for the specific Terraform error."
        POPD
        ENDLOCAL
        EXIT /B 1
    )

    POPD
    ENDLOCAL
    GOTO :EOF

REM ##########################################################################
REM # Main Execution
REM ##########################################################################
:main
    CALL :print_warning "=============================================================="
    CALL :print_warning "           !!! DANGER: RESOURCE DESTRUCTION SCRIPT !!!"
    CALL :print_warning "=============================================================="
    ECHO.
    CALL :print_warning "This script will PERMANENTLY DESTROY all cloud infrastructure"
    CALL :print_warning "managed by Terraform in the following folders:"
    CALL :print_info "%FOLDERS_DESTROY_ORDER%"
    ECHO.
    CALL :print_warning "This action is irreversible."
    ECHO.

    SET "CONFIRM="
    SET /P "CONFIRM=To proceed, type 'yes' and press Enter: "

    IF /I NOT "%CONFIRM%" == "yes" (
        CALL :print_error "Confirmation not received. Aborting script."
        ECHO.
        EXIT /B 1
    )
    ECHO.
    CALL :print_info "Confirmation received. Starting destruction process..."
    ECHO.

    REM --- First, get the S3 backend bucket name from the state file module ---
    CALL :print_info "Retrieving S3 backend bucket name from '1_s3_tfstate'..."
    SET "TF_STATE_DIR=%SCRIPT_DIR%\1_s3_tfstate"

    IF NOT EXIST "%TF_STATE_DIR%\" (
        CALL :print_warning "Could not find folder '1_s3_tfstate'."
        CALL :print_warning "Assuming resources are already destroyed or using local state."
    ) ELSE (
        PUSHD "%TF_STATE_DIR%"
        FOR /F "delims=" %%i IN ('terraform output -raw backend_bucket_name 2^>NUL') DO SET "TF_BACKEND_BUCKET=%%i"
        POPD
    )

    IF DEFINED TF_BACKEND_BUCKET (
        CALL :print_success "Found backend bucket: %TF_BACKEND_BUCKET%"
    ) ELSE (
        CALL :print_warning "Could not find backend bucket name. This might be okay if it's already destroyed."
    )
    ECHO.

    REM --- Loop through the folders and call the destroy subroutine for each ---
    FOR %%f IN (%FOLDERS_DESTROY_ORDER%) DO (
        CALL :destroy_in_folder "%SCRIPT_DIR%\%%f" "%%f"
        IF %ERRORLEVEL% NEQ 0 (
            CALL :print_error "Script stopped due to a failure in folder '%%f'."
            GOTO :end
        )
        ECHO.
    )

    CALL :print_success "=============================================================="
    CALL :print_success "          All Terraform resources destroyed successfully."
    CALL :print_success "=============================================================="
    ECHO.

:end
    CALL :print_info "Script finished."
    PAUSE
