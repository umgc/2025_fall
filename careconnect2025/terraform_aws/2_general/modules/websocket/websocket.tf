# WebSocket API Gateway for CareConnect
# This provides real-time communication for Lambda-based backend

resource "aws_apigatewayv2_api" "cc_websocket_api" {
  name                       = "cc-websocket-api"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"

  tags = var.default_tags
}

# WebSocket Stage (Production)
resource "aws_apigatewayv2_stage" "cc_websocket_stage" {
  api_id      = aws_apigatewayv2_api.cc_websocket_api.id
  name        = var.stage_name
  auto_deploy = true

  default_route_settings {
    detailed_metrics_enabled = true
    throttling_burst_limit   = 500
    throttling_rate_limit    = 100
    # Note: data_trace_enabled and logging_level are disabled by default
    # To enable logging, you must first configure an API Gateway CloudWatch Logs role
    # in your AWS account settings. See: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-logging.html
  }

  # Note: Access logging is disabled by default to avoid account-level IAM role requirement
  # Uncomment the block below after configuring API Gateway CloudWatch Logs role
  # access_log_settings {
  #   destination_arn = aws_cloudwatch_log_group.websocket_api_gw.arn
  #   format = jsonencode({
  #     requestId              = "$context.requestId"
  #     sourceIp               = "$context.identity.sourceIp"
  #     requestTime            = "$context.requestTime"
  #     protocol               = "$context.protocol"
  #     routeKey               = "$context.routeKey"
  #     status                 = "$context.status"
  #     responseLength         = "$context.responseLength"
  #     integrationErrorMessage = "$context.integrationErrorMessage"
  #     errorMessage           = "$context.error.message"
  #     connectionId           = "$context.connectionId"
  #     eventType              = "$context.eventType"
  #   })
  # }

  tags = var.default_tags
}

# CloudWatch Log Group for WebSocket API
resource "aws_cloudwatch_log_group" "websocket_api_gw" {
  name              = "/aws/apigateway/${aws_apigatewayv2_api.cc_websocket_api.name}"
  retention_in_days = 30
  tags              = var.default_tags
}

# $connect Route Integration
resource "aws_apigatewayv2_integration" "connect" {
  api_id             = aws_apigatewayv2_api.cc_websocket_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = var.connect_lambda_invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "connect" {
  api_id    = aws_apigatewayv2_api.cc_websocket_api.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.connect.id}"
}

# $disconnect Route Integration
resource "aws_apigatewayv2_integration" "disconnect" {
  api_id             = aws_apigatewayv2_api.cc_websocket_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = var.disconnect_lambda_invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "disconnect" {
  api_id    = aws_apigatewayv2_api.cc_websocket_api.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.disconnect.id}"
}

# $default Route Integration (for all other messages)
resource "aws_apigatewayv2_integration" "default" {
  api_id             = aws_apigatewayv2_api.cc_websocket_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = var.default_lambda_invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.cc_websocket_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.default.id}"
}

# Lambda Permissions for API Gateway to invoke Lambda functions
resource "aws_lambda_permission" "connect" {
  statement_id  = "AllowAPIGatewayInvokeConnect"
  action        = "lambda:InvokeFunction"
  function_name = var.connect_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.cc_websocket_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "disconnect" {
  statement_id  = "AllowAPIGatewayInvokeDisconnect"
  action        = "lambda:InvokeFunction"
  function_name = var.disconnect_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.cc_websocket_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "default" {
  statement_id  = "AllowAPIGatewayInvokeDefault"
  action        = "lambda:InvokeFunction"
  function_name = var.default_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.cc_websocket_api.execution_arn}/*/*"
}