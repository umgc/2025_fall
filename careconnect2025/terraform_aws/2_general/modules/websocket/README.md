# CareConnect WebSocket API Gateway Module

This Terraform module creates an AWS API Gateway WebSocket API for real-time communication with the CareConnect backend running on AWS Lambda.

## Architecture

The WebSocket API provides three main routes:

1. **$connect** - Handles new WebSocket connections
   - Registers connection in PostgreSQL via `AwsWebSocketService.registerConnection()`
   - Validates connection parameters
   - Sets up connection metadata

2. **$disconnect** - Handles WebSocket disconnections
   - Deactivates connection in PostgreSQL via `AwsWebSocketService.deregisterConnection()`
   - Cleans up connection state

3. **$default** - Handles all WebSocket messages
   - Routes messages to appropriate handlers
   - Processes subscription requests (e.g., email-verification)
   - Updates last activity timestamps

## Backend Integration

The backend uses the `AwsWebSocketService` class to:
- Track connections in PostgreSQL (`websocket_connections` table)
- Send messages via API Gateway Management API
- Handle email verification notifications
- Clean up expired connections

## Usage

**Important**: All three routes point to the **SAME** main backend Lambda. The Spring Boot backend handles routing internally.

```hcl
module "websocket" {
  source = "./modules/websocket"

  default_tags = var.default_tags
  stage_name   = "prod"

  # All routes use the SAME main backend Lambda
  # Spring Boot's AwsWebSocketService handles the routing
  connect_lambda_function_name    = "cc-backend-main"
  connect_lambda_invoke_arn       = aws_lambda_function.backend.invoke_arn

  disconnect_lambda_function_name = "cc-backend-main"
  disconnect_lambda_invoke_arn    = aws_lambda_function.backend.invoke_arn

  default_lambda_function_name    = "cc-backend-main"
  default_lambda_invoke_arn       = aws_lambda_function.backend.invoke_arn
}
```

## Outputs

- `websocket_api_endpoint` - WebSocket API endpoint URL (wss://)
- `websocket_management_endpoint` - Management API endpoint for sending messages
- `websocket_api_id` - API ID
- `websocket_api_execution_arn` - Execution ARN for Lambda permissions

## Environment Variables

The backend requires this environment variable:

```
AWS_WEBSOCKET_API_GATEWAY_ENDPOINT=<management_endpoint_from_output>
```

This is set in `application-prod.properties`:
```properties
careconnect.websocket.aws.api-gateway-endpoint=${AWS_WEBSOCKET_API_GATEWAY_ENDPOINT}
```

## Features

- **Logging**: CloudWatch logs for all WebSocket events
- **Metrics**: Detailed metrics enabled for monitoring
- **Throttling**: Rate limiting (100 req/sec, burst 500)
- **Auto-deployment**: Automatic deployment on changes
- **CORS**: Not applicable to WebSocket APIs

## Notes

- Lambda functions must be created in the compute module (4_compute)
- Lambda functions need IAM permissions for API Gateway Management API
- Connection data is persisted in PostgreSQL for durability
- Maximum connection duration: 2 hours (configurable via TTL)