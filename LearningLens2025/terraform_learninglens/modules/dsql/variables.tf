# ================================================================================
# DSQL Module Variables
# ================================================================================

variable "cluster_name" {
  description = "Name of the DSQL cluster"
  type        = string
}

variable "deletion_protection_enabled" {
  description = "Enable deletion protection for the DSQL cluster"
  type        = bool
  default     = true
}

variable "create_iam_role" {
  description = "Whether to create an IAM role for DSQL access"
  type        = bool
  default     = true
}

variable "additional_policy_arns" {
  description = "List of additional IAM policy ARNs to attach to the DSQL role"
  type        = list(string)
  default     = []
}

# ================================================================================
# Common Variables
# ================================================================================

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}