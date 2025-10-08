# ================================================================================
# Production Environment Configuration for EduLense
# ================================================================================
# Account: Production, Region: us-east-1, account_id: 123456789
# ================================================================================
# AWS CREDENTIALS (Local development only - not used in production)
# Production : use GitHub Actions pipeline and store the secrets in GitHub Secrets
# ================================================================================
access_key = ""
secret_key = ""
github_token = ""

# General Configuration
aws_region  = "us-east-1"
environment = "prod"
project     = "learninglens"
owner       = "learninglens"


# ================================================================================
# VPC Configuration
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
# EC2 Configuration (Moodle Server)
# ================================================================================
ec2 = {
  ami_id                      = "ami-084e1aeb6e428c390"
  instance_type               = "t3.small"
  root_volume_size           = 50
  root_volume_type           = "gp3"
  root_volume_encrypted      = true
  root_device_name           = "/dev/xvda"  
  associate_public_ip_address = true
  key_name                   = ""
  user_data_script_path      = "./scripts/moodle_setup.sh"

  ingress_rules = [
    {
      description = "HTTP access"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTPS access"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "SSH access from VPC"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  
  egress_rules = [
    {
      description = "All outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

# ================================================================================
# S3 Configuration
# ================================================================================
s3 = {
  bucket_name = "learninglens-lambda-deployment"
  
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
# Lambda Configuration
# ================================================================================
lambda = {
  enabled          = true  # Set to false for first deployment, true after uploading zip to S3
  function_name     = "get_db_token"
  runtime          = "nodejs20.x"  # Node.js runtime for AI logging
  handler          = "index.handler"
  timeout          = 10
  memory_size      = 512
  s3_bucket        = "learninglens-lambda-deployment"        # S3 bucket for Lambda deployment
  s3_key           = "gettoken.zip"                   # S3 key for Lambda deployment package
  
  environment_variables = {
    ENVIRONMENT      = "production"
    LOG_LEVEL        = "info"
    DSQL_ENDPOINT    = "tvthczdvx26w4hh3hvtgli5p7u.dsql.us-east-1.on.aws"
    DSQL_REGION      = "us-east-1"
    DSQL_CLUSTER_ARN = "arn:aws:dsql:us-east-1:060569176293:cluster/tvthczdvx26w4hh3hvtgli5p7u"
    DSQL_CLUSTER_ID  = "tvthczdvx26w4hh3hvtgli5p7u"
  }
  
  function_url_auth_type = "NONE"
  function_url_cors = {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["GET", "POST", "PUT", "DELETE", "PATCH"]
    allow_headers     = ["date", "keep-alive", "content-type", "authorization"]
    expose_headers    = ["date", "keep-alive"]
    max_age          = 86400
  }
  
  ingress_rules = []
  egress_rules = [
    {
      description = "All outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

# ================================================================================
# Frontend Configuration
# ================================================================
frontend = {
  app_name        = "edulense-frontend"
  repository      = ""  
  branch_name     = "team_e"  
  framework       = "Flutter"
  enable_webhook  = true
  env_file_path   = "../teamA/.env"  # Path to .env file (relative to terraform_N folder)
  
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
        - cd LearningLens2025/teamA/
        - flutter pub get
        - flutter create . --platforms web
    build:
      commands:
        - echo "Building Flutter web application"
        - echo "$ENV_FILE" > .env
        - export ENV_FILE=
        - flutter build web
  artifacts:
    baseDirectory: LearningLens2025/teamA/build/web/
    files:
      - '**/*'
      - '.env'
      - 'assets/.env'
  cache:
    paths:
      - flutter/.pub-cache
EOT
}

# ================================================================================
# DSQL Configuration
# ================================================================================
dsql = {
  cluster_name                = "EduLenseAILoggingDatabase"
  deletion_protection_enabled = true
  create_iam_role            = true
  additional_policy_arns     = []
}