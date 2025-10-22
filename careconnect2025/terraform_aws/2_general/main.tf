terraform {

  # Consider using workspaces for different environments backends like dev, staging, prod
  # That could help in naming the resources differently based on the environment
  # NOTE: The backend block cannot use variables. You must manually update the bucket name
  # after running 1_s3_tfstate, or use: terraform init -backend-config="bucket=<bucket-name>"
  backend "s3" {
    key          = "tf-state/careconnect.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.90.0"
    }
  }
}

provider "aws" {
  region = var.primary_region
}

data "aws_caller_identity" "current" {}

# Retrieve the S3 bucket created in 1_s3_tfstate
data "aws_s3_bucket" "backend_bucket" {
  bucket = var.cc_iac_bucket_name
}

# Remote state for compute infrastructure removed - no longer needed in 2_general
# WebSocket module has been moved to 4_compute to resolve circular dependency

module "vpc" {
  source         = "./modules/vpc"
  default_tags   = var.default_tags
  primary_region = var.primary_region
}

module "s3_internal" {
  source                  = "./modules/s3"
  default_tags            = var.default_tags
  cc_internal_bucket_name = "cc-internal-file-storage-${var.primary_region}"
  cc_vpc_id               = module.vpc.vpc_id
  cc_app_role_arn         = module.iam.cc_app_role_info.arn
}
locals {
  params_keys = toset([for k, v in var.cc_ssm_params : k])
}
module "ssm" {
  source              = "./modules/ssm"
  default_tags        = var.default_tags
  params_keys         = local.params_keys
  cc_sensitive_params = var.cc_ssm_params
}

module "iam" {
  source                               = "./modules/iam"
  default_tags                         = var.default_tags
  primary_region                       = var.primary_region
  cc_internal_bucket_arn               = module.s3_internal.internal_s3_bucket.arn
  cc_applify_app_id                    = module.amplify.amplify_app_id
  only_compute_required_ssm_parameters = [for p in module.ssm.sensitive_params : p.arn]
}

module "amplify" {
  source          = "./modules/amplify"
  default_tags    = var.default_tags
  primary_region  = var.primary_region
  cc_app_role_arn = module.iam.cc_app_role_info.arn
}
# Create the SES Domain Identity for the provided domain name

resource "aws_ses_domain_identity" "ses_domain" {
  domain = var.domain_name  
}
# ---  Configure the Custom MAIL FROM domain ---
resource "aws_ses_domain_mail_from" "ses_mail_from" {
  domain           = aws_ses_domain_identity.ses_domain.domain
  mail_from_domain = "mail.${var.domain_name}"

  # This setting is optional but recommended. It tells SES to use its
  # default MAIL FROM domain if it runs into issues with your custom one,
  # which prevents your emails from being rejected.
  behavior_on_mx_failure = "UseDefaultValue"
}
# Generate the DKIM tokens needed for DNS verification

 resource "aws_ses_domain_dkim" "ses_domain_dkim" {
  domain = aws_ses_domain_identity.ses_domain.domain
}

# module "ses" {
#   source         = "./modules/ses"
#   default_tags   = var.default_tags
#   primary_region = var.primary_region
#   domain_name    = var.domain_name
#   # hosted_zone_id omitted because DNS is at Namecheap
# }

### This will be moved to the terraform compute app
module "main_api" {
  source               = "./modules/api"
  cc_main_api_role_arn = module.iam.cc_api_gw_role.arn
  cc_vpc_id            = module.vpc.vpc_id
  cc_main_api_sg_id    = module.vpc.cc_main_api_sg_id
  cc_main_sbn_ids      = module.vpc.cc_subnet_ids
  default_tags         = var.default_tags
}

##### This module will be used for CI/CD soon ######
module "evb" {
  source                   = "./modules/eventbridge"
  default_tags             = var.default_tags
  cc_app_role_arn          = module.iam.cc_app_role_info.arn
  cc_iac_bucket_name       = var.cc_iac_bucket_name
  cc_frontend_build_prefix = var.cc_frontend_build_prefix
  cc_aplify_app_id         = module.amplify.amplify_app_id
  cc_frontend_branch_name  = module.amplify.amplify_branch_name
  cc_stm_arn               = module.sfn_sm.cc_deployment_sfn_arn
}

##### This module will be used for CI/CD soon ######
module "sfn_sm" {
  source          = "./modules/stepfunction"
  cc_app_role_arn = module.iam.cc_app_role_info.arn
  default_tags    = var.default_tags
}

##### WebSocket API Gateway moved to 4_compute ######
# The WebSocket module has been moved to 4_compute/main.tf to resolve circular dependency.
# It will be deployed after the Lambda function is created in the same apply.