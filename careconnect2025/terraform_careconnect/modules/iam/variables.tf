variable "create_role" {
  description = "Whether to create IAM role"
  type        = bool
  default     = true
}

variable "role_name" {
  description = "Name of the IAM role"
  type        = string
  default     = ""
}

variable "assume_role_policy" {
  description = "Assume role policy document"
  type        = string
  default     = ""
}

variable "managed_policy_arns" {
  description = "List of managed policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Map of inline policies to attach to the role"
  type = map(object({
    policy = string
  }))
  default = {}
}

variable "custom_policies" {
  description = "Map of custom policies to create and attach"
  type = map(object({
    description = optional(string)
    policy      = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to IAM resources"
  type        = map(string)
  default     = {}
}
