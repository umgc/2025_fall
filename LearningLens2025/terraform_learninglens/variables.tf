# Global Variables for EduLense Terraform Deployment

variable "project" {
  description = "Name of the project"
  type        = string
  default     = "edulense"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "learninglens"
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "access_key" {
  type        = string
  description = "The IAM access key"
  sensitive   = true
}

variable "secret_key" {
  type        = string
  description = "The IAM secret key"
  sensitive   = true
}

# ================================================================
# GITHUB CONFIGURATION
# ================================================================
variable "github_token" {
  description = "GitHub personal access token for Amplify"
  type        = string
  sensitive   = true
}

# ================================================================
# API KEYS
# ================================================================
variable "openai_api_key" {
  description = "OpenAI API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "perplexity_api_key" {
  description = "Perplexity API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "grok_api_key" {
  description = "Grok API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "google_client_id" {
  description = "Google Client ID for Classroom API"
  type        = string
  sensitive   = true
  default     = ""
}

variable "claude_api_key" {
  description = "Claude API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "deepseek_api_key" {
  description = "DeepSeek API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "moodle_username" {
  description = "Moodle username for auto-login"
  type        = string
  sensitive   = true
  default     = ""
}

variable "moodle_password" {
  description = "Moodle password for auto-login"
  type        = string
  sensitive   = true
  default     = ""
}

# ================================================================
# VPC CONFIGURATION
# ================================================================
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "A list of public subnets with CIDR blocks, availability zones, and mapping options for public IPs."
  type = list(object({
    cidr                    = string
    availability_zone       = string
    map_public_ip_on_launch = bool
  }))
  default = []
}

variable "private_subnets" {
  description = "A list of private subnets with CIDR blocks and availability zones."
  type = list(object({
    cidr              = string
    availability_zone = string
  }))
  default = []
}



variable "create_nat_gateway" {
  description = "Whether to create NAT Gateway for private subnets"
  type        = bool
  default     = true
}



# ================================================================
# EC2 CONFIGURATION
# ================================================================
variable "ec2" {
  description = "EC2 instance configuration"
  type = object({
    ami_id                     = string
    instance_type              = string
    root_volume_size          = number
    root_volume_type          = string
    root_volume_encrypted     = bool
    root_device_name          = string
    associate_public_ip_address = bool
    create_elastic_ip         = optional(bool, true)
    key_name                  = string
    user_data_script_path     = string
    monitoring                = optional(bool, true)
    ingress_rules = list(object({
      description = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    }))
    egress_rules = list(object({
      description = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    }))
  })
}

# ================================================================
# LAMBDA CONFIGURATION
# ================================================================
variable "lambda" {
  description = "Lambda function configuration"
  type = object({
    enabled                  = optional(bool, true)
    function_name             = string
    runtime                  = string
    handler                  = string
    timeout                  = number
    memory_size              = number
    s3_bucket                = string
    s3_key                   = string
    environment_variables    = map(string)
    function_url_auth_type   = string
    function_url_cors = object({
      allow_credentials = bool
      allow_origins     = list(string)
      allow_methods     = list(string)
      allow_headers     = list(string)
      expose_headers    = list(string)
      max_age          = number
    })
    ingress_rules = list(object({
      description = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    }))
    egress_rules = list(object({
      description = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    }))
  })
}

# ================================================================
# FRONTEND CONFIGURATION
# ================================================================
variable "frontend" {
  description = "Frontend application configuration (AWS Amplify)"
  type = object({
    app_name              = string
    repository            = string
    branch_name           = string
    framework             = string
    environment_variables = map(string)
    build_spec           = string
    enable_webhook        = bool
    env_file_path        = string
  })
}

variable "env_file_path" {
  description = "Path to the .env file for the Flutter app"
  type        = string
  default     = "../teamA/.env"
}

variable "amplify_build_spec" {
  description = "Build specification for the Amplify app"
  type        = string
  default     = "version: 1\nfrontend:\n  phases:\n    preBuild:\n      commands:\n        - npm ci\n    build:\n      commands:\n        - npm run build\n  artifacts:\n    baseDirectory: build\n    files:\n      - '**/*'\n  cache:\n    paths:\n      - node_modules/**/*"
}

variable "amplify_basic_auth_credentials" {
  description = "Basic authentication credentials for Amplify (base64 encoded username:password)"
  type        = string
  sensitive   = true
  default     = ""
}

# ================================================================
# S3 CONFIGURATION
# ================================================================
variable "s3" {
  description = "S3 bucket configuration"
  type = object({
    bucket_name     = string
    lifecycle_rules = any
    cors_rules      = any
  })
}

# ================================================================
# DSQL CONFIGURATION
# ================================================================
variable "dsql" {
  description = "Aurora DSQL cluster configuration"
  type = object({
    cluster_name                = string
    deletion_protection_enabled = bool
    create_iam_role            = bool
    additional_policy_arns     = list(string)
  })
}
