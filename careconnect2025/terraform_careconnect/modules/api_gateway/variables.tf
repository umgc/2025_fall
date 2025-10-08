variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "protocol_type" {
  description = "API protocol type (HTTP or WEBSOCKET)"
  type        = string
  default     = "HTTP"
}

variable "description" {
  description = "Description of the API Gateway"
  type        = string
  default     = ""
}

variable "stage_name" {
  description = "Name of the API stage"
  type        = string
  default     = "$default"
}

variable "auto_deploy" {
  description = "Whether to automatically deploy changes"
  type        = bool
  default     = true
}

variable "create_log_group" {
  description = "Whether to create CloudWatch log group"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 60
}

variable "cors_configuration" {
  description = "CORS configuration for the API"
  type = object({
    allow_credentials = optional(bool, false)
    allow_headers     = optional(list(string), ["*"])
    allow_methods     = optional(list(string), ["*"])
    allow_origins     = optional(list(string), ["*"])
    expose_headers    = optional(list(string), [])
    max_age           = optional(number, 0)
  })
  default = {
    allow_credentials = false
    allow_headers     = ["*"]
    allow_methods     = ["*"]
    allow_origins     = ["*"]
    expose_headers    = []
    max_age           = 0
  }
}

variable "lambda_integrations" {
  description = "Map of Lambda integrations"
  type = map(object({
    lambda_function_name   = string
    lambda_invoke_arn      = string
    route_key              = string
    payload_format_version = optional(string, "1.0")
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to API Gateway resources"
  type        = map(string)
  default     = {}
}
