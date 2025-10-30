output "websocket_api_id" {
  description = "WebSocket API ID"
  value       = aws_apigatewayv2_api.cc_websocket_api.id
}

output "websocket_api_endpoint" {
  description = "WebSocket API endpoint URL"
  value       = aws_apigatewayv2_api.cc_websocket_api.api_endpoint
}

output "websocket_api_execution_arn" {
  description = "WebSocket API execution ARN"
  value       = aws_apigatewayv2_api.cc_websocket_api.execution_arn
}

output "websocket_stage_name" {
  description = "WebSocket API stage name"
  value       = aws_apigatewayv2_stage.cc_websocket_stage.name
}

output "websocket_stage_invoke_url" {
  description = "WebSocket API stage invoke URL (wss://)"
  value       = aws_apigatewayv2_stage.cc_websocket_stage.invoke_url
}

output "websocket_management_endpoint" {
  description = "WebSocket API Gateway Management API endpoint for sending messages"
  value       = "https://${aws_apigatewayv2_api.cc_websocket_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${aws_apigatewayv2_stage.cc_websocket_stage.name}"
}

data "aws_region" "current" {}