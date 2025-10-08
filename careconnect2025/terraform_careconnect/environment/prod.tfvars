# ================================================================================
# CareConnect Production Environment Configuration
# ================================================================================
# Environment: Production | Region: us-east-1 | Last Updated: 2025-10-04
# ================================================================================
# ================================================================================
# AWS CREDENTIALS (Local development only - not used in production)
# Production : use GitHub Actions pipeline and store the secrets in GitHub Secrets
# ================================================================================
access_key = "YOUR_AWS_ACCESS_KEY_HERE"
secret_key = "YOUR_AWS_SECRET_KEY_HERE"
github_token = "YOUR_GITHUB_TOKEN_HERE"


# Global Configuration
aws_region  = "us-east-1"
environment = "prod"
project     = "careconnect"
owner       = "careconnect-team"

# ================================================================================
# Network Configuration
# ================================================================================
vpc_cidr = "10.1.0.0/16"

public_subnets = [
  { cidr = "10.1.1.0/24", availability_zone = "us-east-1a", map_public_ip_on_launch = true },
  { cidr = "10.1.2.0/24", availability_zone = "us-east-1b", map_public_ip_on_launch = true }
]

private_subnets = [
  { cidr = "10.1.3.0/24", availability_zone = "us-east-1a" },
  { cidr = "10.1.4.0/24", availability_zone = "us-east-1b" }
]

create_nat_gateway = true

# ================================================================================
# Database Configuration - PostgreSQL 16.4
# ================================================================================
rds = {
  identifier     = "careconnect-db"
  engine         = "postgres"
  engine_version = "16.4"
  instance_class = "db.t3.micro"
  
  allocated_storage     = 20
  max_allocated_storage = 250
  storage_type          = "gp3"
  iops                  = null
  storage_encrypted     = true
  
  db_name  = "careconnect"
  username = "careconnect_admin"
  password = "YOUR_DATABASE_PASSWORD_HERE"
  port     = 5432
  
  multi_az                    = false
  publicly_accessible         = false
  manage_master_user_password = false
  
  backup_retention_period   = 0
  backup_window             = "03:00-04:00"
  maintenance_window        = "mon:04:00-mon:05:00"
  deletion_protection       = false
  skip_final_snapshot       = true
  final_snapshot_identifier = null
  
  enabled_cloudwatch_logs_exports = ["postgresql"]
  
  ingress_rules = [
    {
      description = "PostgreSQL access from VPC"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = ["10.1.0.0/16"]
    }
  ]
  egress_rules = []
}

# ================================================================================
# S3 Storage Configuration
# ================================================================================
s3 = {
  bucket_name = "careconnect-internal-storage-us-east-1"
  
  lifecycle_rules = [
    {
      id                                 = "delete-old-versions"
      status                             = "Enabled"
      noncurrent_version_expiration_days = 90
    },
    {
      id     = "transition-to-ia"
      status = "Enabled"
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
    }
  ]
  
  cors_rules = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
      allowed_origins = ["*"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
  ]
}

# ================================================================================
# API Gateway Configuration
# ================================================================================
api_gateway = {
  api_name               = "careconnect-main-api"
  protocol_type          = "HTTP"
  description            = "Main API Gateway for CareConnect"
  stage_name             = "$default"
  auto_deploy            = true
  create_log_group       = true
  log_retention_days     = 60
  payload_format_version = "1.0"
  cors_configuration = {
    allow_credentials = true
    allow_headers     = ["*"]
    allow_methods     = ["*"]
    allow_origins     = ["http://*", "https://*"]
    expose_headers    = ["*"]
    max_age           = 360
  }
}

# ================================================================================
# Lambda Backend Configuration - Java 17 Spring Boot
# ================================================================================
lambda = {
  enabled       = true  # Set to false for first deployment, true after uploading zip to S3
  function_name = "careconnect_main_backend"
  runtime       = "java17"
  handler       = "com.careconnect.CcLambdaHandler"
  timeout       = 30
  memory_size   = 1024
  
  # S3 deployment configuration
  s3_bucket     = "careconnect-internal-storage-us-east-1"
  s3_key        = "careconnect-backend-0.0.1-SNAPSHOT-lambda-package.zip"
  
  # Environment variables reference SSM Parameter Store
  environment_variables = {
    ENVIRONMENT = "production"
    LOG_LEVEL   = "INFO"
    
    # Database
    JDBC_URI    = "/careconnect/prod/db/jdbc_uri"
    DB_USER     = "/careconnect/prod/db/username"
    DB_PASSWORD = "/careconnect/prod/db/password"
    
    # Application
    HIBERNATE_DDL_AUTO = "update"
    JWT_EXPIRATION     = "10800000"
    
    # Security
    SECURITY_JWT_SECRET = "YOUR_JWT_SECRET_KEY_HERE"
    
    # Third-party services
    STRIPE_SECRET_KEY = "YOUR_STRIPE_SECRET_KEY_HERE"
    STRIPE_WEBHOOK_SIGNING_SECRET = "YOUR_STRIPE_WEBHOOK_SECRET_HERE"
    OPENAI_API_KEY    = "YOUR_OPENAI_API_KEY_HERE"
    
    # Email
    MAIL_HOST          = "smtp.sendgrid.net"
    MAIL_PORT          = "587"
    MAIL_SMTP_AUTH     = "true"
    MAIL_SMTP_STARTTLS = "true"
    
    # Google OAuth
    GOOGLE_SCOPE         = "openid,email,profile"
    GOOGLE_REDIRECT_URI  = "{baseUrl}/login/oauth2/code/google"
    GOOGLE_AUTH_URI      = "https://accounts.google.com/o/oauth2/v2/auth"
    GOOGLE_TOKEN_URI     = "https://oauth2.googleapis.com/token"
    GOOGLE_USERINFO_URI  = "https://www.googleapis.com/oauth2/v3/userinfo"
    GOOGLE_CLIENT_ID     = "dummy"
    GOOGLE_CLIENT_SECRET = "dummy"
    
    # Fitbit
    FITBIT_CLIENT_ID     = "dummy"
    FITBIT_CLIENT_SECRET = "dummy"
  }
  
  cors_allowed_origins = [
    "https://developer.dvcrq9he1jxqx.amplifyapp.com/"
  ]
  
  ingress_rules = []
  egress_rules = [
    {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

# ================================================================================
# Frontend Configuration - AWS Amplify Flutter
# ================================================================================
frontend = {
  app_name       = "careconnect-frontend"
  repository     = ""
  branch_name    = "developer"
  framework      = "Flutter"
  enable_webhook = true
  env_file_path  = "careconnect2025/frontend/.env"
  
  environment_variables = {
    AMPLIFY_DIFF_DEPLOY = "false"
  }
  
  build_spec = <<-EOT
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - echo "Installing Flutter SDK"
        - git clone https://github.com/flutter/flutter.git -b stable --depth 1
        - export PATH="$PATH:$(pwd)/flutter/bin"
        - flutter config --no-analytics
        - flutter doctor
        - echo "Installing dependencies"
        - cd careconnect2025/frontend
        - flutter pub get
        - flutter create . --platforms web
    build:
      commands:
        - echo "Building Flutter web application"
        - flutter build web
  artifacts:
    baseDirectory: careconnect2025/frontend/build/web/
    files:
      - '**/*'
  cache:
    paths:
      - flutter/.pub-cache
EOT
}


