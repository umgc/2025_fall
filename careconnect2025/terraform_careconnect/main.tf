locals {
  default_tags = {
    MaintainedBy = var.owner
    CreatedBy    = "Terraform"
    Environment  = var.environment
    Project      = var.project
  }
}

terraform {
  backend "s3" {
  }
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.30.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4"
    }
  }
}
