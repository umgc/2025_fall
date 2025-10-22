# WebSocket Module Summary

## Purpose
Provides AWS API Gateway WebSocket API for real-time bidirectional communication between the CareConnect Flutter frontend and Lambda backend.

## Resources Created
1. **API Gateway WebSocket API** (`cc-websocket-api`)
   - Protocol: WEBSOCKET
   - Routes: $connect, $disconnect, $default

2. **API Gateway Stage** (`prod`)
   - Auto-deployment enabled
   - CloudWatch logging configured
   - Throttling: 100 req/sec (burst 500)

3. **Lambda Integrations**
   - $connect → Lambda function for connection handling
   - $disconnect → Lambda function for disconnection handling
   - $default → Lambda function for message routing

4. **CloudWatch Log Group**
   - Retention: 30 days
   - Detailed request/response logging

5. **Lambda Permissions**
   - Allows API Gateway to invoke Lambda functions

## Dependencies

### Required from Other Modules
- **IAM Module**: Lambda execution role with permissions for:
  - CloudWatch Logs
  - API Gateway Management API (execute-api:ManageConnections)
  - RDS PostgreSQL access

- **Compute Module** (4_compute): Lambda functions:
  - `cc-websocket-connect` - Handles new connections
  - `cc-websocket-disconnect` - Handles disconnections
  - `cc-websocket-default` - Handles messages

### Database
- PostgreSQL table: `websocket_connections`
- Automatically created by JPA from `WebSocketConnection` model

## Integration Steps

### 1. Create Lambda Functions (in 4_compute)
```hcl
# In terraform_aws/4_compute/main.tf

resource "aws_lambda_function" "websocket_connect" {
  function_name = "cc-websocket-connect"
  handler       = "com.careconnect.handler.WebSocketConnectHandler"
  runtime       = "java17"
  role          = var.lambda_execution_role_arn

  environment {
    variables = {
      DATABASE_URL = var.database_url
      AWS_WEBSOCKET_API_GATEWAY_ENDPOINT = var.websocket_management_endpoint
    }
  }
}

# Similar for disconnect and default handlers
```

### 2. Add Module to main.tf (in 2_general)
```hcl
module "websocket" {
  source = "./modules/websocket"

  default_tags = var.default_tags
  stage_name   = "prod"

  connect_lambda_function_name    = "cc-websocket-connect"
  connect_lambda_invoke_arn       = data.terraform_remote_state.compute.outputs.websocket_connect_lambda_invoke_arn

  disconnect_lambda_function_name = "cc-websocket-disconnect"
  disconnect_lambda_invoke_arn    = data.terraform_remote_state.compute.outputs.websocket_disconnect_lambda_invoke_arn

  default_lambda_function_name    = "cc-websocket-default"
  default_lambda_invoke_arn       = data.terraform_remote_state.compute.outputs.websocket_default_lambda_invoke_arn
}
```

### 3. Update IAM Permissions
Add to Lambda execution role:
```json
{
  "Effect": "Allow",
  "Action": [
    "execute-api:ManageConnections",
    "execute-api:Invoke"
  ],
  "Resource": "arn:aws:execute-api:*:*:*/@connections/*"
}
```

### 4. Set Environment Variables
After deployment, set in Lambda environment:
```bash
AWS_WEBSOCKET_API_GATEWAY_ENDPOINT=<output.websocket_management_endpoint>
```

## Outputs Used By
- **Backend Lambda Functions**: `websocket_management_endpoint`
- **Frontend**: `websocket_stage_invoke_url` (for connecting)
- **IAM Policies**: `websocket_api_execution_arn`

## Cost Considerations
- **API Gateway WebSocket**: $1.00 per million messages + $0.25 per million connection minutes
- **CloudWatch Logs**: ~$0.50/GB ingested
- **Data Transfer**: Standard AWS data transfer rates

## Monitoring
- CloudWatch Metrics: `AWS/ApiGateway` namespace
- Key Metrics:
  - `ConnectCount`: New connections
  - `MessageCount`: Messages sent/received
  - `IntegrationLatency`: Lambda invocation time
  - `ClientError/ServerError`: Error rates

## Current Status
⚠️ **Module created, not yet integrated**

This module is ready but requires:
1. Lambda functions to be created in `4_compute`
2. IAM permissions to be updated
3. Module to be added to `2_general/main.tf`

See README.md for detailed integration instructions.