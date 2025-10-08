provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}

# GitHub Provider Configuration
provider "github" {
  token = var.github_token
}

