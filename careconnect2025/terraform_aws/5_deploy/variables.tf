variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Target S3 bucket name"
  type        = string
}

variable "s3_prefix" {
  description = "Folder prefix inside the bucket, for example springboot3"
  type        = string
  default     = "springboot3"
}

variable "repo_owner" {
  description = "GitHub org or user that owns the repo"
  type        = string
}

variable "repo_name" {
  description = "GitHub repository name"
  type        = string
}

variable "allowed_ref" {
  description = "Git ref to allow. Use refs/heads/main for main only, or * to allow all branches"
  type        = string
  default     = "refs/heads/main"
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider in this account"
  type        = bool
  default     = false
}

variable "github_thumbprints" {
  description = "Thumbprints for the GitHub OIDC provider if you create it here"
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "KMS key ARN if bucket enforces SSE-KMS. Leave empty if not used"
  type        = string
  default     = ""
}

variable "create_bucket" {
  description = "Create the S3 bucket"
  type        = bool
  default     = false
}

variable "enable_bucket_versioning" {
  description = "Enable versioning if creating the bucket"
  type        = bool
  default     = true
}
