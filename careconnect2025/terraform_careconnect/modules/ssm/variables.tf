variable "parameters" {
  description = "Map of SSM parameters to create"
  type = map(object({
    value       = string
    type        = optional(string, "SecureString")
    description = optional(string)
    tier        = optional(string, "Standard")
  }))
  default = {}
}

variable "kms_key_id" {
  description = "KMS key ID for encrypting SecureString parameters"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to SSM parameters"
  type        = map(string)
  default     = {}
}
