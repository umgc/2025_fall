output "cc_main_backend_lambda_qualified_arn" {
  description = "ARN of the latest published version of the main backend Lambda function"
  value       = aws_lambda_function.cc_main_backend_lambda.qualified_arn
}

output "cc_main_backend_lambda_arn" {
  description = "ARN of the main backend Lambda function"
  value       = aws_lambda_function.cc_main_backend_lambda.arn
}

output "cc_main_backend_lambda_invoke_arn" {
  description = "Invoke ARN of the main backend Lambda function for API Gateway integration"
  value       = aws_lambda_function.cc_main_backend_lambda.invoke_arn
}

output "cc_main_backend_lambda_function_name" {
  description = "Function name of the main backend Lambda"
  value       = aws_lambda_function.cc_main_backend_lambda.function_name
}

# WebSocket outputs (moved from 2_general)
output "websocket_management_endpoint" {
  description = "WebSocket API Gateway Management API endpoint for Lambda to send messages"
  value       = module.websocket.websocket_management_endpoint
}

output "websocket_api_endpoint" {
  description = "WebSocket API endpoint URL for client connections"
  value       = module.websocket.websocket_stage_invoke_url
}