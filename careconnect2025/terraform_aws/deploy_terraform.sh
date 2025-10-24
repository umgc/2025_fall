#!/bin/bash

set -e  # Exit on any error

# Parse command-line arguments
DESTROY_MODE=false
for arg in "$@"; do
    if [ "$arg" = "--destroy" ]; then
        DESTROY_MODE=true
    fi
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to build backend
build_backend() {
    print_info "=================================================="
    print_info "Building Backend (Spring Boot with dev profile)"
    print_info "=================================================="

    local backend_dir="$PROJECT_ROOT/backend/core"

    if [ ! -d "$backend_dir" ]; then
        print_error "Backend directory not found: $backend_dir"
        exit 1
    fi

    cd "$backend_dir"

    print_info "Running Maven clean and package with assembly-zip profile..."
    mvn clean package -Passembly-zip -Dspring.profiles.active=dev -DskipTests

    if [ $? -eq 0 ]; then
        print_success "Backend build completed successfully!"

        # Check if build artifact exists
        if [ -f "target/careconnect-backend-0.0.1-SNAPSHOT-bin.zip" ]; then
            print_info "Build artifact: target/careconnect-backend-0.0.1-SNAPSHOT-bin.zip"
        else
            print_warning "Expected build artifact not found. Check target directory."
            ls -lh target/*.zip 2>/dev/null || print_warning "No zip files found in target directory"
        fi
    else
        print_error "Backend build failed!"
        exit 1
    fi

    cd "$SCRIPT_DIR"
}

# Function to build frontend
build_frontend() {
    print_info "=================================================="
    print_info "Building Frontend (Flutter for Web)"
    print_info "=================================================="

    local frontend_dir="$PROJECT_ROOT/frontend"

    if [ ! -d "$frontend_dir" ]; then
        print_error "Frontend directory not found: $frontend_dir"
        exit 1
    fi

    cd "$frontend_dir"

    # Check if Flutter is installed
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        exit 1
    fi

    print_info "Running Flutter pub get..."
    flutter pub get

    print_info "Building Flutter web app..."
    flutter build web --release

    if [ $? -eq 0 ]; then
        print_success "Frontend build completed successfully!"
        print_info "Build output: build/web/"
    else
        print_error "Frontend build failed!"
        exit 1
    fi

    cd "$SCRIPT_DIR"
}

# Function to print terraform outputs after deployment
print_outputs() {
    local folder_name="$1"

    echo ""
    print_info "--------------------------------------------------"
    print_info "Key Outputs from $folder_name:"
    print_info "--------------------------------------------------"

    case "$folder_name" in
        "2_general")
            # Output key information from 2_general
            local main_api_endpoint=$(terraform output -raw main_api_endpoint 2>/dev/null)
            local amplify_url=$(terraform output -raw amplify_url 2>/dev/null)

            if [ -n "$main_api_endpoint" ]; then
                print_success "Main API Endpoint: $main_api_endpoint"
            fi

            if [ -n "$amplify_url" ]; then
                print_success "Amplify URL: https://$amplify_url"
            fi
            ;;

        "3_database")
            # Output database information
            local db_endpoint=$(terraform output -raw db_endpoint 2>/dev/null)
            local db_port=$(terraform output -raw db_port 2>/dev/null)

            if [ -n "$db_endpoint" ]; then
                print_success "Database Endpoint: $db_endpoint"
            fi

            if [ -n "$db_port" ]; then
                print_success "Database Port: $db_port"
            fi
            ;;

        "4_compute")
            # Output Lambda information
            local lambda_arn=$(terraform output -raw cc_main_backend_lambda_arn 2>/dev/null)
            local lambda_invoke_arn=$(terraform output -raw cc_main_backend_lambda_invoke_arn 2>/dev/null)
            local lambda_function_name=$(terraform output -raw cc_main_backend_lambda_function_name 2>/dev/null)
            local websocket_api_endpoint=$(terraform output -raw websocket_api_endpoint 2>/dev/null)
            local websocket_management_endpoint=$(terraform output -raw websocket_management_endpoint 2>/dev/null)

            if [ -n "$lambda_function_name" ]; then
                print_success "Lambda Function Name: $lambda_function_name"
            fi

            if [ -n "$lambda_arn" ]; then
                print_success "Lambda ARN: $lambda_arn"
            fi

            if [ -n "$lambda_invoke_arn" ]; then
                print_success "Lambda Invoke ARN: $lambda_invoke_arn"
                print_info "  (Used by API Gateway to invoke Lambda)"
            fi

            if [ -n "$websocket_api_endpoint" ]; then
                print_success "WebSocket Client Endpoint: $websocket_api_endpoint"
                print_info "  (Use this in Flutter frontend for WebSocket connections)"
            fi

            if [ -n "$websocket_management_endpoint" ]; then
                print_success "WebSocket Management Endpoint: $websocket_management_endpoint"
                print_info "  (Lambda uses this to send messages to WebSocket connections)"
            fi

            # Retrieve and display WebSocket endpoint from Lambda environment
            if [ -n "$lambda_function_name" ]; then
                local ws_endpoint=$(aws lambda get-function-configuration \
                    --function-name "$lambda_function_name" \
                    --query 'Environment.Variables.AWS_WEBSOCKET_API_ENDPOINT' \
                    --output text 2>/dev/null)

                if [ -n "$ws_endpoint" ] && [ "$ws_endpoint" != "None" ] && [ "$ws_endpoint" != "" ]; then
                    print_success "Lambda WebSocket Endpoint (from env): $ws_endpoint"
                fi
            fi
            ;;
    esac

    print_info "--------------------------------------------------"
    echo ""
}

# Function to collect SSM parameters
collect_ssm_params() {
    print_info "Collecting SSM parameters for 2_general..."
    declare -g -A SSM_PARAMS
    local continue_adding="y"

    while [[ $continue_adding =~ ^[Yy]$ ]]; do
        echo ""
        read -p "$(echo -e ${YELLOW}Enter parameter key:${NC} )" param_key

        if [ -z "$param_key" ]; then
            print_warning "Key cannot be empty. Skipping..."
            read -p "$(echo -e ${YELLOW}Add another parameter? [y/N]:${NC} )" continue_adding
            continue
        fi

        read -s -p "$(echo -e ${YELLOW}Enter parameter value:${NC} )" param_value
        echo ""

        if [ -z "$param_value" ]; then
            print_warning "Value cannot be empty. Skipping..."
            read -p "$(echo -e ${YELLOW}Add another parameter? [y/N]:${NC} )" continue_adding
            continue
        fi

        SSM_PARAMS["$param_key"]="$param_value"
        print_success "Added parameter: $param_key"

        read -p "$(echo -e ${YELLOW}Add another parameter? [y/N]:${NC} )" continue_adding
    done

    # Build the Terraform variable string
    if [ ${#SSM_PARAMS[@]} -gt 0 ]; then
        local ssm_var_string="{"
        local first=true
        for key in "${!SSM_PARAMS[@]}"; do
            if [ "$first" = true ]; then
                first=false
            else
                ssm_var_string+=","
            fi
            # Escape any quotes in the value
            local escaped_value="${SSM_PARAMS[$key]//\"/\\\"}"
            ssm_var_string+="\"$key\"=\"$escaped_value\""
        done
        ssm_var_string+="}"
        export TF_VAR_SSM_PARAMS="$ssm_var_string"
        print_success "SSM parameters configured: ${#SSM_PARAMS[@]} parameter(s)"
    else
        print_warning "No SSM parameters added"
        export TF_VAR_SSM_PARAMS="{}"
    fi
    echo ""
}

# Function to run terraform in a directory
run_terraform() {
    local dir="$1"
    local folder_name=$(basename "$dir")

    print_info "=================================================="
    print_info "Running Terraform in: $folder_name"
    print_info "=================================================="

    cd "$dir"

    # Build additional terraform flags
    local tf_var_flags=""

    # Add bucket name variable for all folders except 1_s3_tfstate
    if [ "$folder_name" != "1_s3_tfstate" ] && [ -n "$TF_BACKEND_BUCKET" ]; then
        tf_var_flags="-var=cc_iac_bucket_name=$TF_BACKEND_BUCKET"
    fi

    # Add SSM parameters for 2_general
    if [ "$folder_name" = "2_general" ] && [ -n "$TF_VAR_SSM_PARAMS" ]; then
        if [ -n "$tf_var_flags" ]; then
            tf_var_flags="$tf_var_flags -var=cc_ssm_params=$TF_VAR_SSM_PARAMS"
        else
            tf_var_flags="-var=cc_ssm_params=$TF_VAR_SSM_PARAMS"
        fi
        print_info "Using SSM parameters for 2_general"
    fi

    # Special handling for 1_s3_tfstate (no backend configuration needed)
    if [ "$folder_name" = "1_s3_tfstate" ]; then
        # Initialize Terraform
        print_info "Initializing Terraform..."
        terraform init

        # Validate
        print_info "Validating Terraform configuration..."
        terraform validate

        # Plan and save to file
        print_info "Planning Terraform changes..."
        terraform plan -out=tfplan $tf_var_flags

        # Apply the saved plan
        print_info "Applying Terraform configuration..."
        terraform apply tfplan

        if [ $? -eq 0 ]; then
            print_success "Terraform apply completed for $folder_name"

            # Extract the bucket name from outputs
            BACKEND_BUCKET_NAME=$(terraform output -raw backend_bucket_name 2>/dev/null)
            if [ -n "$BACKEND_BUCKET_NAME" ]; then
                print_success "Backend S3 bucket created: $BACKEND_BUCKET_NAME"
                export TF_BACKEND_BUCKET="$BACKEND_BUCKET_NAME"
            else
                print_warning "Could not retrieve backend bucket name from outputs"
            fi
        else
            print_error "Terraform apply failed for $folder_name"
            exit 1
        fi
    else
        # For all other folders, initialize with backend config if available
        if [ -n "$TF_BACKEND_BUCKET" ]; then
            print_info "Initializing Terraform with backend bucket: $TF_BACKEND_BUCKET"
            terraform init -backend-config="bucket=$TF_BACKEND_BUCKET"
        else
            print_info "Initializing Terraform..."
            terraform init
        fi

        # Validate
        print_info "Validating Terraform configuration..."
        terraform validate

        # Plan and save to file
        print_info "Planning Terraform changes..."
        terraform plan -out=tfplan $tf_var_flags

        # Apply the saved plan
        print_info "Applying Terraform configuration..."
        terraform apply tfplan

        if [ $? -eq 0 ]; then
            print_success "Terraform apply completed for $folder_name"

            # Output key information after successful deployment
            print_outputs "$folder_name"
        else
            print_error "Terraform apply failed for $folder_name"
            exit 1
        fi
    fi

    cd "$SCRIPT_DIR"
}

# Function to destroy terraform resources in a directory
destroy_terraform() {
    local dir="$1"
    local folder_name=$(basename "$dir")

    print_info "=================================================="
    print_info "Destroying Terraform resources in: $folder_name"
    print_info "=================================================="

    cd "$dir"

    # Special handling for 1_s3_tfstate (no backend configuration needed)
    if [ "$folder_name" = "1_s3_tfstate" ]; then
        # Initialize Terraform
        print_info "Initializing Terraform..."
        terraform init

        # Destroy
        print_info "Destroying Terraform resources..."
        terraform destroy

        if [ $? -eq 0 ]; then
            print_success "Terraform destroy completed for $folder_name"
        else
            print_error "Terraform destroy failed for $folder_name"
            exit 1
        fi
    else
        # For all other folders, initialize with backend config if available
        if [ -n "$TF_BACKEND_BUCKET" ]; then
            print_info "Initializing Terraform with backend bucket: $TF_BACKEND_BUCKET"
            terraform init -backend-config="bucket=$TF_BACKEND_BUCKET"
        else
            print_info "Initializing Terraform..."
            terraform init
        fi

        # Destroy
        print_info "Destroying Terraform resources..."
        terraform destroy

        if [ $? -eq 0 ]; then
            print_success "Terraform destroy completed for $folder_name"
        else
            print_error "Terraform destroy failed for $folder_name"
            exit 1
        fi
    fi

    cd "$SCRIPT_DIR"
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    local all_good=true

    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed or not in PATH"
        print_info "Install Terraform from: https://www.terraform.io/downloads"
        all_good=false
    else
        local tf_version=$(terraform version -json | grep -o '"version":"[^"]*' | cut -d'"' -f4)
        print_success "Terraform installed: version $tf_version"
    fi

    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_warning "AWS CLI is not installed or not in PATH"
        print_info "Install AWS CLI from: https://aws.amazon.com/cli/"
    else
        local aws_version=$(aws --version 2>&1 | cut -d' ' -f1 | cut -d'/' -f2)
        print_success "AWS CLI installed: version $aws_version"
    fi

    # Check if AWS credentials are configured
    if ! aws sts get-caller-identity &> /dev/null; then
        print_warning "AWS credentials not configured or invalid"
        print_info "Configure AWS credentials using: aws configure"
        print_info "Or set environment variables: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY"
    else
        local aws_account=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
        local aws_user=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null)
        print_success "AWS credentials configured"
        print_info "Account: $aws_account"
        print_info "Identity: $aws_user"
    fi

    # Check if Maven is installed (for backend build)
    if ! command -v mvn &> /dev/null; then
        print_warning "Maven is not installed or not in PATH"
        print_info "Install Maven from: https://maven.apache.org/download.cgi"
    else
        local mvn_version=$(mvn -v 2>&1 | head -n 1 | cut -d' ' -f3)
        print_success "Maven installed: version $mvn_version"
    fi

    # Check if Flutter is installed (for frontend build)
    if ! command -v flutter &> /dev/null; then
        print_warning "Flutter is not installed or not in PATH"
        print_info "Install Flutter from: https://flutter.dev/docs/get-started/install"
    else
        local flutter_version=$(flutter --version 2>&1 | head -n 1 | cut -d' ' -f2)
        print_success "Flutter installed: version $flutter_version"
    fi

    echo ""

    if [ "$all_good" = false ]; then
        print_error "Required tools are missing. Please install them before proceeding."
        exit 1
    fi
}

# Main execution
main() {
    print_info "=================================================="
    print_info "CareConnect Terraform Deployment Script"
    print_info "=================================================="
    echo ""

    # Check prerequisites
    check_prerequisites

    # Array of folders in execution order
    folders=(
        "1_s3_tfstate"
        "2_general"
        "3_database"
        "4_compute"
    )

    # Check if all folders exist
    print_info "Checking Terraform folders..."
    for folder in "${folders[@]}"; do
        if [ ! -d "$SCRIPT_DIR/$folder" ]; then
            print_error "Folder $folder does not exist!"
            exit 1
        fi
    done
    print_success "All Terraform folders found"
    echo ""

    # If destroy mode is enabled, run destroy in reverse order first
    if [ "$DESTROY_MODE" = true ]; then
        print_warning "=================================================="
        print_warning "DESTROY MODE ENABLED"
        print_warning "This will destroy all Terraform resources!"
        print_warning "=================================================="
        echo ""

        # Confirm with user
        read -p "$(echo -e ${RED}Are you sure you want to destroy all resources? [y/N]:${NC} )" -n 1 -r
        echo ""

        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_warning "Destroy cancelled."
            exit 0
        fi

        # Get backend bucket name from 1_s3_tfstate outputs if available
        if [ -d "$SCRIPT_DIR/1_s3_tfstate" ]; then
            cd "$SCRIPT_DIR/1_s3_tfstate"
            BACKEND_BUCKET_NAME=$(terraform output -raw backend_bucket_name 2>/dev/null)
            if [ -n "$BACKEND_BUCKET_NAME" ]; then
                export TF_BACKEND_BUCKET="$BACKEND_BUCKET_NAME"
                print_info "Using backend bucket: $TF_BACKEND_BUCKET"
            fi
            cd "$SCRIPT_DIR"
        fi

        # Destroy in reverse order (exclude 1_s3_tfstate for now)
        print_info "Starting Terraform destroy in reverse order..."
        echo ""

        for ((i=${#folders[@]}-1; i>=0; i--)); do
            destroy_terraform "$SCRIPT_DIR/${folders[i]}"
            echo ""
        done

        print_success "=================================================="
        print_success "All Terraform resources destroyed successfully!"
        print_success "=================================================="
        exit 0
    fi

    # Ask if user wants to build projects
    read -p "$(echo -e ${YELLOW}Do you want to build the backend and frontend? [Y/n]:${NC} )" -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        # Build backend
        build_backend
        echo ""

        # Build frontend
        build_frontend
        echo ""
    else
        print_warning "Skipping build step"
        echo ""
    fi

    # Ask if user wants to proceed with Terraform deployment
    read -p "$(echo -e ${YELLOW}Do you want to proceed with Terraform deployment? [Y/n]:${NC} )" -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_warning "Deployment cancelled."
        exit 0
    fi

    # Collect SSM parameters before deployment
    echo ""
    collect_ssm_params

    # Execute Terraform in each folder
    print_info "Starting Terraform deployment in sequential order..."
    echo ""

    for folder in "${folders[@]}"; do
        run_terraform "$SCRIPT_DIR/$folder"
        echo ""
    done

    print_success "=================================================="
    print_success "All Terraform deployments completed successfully!"
    print_success "=================================================="
    echo ""

    # Print final summary with all important endpoints
    print_final_summary
}

# Function to print final deployment summary
print_final_summary() {
    print_info "=================================================="
    print_info "DEPLOYMENT SUMMARY - IMPORTANT ENDPOINTS"
    print_info "=================================================="
    echo ""

    # Get outputs from each module
    print_info "Retrieving deployment information..."
    echo ""

    # 2_general outputs
    if [ -d "$SCRIPT_DIR/2_general" ]; then
        cd "$SCRIPT_DIR/2_general"

        print_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print_success "API Endpoints (from 2_general)"
        print_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        local main_api=$(terraform output -raw main_api_endpoint 2>/dev/null)
        local amplify=$(terraform output -raw amplify_url 2>/dev/null)

        echo ""
        print_info "REST API:"
        [ -n "$main_api" ] && echo "  $main_api" || echo "  (not available)"

        echo ""
        print_info "Frontend (Amplify):"
        [ -n "$amplify" ] && echo "  https://$amplify" || echo "  (not available)"

        cd "$SCRIPT_DIR"
    fi

    echo ""

    # 4_compute outputs
    if [ -d "$SCRIPT_DIR/4_compute" ]; then
        cd "$SCRIPT_DIR/4_compute"

        print_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print_success "Lambda Backend (from 4_compute)"
        print_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        local lambda_name=$(terraform output -raw cc_main_backend_lambda_function_name 2>/dev/null)
        local lambda_arn=$(terraform output -raw cc_main_backend_lambda_arn 2>/dev/null)
        local lambda_invoke=$(terraform output -raw cc_main_backend_lambda_invoke_arn 2>/dev/null)
        local ws_client=$(terraform output -raw websocket_api_endpoint 2>/dev/null)
        local ws_mgmt=$(terraform output -raw websocket_management_endpoint 2>/dev/null)

        echo ""
        print_info "Function Name:"
        [ -n "$lambda_name" ] && echo "  $lambda_name" || echo "  (not available)"

        echo ""
        print_info "Lambda ARN:"
        [ -n "$lambda_arn" ] && echo "  $lambda_arn" || echo "  (not available)"

        echo ""
        print_info "Invoke ARN (for API Gateway):"
        if [ -n "$lambda_invoke" ]; then
            echo "  $lambda_invoke"
            print_info "  → All 3 WebSocket routes (\$connect, \$disconnect, \$default) use this ARN"
        else
            echo "  (not available)"
        fi

        echo ""
        print_info "WebSocket Client Endpoint:"
        [ -n "$ws_client" ] && echo "  $ws_client" || echo "  (not available)"
        [ -n "$ws_client" ] && print_info "  → Use this in Flutter for real-time connections"

        echo ""
        print_info "WebSocket Management API:"
        [ -n "$ws_mgmt" ] && echo "  $ws_mgmt" || echo "  (not available)"
        [ -n "$ws_mgmt" ] && print_info "  → Lambda uses this to send messages"

        # Get WebSocket endpoint from Lambda environment
        if [ -n "$lambda_name" ]; then
            local ws_env=$(aws lambda get-function-configuration \
                --function-name "$lambda_name" \
                --query 'Environment.Variables.AWS_WEBSOCKET_API_ENDPOINT' \
                --output text 2>/dev/null)

            echo ""
            print_info "Lambda Environment - WebSocket Endpoint:"
            if [ -n "$ws_env" ] && [ "$ws_env" != "None" ] && [ "$ws_env" != "" ]; then
                echo "  $ws_env"
                print_success "  ✓ Lambda is configured with WebSocket endpoint"
            else
                echo "  (not configured)"
                print_warning "  ⚠ Lambda may need re-deployment to get WebSocket endpoint"
            fi
        fi

        cd "$SCRIPT_DIR"
    fi

    echo ""
    echo ""

    # Configure Lambda environment variables
    configure_lambda_environment
}

# Function to configure Lambda environment variables after deployment
configure_lambda_environment() {
    print_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_success "Configuring Lambda Environment Variables"
    print_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Get Lambda function name from 4_compute outputs
    cd "$SCRIPT_DIR/4_compute"
    local lambda_name=$(terraform output -raw cc_main_backend_lambda_function_name 2>/dev/null)

    if [ -z "$lambda_name" ]; then
        print_error "Could not retrieve Lambda function name from Terraform outputs"
        print_warning "Skipping Lambda environment configuration"
        return 1
    fi

    print_info "Lambda Function: $lambda_name"
    echo ""

    # Collect Terraform outputs
    print_info "Collecting Terraform outputs..."

    # From 2_general
    cd "$SCRIPT_DIR/2_general"
    local main_api=$(terraform output -raw main_api_endpoint 2>/dev/null)
    local amplify=$(terraform output -raw amplify_url 2>/dev/null)
    local s3_bucket=$(terraform output -raw internal_s3_bucket 2>/dev/null)

    # From 3_database
    cd "$SCRIPT_DIR/3_database"
    local db_endpoint=$(terraform output -raw db_cluster_endpoint 2>/dev/null)
    local db_port=$(terraform output -raw db_cluster_port 2>/dev/null)
    local db_name=$(terraform output -raw db_cluster_name 2>/dev/null)
    local db_secret_arn=$(terraform output -raw db_master_user_secret_arn 2>/dev/null)

    # From 4_compute
    cd "$SCRIPT_DIR/4_compute"
    local ws_mgmt=$(terraform output -raw websocket_management_endpoint 2>/dev/null)

    # Get database password from Secrets Manager
    print_info "Retrieving database password from Secrets Manager..."
    local db_password=$(aws secretsmanager get-secret-value \
        --secret-id "$db_secret_arn" \
        --query 'SecretString' \
        --output text 2>/dev/null | jq -r '.password' 2>/dev/null)

    if [ -z "$db_password" ]; then
        print_warning "Could not retrieve database password from Secrets Manager"
        db_password="PLACEHOLDER_PASSWORD"
    fi

    # Create temporary JSON file for Lambda environment variables
    local env_file="/tmp/lambda_env_config.json"

    print_info "Creating Lambda environment configuration..."
    cat > "$env_file" <<EOF
{
  "Variables": {
    "APP_FRONTEND_BASE_URL": "https://${amplify}",
    "AWS_S3_BUCKET": "${s3_bucket}",
    "AWS_S3_BASE_URL": "https://${s3_bucket}.s3.us-east-1.amazonaws.com",
    "BASE_URL": "${main_api}",
    "CC_APP_ROLE": "$(cd $SCRIPT_DIR/2_general && terraform output -raw cc_app_role_arn 2>/dev/null)",
    "CORS_ALLOWED_LIST": "http://localhost:*,http://127.0.0.1:*,https://${amplify}",
    "DB_HOST": "${db_endpoint}",
    "DB_NAME": "${db_name}",
    "DB_PASSWORD_SECRET_ARN": "${db_secret_arn}",
    "DB_PORT": "${db_port}",
    "DB_USER": "postgres",
    "DB_PASSWORD": "${db_password}",
    "AWS_WEBSOCKET_API_ENDPOINT": "${ws_mgmt}",
    "JDBC_URI": "jdbc:postgresql://${db_endpoint}:${db_port}/${db_name}",
    "CARECONNECT_DATABASE_USE_AWS_CONFIG": "false",
    "SPRING_DATASOURCE_URL": "jdbc:postgresql://${db_endpoint}:${db_port}/${db_name}",
    "SPRING_DATASOURCE_USERNAME": "postgres",
    "SPRING_DATASOURCE_PASSWORD": "${db_password}",
    "STRIPE_SECRET_KEY": "sk_test_placeholder_replace_with_real_key",
    "SECURITY_JWT_SECRET": "placeholder_jwt_secret_minimum_256_bits_required_for_hs256_algorithm_please_replace",
    "OPENAI_API_KEY": "sk-placeholder-openai-key",
    "STRIPE_WEBHOOK_SIGNING_SECRET": "whsec_placeholder_stripe_webhook_secret",
    "FITBIT_CLIENT_ID": "placeholder",
    "FITBIT_CLIENT_SECRET": "placeholder",
    "GOOGLE_CLIENT_ID": "placeholder.apps.googleusercontent.com",
    "GOOGLE_CLIENT_SECRET": "placeholder",
    "SENDGRID_API_KEY": "SG.placeholder",
    "FIREBASE_PROJECT_ID": "careconnectcapstone",
    "FIREBASE_SERVICE_ACCOUNT_KEY": "firebase-service-account.json",
    "FIREBASE_SENDER_ID": "663999888931"
  }
}
EOF

    print_info "Updating Lambda environment variables..."
    if aws lambda update-function-configuration \
        --function-name "$lambda_name" \
        --environment "file://$env_file" > /dev/null 2>&1; then
        print_success "Lambda environment variables updated successfully!"
        echo ""

        print_info "Configured variables:"
        echo "  ✓ Database connection (JDBC_URI, DB_HOST, DB_NAME, DB_PORT, DB_USER, DB_PASSWORD)"
        echo "  ✓ AWS services (S3_BUCKET, WEBSOCKET_ENDPOINT)"
        echo "  ✓ Application URLs (BASE_URL, FRONTEND_BASE_URL)"
        echo "  ✓ CORS configuration"
        echo ""

        print_warning "Placeholder variables (replace with real values):"
        echo "  • STRIPE_SECRET_KEY"
        echo "  • SECURITY_JWT_SECRET (required for JWT authentication)"
        echo "  • OPENAI_API_KEY"
        echo "  • STRIPE_WEBHOOK_SIGNING_SECRET"
        echo "  • OAuth2 credentials (FITBIT, GOOGLE)"
        echo "  • SENDGRID_API_KEY"
        echo ""

        print_info "To update these values, use:"
        echo "  aws lambda update-function-configuration --function-name $lambda_name \\"
        echo "    --environment Variables={...}"
    else
        print_error "Failed to update Lambda environment variables"
        print_info "You can manually update them using the AWS Console or CLI"
    fi

    # Clean up temp file
    rm -f "$env_file"

    cd "$SCRIPT_DIR"
}

# Run main function
main