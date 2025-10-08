output "api_id" {
  description = "ID of the API Gateway"
  value       = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "api_arn" {
  description = "ARN of the API Gateway"
  value       = aws_apigatewayv2_api.this.arn
}

output "stage_invoke_url" {
  description = "Invoke URL for the API stage"
  value       = aws_apigatewayv2_stage.this.invoke_url
}
