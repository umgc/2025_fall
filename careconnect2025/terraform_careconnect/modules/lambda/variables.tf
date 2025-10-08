variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = ""
}

variable "runtime" {
  description = "Runtime for the Lambda function"
  type        = string
  default     = "python3.11"
}

variable "handler" {
  description = "Handler for the Lambda function"
  type        = string
  default     = "index.handler"
}

variable "s3_bucket" {
  description = "S3 bucket containing the Lambda deployment package"
  type        = string
}

variable "s3_key" {
  description = "S3 key of the Lambda deployment package"
  type        = string
}

variable "timeout" {
  description = "Timeout for the Lambda function in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Memory size for the Lambda function in MB"
  type        = number
  default     = 128
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "vpc_config" {
  description = "VPC configuration for the Lambda function"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "dead_letter_config" {
  description = "Dead letter queue configuration"
  type = object({
    target_arn = string
  })
  default = null
}

variable "tracing_config" {
  description = "Tracing configuration for the Lambda function"
  type = object({
    mode = string
  })
  default = {
    mode = "PassThrough"
  }
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrent executions for the Lambda function"
  type        = number
  default     = -1
}

variable "publish" {
  description = "Whether to publish creation/change as new Lambda Function Version"
  type        = bool
  default     = false
}

variable "enable_snap_start" {
  description = "Enable SnapStart for Java 17 Lambda functions"
  type        = bool
  default     = true
}

variable "layers" {
  description = "List of Lambda Layer Version ARNs to attach to the function"
  type        = list(string)
  default     = []
}

variable "role_name" {
  description = "Name of the IAM role to create for the Lambda function"
  type        = string
}

variable "policy_arns" {
  description = "List of policy ARNs to attach to the Lambda execution role"
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

variable "custom_policies" {
  description = "List of custom policy documents to attach to the Lambda execution role"
  type        = list(string)
  default     = []
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "create_log_group" {
  description = "Whether to create a CloudWatch log group for the Lambda function"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to be added to the Lambda function and related resources"
  type        = map(string)
  default     = {}
}

# ================================================================
# LAMBDA FUNCTION URL VARIABLES
# ================================================================
variable "create_function_url" {
  description = "Whether to create a Lambda function URL"
  type        = bool
  default     = false
}

variable "function_url_auth_type" {
  description = "The type of authentication that the function URL uses"
  type        = string
  default     = "AWS_IAM"
  validation {
    condition     = contains(["AWS_IAM", "NONE"], var.function_url_auth_type)
    error_message = "function_url_auth_type must be either 'AWS_IAM' or 'NONE'."
  }
}

variable "function_url_cors" {
  description = "CORS configuration for the function URL"
  type = object({
    allow_credentials = optional(bool, false)
    allow_origins     = optional(list(string), ["*"])
    allow_methods     = optional(list(string), ["*"])
    allow_headers     = optional(list(string), ["date", "keep-alive"])
    expose_headers    = optional(list(string), ["date", "keep-alive"])
    max_age          = optional(number, 86400)
  })
  default = null
}