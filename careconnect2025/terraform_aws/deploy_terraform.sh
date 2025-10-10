#!/bin/bash

set -e  # Exit on any error

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
    if [ "$folder_name" = "2_general" ] && [ -n "$TF_VAR_SSM_PARAMS" ]; then
        tf_var_flags="-var=cc_ssm_params=$TF_VAR_SSM_PARAMS"
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

        # Plan
        print_info "Planning Terraform changes..."
        terraform plan $tf_var_flags

        # Apply (Terraform will prompt for variables and confirmation)
        print_info "Applying Terraform configuration..."
        terraform apply $tf_var_flags

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

        # Plan
        print_info "Planning Terraform changes..."
        terraform plan $tf_var_flags

        # Apply (Terraform will prompt for variables and confirmation)
        print_info "Applying Terraform configuration..."
        terraform apply $tf_var_flags

        if [ $? -eq 0 ]; then
            print_success "Terraform apply completed for $folder_name"
        else
            print_error "Terraform apply failed for $folder_name"
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
        "5_deploy"
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
}

# Run main function
main