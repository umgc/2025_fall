# Global Variables for CareConnect Terraform Deployment

variable "project" {
  description = "Name of the project"
  type        = string
  default     = "careconnect"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "careconnect-team"
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
# NOTE: Application secrets are now managed via SSM Parameter Store
# See ssm.tf for all secret parameters
# ================================================================



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
# RDS DATABASE CONFIGURATION
# ================================================================
variable "rds" {
  description = "RDS database configuration"
  type = object({
    identifier                  = string
    engine                      = string
    engine_version              = string
    instance_class              = string
    allocated_storage           = number
    max_allocated_storage       = number
    storage_type                = string
    iops                        = number
    storage_encrypted           = bool
    db_name                     = string
    username                    = string
    password                    = optional(string)
    port                        = number
    multi_az                    = bool
    publicly_accessible         = bool
    manage_master_user_password = optional(bool, false)
    backup_retention_period     = number
    backup_window               = string
    maintenance_window          = string
    deletion_protection         = bool
    skip_final_snapshot         = bool
    final_snapshot_identifier   = string
    enabled_cloudwatch_logs_exports = list(string)
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
  sensitive = true
}

# ================================================================
# LAMBDA CONFIGURATION
# ================================================================
variable "lambda" {
  description = "Lambda function configuration"
  type = object({
    function_name          = string
    runtime                = string
    handler                = string
    timeout                = number
    memory_size            = number
    use_s3_source          = optional(bool, false)
    s3_bucket              = optional(string)
    s3_key                 = optional(string)
    source_path            = optional(string, "")
    output_path            = optional(string, "")
    environment_variables  = map(string)
    cors_allowed_origins   = list(string)
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
# S3 CONFIGURATION
# ================================================================
variable "s3" {
  description = "S3 bucket configuration"
  type = object({
    bucket_name = string
    lifecycle_rules = list(object({
      id                                 = string
      status                             = string
      noncurrent_version_expiration_days = optional(number)
      transitions = optional(list(object({
        days          = number
        storage_class = string
      })))
    }))
    cors_rules = list(object({
      allowed_headers = list(string)
      allowed_methods = list(string)
      allowed_origins = list(string)
      expose_headers  = optional(list(string))
      max_age_seconds = optional(number)
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

variable "amplify_basic_auth_credentials" {
  description = "Basic authentication credentials for Amplify (base64 encoded username:password)"
  type        = string
  sensitive   = true
  default     = ""
}
