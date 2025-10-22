@echo off
setlocal enabledelayedexpansion

REM Parse command-line arguments
set "DESTROY_MODE=false"
for %%A in (%*) do (
    if "%%A"=="--destroy" set "DESTROY_MODE=true"
)

REM Script directory
set "SCRIPT_DIR=%~dp0"
for %%A in ("%SCRIPT_DIR:~0,-1%") do set "PROJECT_ROOT=%%~dpA"
set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"

echo.
echo ==================================================
echo CareConnect Terraform Deployment Script
echo ==================================================
echo.

REM Check prerequisites
echo Checking prerequisites...

where terraform >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Terraform is not installed or not in PATH
    echo [INFO] Install Terraform from: https://www.terraform.io/downloads
    pause
    exit /b 1
) else (
    echo [SUCCESS] Terraform is installed
)

where aws >nul 2>&1
if errorlevel 1 (
    echo [WARNING] AWS CLI is not installed or not in PATH
    echo [INFO] Install AWS CLI from: https://aws.amazon.com/cli/
) else (
    echo [SUCCESS] AWS CLI is installed
)

aws sts get-caller-identity >nul 2>&1
if errorlevel 1 (
    echo [WARNING] AWS credentials not configured or invalid
    echo [INFO] Configure AWS credentials using: aws configure
) else (
    echo [SUCCESS] AWS credentials configured
)

where mvn >nul 2>&1
if errorlevel 1 (
    echo [WARNING] Maven is not installed or not in PATH
) else (
    echo [SUCCESS] Maven is installed
)

where flutter >nul 2>&1
if errorlevel 1 (
    echo [WARNING] Flutter is not installed or not in PATH
) else (
    echo [SUCCESS] Flutter is installed
)

echo.

REM Check if all folders exist
echo Checking Terraform folders...
if not exist "%SCRIPT_DIR%\1_s3_tfstate" (
    echo [ERROR] Folder 1_s3_tfstate does not exist!
    pause
    exit /b 1
)
if not exist "%SCRIPT_DIR%\2_general" (
    echo [ERROR] Folder 2_general does not exist!
    pause
    exit /b 1
)
if not exist "%SCRIPT_DIR%\3_database" (
    echo [ERROR] Folder 3_database does not exist!
    pause
    exit /b 1
)
if not exist "%SCRIPT_DIR%\4_compute" (
    echo [ERROR] Folder 4_compute does not exist!
    pause
    exit /b 1
)
echo [SUCCESS] All Terraform folders found
echo.

REM Destroy mode
if "%DESTROY_MODE%"=="true" (
    echo.
    echo ==================================================
    echo DESTROY MODE ENABLED
    echo This will destroy all Terraform resources!
    echo ==================================================
    echo.
    
    set /p "REPLY=Are you sure you want to destroy all resources? [y/N]: "
    
    if /i not "%REPLY%"=="y" (
        echo [WARNING] Destroy cancelled.
        pause
        exit /b 0
    )
    
    echo [INFO] Starting Terraform destroy in reverse order...
    echo.
    
    echo [INFO] Destroying 4_compute...
    cd /d "%SCRIPT_DIR%\4_compute"
    terraform init
    terraform destroy -auto-approve
    
    echo [INFO] Destroying 3_database...
    cd /d "%SCRIPT_DIR%\3_database"
    terraform init
    terraform destroy -auto-approve
    
    echo [INFO] Destroying 2_general...
    cd /d "%SCRIPT_DIR%\2_general"
    terraform init
    terraform destroy -auto-approve
    
    echo [INFO] Destroying 1_s3_tfstate...
    cd /d "%SCRIPT_DIR%\1_s3_tfstate"
    terraform init
    terraform destroy -auto-approve
    
    echo.
    echo ==================================================
    echo [SUCCESS] All Terraform resources destroyed!
    echo ==================================================
    pause
    exit /b 0
)

REM Ask if user wants to build projects
set /p "REPLY=Do you want to build the backend and frontend? [Y/n]: "

if /i not "%REPLY%"=="n" (
    echo.
    echo ==================================================
    echo Building Backend
    echo ==================================================
    
    set "backend_dir=%PROJECT_ROOT%\backend\core"
    
    if not exist "!backend_dir!" (
        echo [ERROR] Backend directory not found: !backend_dir!
        pause
        exit /b 1
    )
    
    cd /d "!backend_dir!"
    echo [INFO] Running Maven clean and package...
    call mvn clean package -Passembly-zip -Dspring.profiles.active=dev -DskipTests
    
    if errorlevel 1 (
        echo [ERROR] Backend build failed!
        pause
        exit /b 1
    )
    echo [SUCCESS] Backend build completed!
    echo.
    
    echo ==================================================
    echo Building Frontend
    echo ==================================================
    
    set "frontend_dir=%PROJECT_ROOT%\frontend"
    
    if not exist "!frontend_dir!" (
        echo [ERROR] Frontend directory not found: !frontend_dir!
        pause
        exit /b 1
    )
    
    cd /d "!frontend_dir!"
    echo [INFO] Running Flutter pub get...
    call flutter pub get
    
    echo [INFO] Building Flutter web app...
    call flutter build web --release
    
    if errorlevel 1 (
        echo [ERROR] Frontend build failed!
        pause
        exit /b 1
    )
    echo [SUCCESS] Frontend build completed!
    echo.
) else (
    echo [WARNING] Skipping build step
    echo.
)

REM Ask if user wants to proceed with Terraform deployment
set /p "REPLY=Do you want to proceed with Terraform deployment? [Y/n]: "

if /i "%REPLY%"=="n" (
    echo [WARNING] Deployment cancelled.
    pause
    exit /b 0
)

echo.

REM Collect SSM parameters
echo ==================================================
echo Collecting SSM Parameters
echo ==================================================
echo.

set "continue_adding=y"
set "param_count=0"

:ssm_loop
if /i "!continue_adding!"=="y" (
    echo.
    set /p param_key="Enter parameter key (or press Enter to skip): "
    
    if "!param_key!"=="" (
        goto ssm_done
    )
    
    set /p "param_value=Enter parameter value: "
    
    if "!param_value!"=="" (
        echo [WARNING] Value cannot be empty. Skipping...
        set /p continue_adding="Add another parameter? [y/N]: "
        goto ssm_loop
    )
    
    set "SSM_PARAM_!param_count!=!param_key!^=!param_value!"
    set /a param_count+=1
    echo [SUCCESS] Added parameter: !param_key!
    
    set /p continue_adding="Add another parameter? [y/N]: "
    goto ssm_loop
)

:ssm_done
if !param_count! gtr 0 (
    echo [SUCCESS] SSM parameters configured: !param_count! parameter(s)
) else (
    echo [WARNING] No SSM parameters added
)
echo.

REM Deploy Terraform in order
echo ==================================================
echo Starting Terraform Deployment
echo ==================================================
echo.

REM 1_s3_tfstate
echo [INFO] Deploying 1_s3_tfstate...
cd /d "%SCRIPT_DIR%\1_s3_tfstate"
terraform init
terraform plan -out=tfplan
terraform apply tfplan

if errorlevel 1 (
    echo [ERROR] Terraform deployment failed for 1_s3_tfstate
    pause
    exit /b 1
)

for /f "delims=" %%I in ('terraform output -raw backend_bucket_name 2^>nul') do set "TF_BACKEND_BUCKET=%%I"
echo [SUCCESS] Backend S3 bucket: !TF_BACKEND_BUCKET!
echo.

REM 2_general
echo [INFO] Deploying 2_general...
cd /d "%SCRIPT_DIR%\2_general"
terraform init -backend-config="bucket=!TF_BACKEND_BUCKET!"
terraform plan -out=tfplan
terraform apply tfplan

if errorlevel 1 (
    echo [ERROR] Terraform deployment failed for 2_general
    pause
    exit /b 1
)

for /f "delims=" %%I in ('terraform output -raw main_api_endpoint 2^>nul') do set "main_api=%%I"
for /f "delims=" %%I in ('terraform output -raw amplify_url 2^>nul') do set "amplify_url=%%I"

echo [SUCCESS] API Endpoint: !main_api!
echo [SUCCESS] Amplify URL: https://!amplify_url!
echo.

REM 3_database
echo [INFO] Deploying 3_database...
cd /d "%SCRIPT_DIR%\3_database"
terraform init -backend-config="bucket=!TF_BACKEND_BUCKET!"
terraform plan -out=tfplan
terraform apply tfplan

if errorlevel 1 (
    echo [ERROR] Terraform deployment failed for 3_database
    pause
    exit /b 1
)

for /f "delims=" %%I in ('terraform output -raw db_endpoint 2^>nul') do set "db_endpoint=%%I"
for /f "delims=" %%I in ('terraform output -raw db_port 2^>nul') do set "db_port=%%I"

echo [SUCCESS] Database Endpoint: !db_endpoint!:!db_port!
echo.

REM 4_compute
echo [INFO] Deploying 4_compute...
cd /d "%SCRIPT_DIR%\4_compute"
terraform init -backend-config="bucket=!TF_BACKEND_BUCKET!"
terraform plan -out=tfplan
terraform apply tfplan

if errorlevel 1 (
    echo [ERROR] Terraform deployment failed for 4_compute
    pause
    exit /b 1
)

for /f "delims=" %%I in ('terraform output -raw cc_main_backend_lambda_function_name 2^>nul') do set "lambda_name=%%I"
for /f "delims=" %%I in ('terraform output -raw websocket_api_endpoint 2^>nul') do set "ws_endpoint=%%I"

echo [SUCCESS] Lambda Function: !lambda_name!
echo [SUCCESS] WebSocket Endpoint: !ws_endpoint!
echo.

REM Final summary
echo.
echo ==================================================
echo DEPLOYMENT SUMMARY - IMPORTANT ENDPOINTS
echo ==================================================
echo.
echo REST API: !main_api!
echo.
echo Frontend (Amplify): https://!amplify_url!
echo.
echo Database: !db_endpoint!:!db_port!
echo.
echo Lambda Function: !lambda_name!
echo.
echo WebSocket Endpoint: !ws_endpoint!
echo.
echo ==================================================
echo [SUCCESS] All Terraform deployments completed!
echo ==================================================
echo.

pause
exit /b 0