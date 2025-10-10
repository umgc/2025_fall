variable "aws_region" {
  description = "The AWS region where resources will be created."
  type        = string
  default     = "us-east-1"
}

variable "rds_username" {
  description = "The master username for the RDS database."
  type        = string
  sensitive   = true
}

variable "rds_password" {
  description = "The master password for the RDS database."
  type        = string
  sensitive   = true
}

