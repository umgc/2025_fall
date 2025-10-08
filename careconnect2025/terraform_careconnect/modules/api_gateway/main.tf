resource "aws_cloudwatch_log_group" "this" {
  count = var.create_log_group ? 1 : 0

  name              = "/aws/apigateway/${var.api_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
  
  # Handle existing log groups gracefully
  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_apigatewayv2_api" "this" {
  name          = var.api_name
  protocol_type = var.protocol_type
  description   = var.description

  cors_configuration {
    allow_credentials = var.cors_configuration.allow_credentials
    allow_headers     = var.cors_configuration.allow_headers
    allow_methods     = var.cors_configuration.allow_methods
    allow_origins     = var.cors_configuration.allow_origins
    expose_headers    = var.cors_configuration.expose_headers
    max_age           = var.cors_configuration.max_age
  }

  tags = var.tags
}

resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = var.stage_name
  auto_deploy = var.auto_deploy

  access_log_settings {
    destination_arn = var.create_log_group ? aws_cloudwatch_log_group.this[0].arn : null
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = var.tags
}

resource "aws_apigatewayv2_integration" "lambda" {
  for_each = var.lambda_integrations

  api_id           = aws_apigatewayv2_api.this.id
  integration_type = "AWS_PROXY"

  integration_uri        = each.value.lambda_invoke_arn
  integration_method     = "POST"
  payload_format_version = each.value.payload_format_version
}

resource "aws_apigatewayv2_route" "this" {
  for_each = var.lambda_integrations

  api_id    = aws_apigatewayv2_api.this.id
  route_key = each.value.route_key
  target    = "integrations/${aws_apigatewayv2_integration.lambda[each.key].id}"
}

resource "aws_lambda_permission" "api_gateway" {
  for_each = var.lambda_integrations

  statement_id  = "AllowExecutionFromAPIGateway-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
