variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
}

variable "stage_name" {
  description = "WebSocket API stage name"
  type        = string
  default     = "prod"
}

variable "connect_lambda_function_name" {
  description = "Name of the Lambda function for $connect route"
  type        = string
}

variable "connect_lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function for $connect route"
  type        = string
}

variable "disconnect_lambda_function_name" {
  description = "Name of the Lambda function for $disconnect route"
  type        = string
}

variable "disconnect_lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function for $disconnect route"
  type        = string
}

variable "default_lambda_function_name" {
  description = "Name of the Lambda function for $default route (message handler)"
  type        = string
}

variable "default_lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function for $default route"
  type        = string
}