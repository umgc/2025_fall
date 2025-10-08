output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "function_qualified_arn" {
  description = "Qualified ARN of the Lambda function"
  value       = aws_lambda_function.this.qualified_arn
}

output "function_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.this.invoke_arn
}

output "function_version" {
  description = "Version of the Lambda function"
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
  value       = var.create_log_group ? aws_cloudwatch_log_group.lambda_logs[0].name : null
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = var.create_log_group ? aws_cloudwatch_log_group.lambda_logs[0].arn : null
}

output "deployment_package_path" {
  description = "Path to the deployment package"
  value       = var.output_path
}

output "deployment_package_size" {
  description = "Size of the deployment package in bytes"
  value       = length(data.archive_file.lambda_zip) > 0 ? data.archive_file.lambda_zip[0].output_size : 0
}

# ================================================================
# LAMBDA FUNCTION URL OUTPUTS
# ================================================================
output "function_url" {
  description = "The HTTP URL endpoint for the function"
  value       = var.create_function_url ? aws_lambda_function_url.function_url[0].function_url : null
}