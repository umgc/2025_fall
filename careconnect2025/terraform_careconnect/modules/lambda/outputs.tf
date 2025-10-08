output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.this.invoke_arn
}

output "qualified_arn" {
  description = "Qualified ARN of the Lambda function"
  value       = aws_lambda_function.this.qualified_arn
}

output "version" {
  description = "Latest published version of the Lambda function"
  value       = aws_lambda_function.this.version
}

output "function_last_modified" {
  description = "Date the Lambda function was last modified"
  value       = aws_lambda_function.this.last_modified
}

output "function_source_code_hash" {
  description = "Base64-encoded representation of raw SHA-256 sum of the zip file"
  value       = aws_lambda_function.this.source_code_hash
}

output "function_source_code_size" {
  description = "Size in bytes of the function .zip file"
  value       = aws_lambda_function.this.source_code_size
}

output "role_arn" {
  description = "ARN of the IAM role used by the Lambda function"
  value       = aws_iam_role.lambda_role.arn
}

output "role_name" {
  description = "Name of the IAM role used by the Lambda function"
  value       = aws_iam_role.lambda_role.name
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = var.create_log_group ? aws_cloudwatch_log_group.lambda_log_group[0].name : null
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = var.create_log_group ? aws_cloudwatch_log_group.lambda_log_group[0].arn : null
}

# ================================================================
# LAMBDA FUNCTION URL OUTPUTS
# ================================================================
output "function_url" {
  description = "The HTTP URL endpoint for the function"
  value       = var.create_function_url ? aws_lambda_function_url.function_url[0].function_url : null
}

# ================================================================
# S3 SOURCE OUTPUTS
# ================================================================
output "s3_bucket" {
  description = "S3 bucket used for Lambda deployment"
  value       = var.s3_bucket
}

output "s3_key" {
  description = "S3 key used for Lambda deployment"
  value       = var.s3_key
}

output "deployment_source" {
  description = "Source used for deployment (always S3)"
  value       = "S3"
}