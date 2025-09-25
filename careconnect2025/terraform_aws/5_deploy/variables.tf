variable "s3_bucket_name" {
  description = "The name of the existing S3 bucket for storing builds."
  type        = string
}
variable "s3_bucket_backend_folder" {
  description = "The name of the existing S3 bucket folder for storing backend builds."
  type        = string
}
variable "s3_bucket_frontend_folder" {
  description = "The name of the existing S3 bucket folder for storing frontend builds."
  type        = string
}
variable "github_repo" {
  description = "The GitHub repository in 'owner/repo' format (e.g., 'my-username/my-cool-app')."
  type        = string
}
variable "github_branch" {
  description = "The GitHub repository branch name."
  type        = string
}

variable "aws_region" {
  description = "The AWS region where your resources are located."
  type        = string
  default     = "us-east-1"
}
