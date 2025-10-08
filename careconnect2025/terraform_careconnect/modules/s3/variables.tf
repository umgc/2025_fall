variable "bucket_name" {
  description = "The name of the bucket"
  type        = string
}

variable "versioning_enabled" {
  description = "Enable versioning"
  type        = bool
  default     = true
}

variable "sse_algorithm" {
  description = "The server-side encryption algorithm to use"
  type        = string
  default     = "AES256"
}

variable "block_public_access" {
  description = "Whether to block public access"
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules"
  type        = any
  default     = []
}

variable "cors_rules" {
  description = "List of CORS rules"
  type        = any
  default     = []
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
