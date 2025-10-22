# WebSocket API Gateway Integration Guide

## Overview
The WebSocket module provides real-time communication for the CareConnect backend. **The Spring Boot backend already has all the WebSocket logic** in `AwsWebSocketService` - you just need to connect API Gateway routes to your existing Lambda function.

## Current Status
✅ **Module Created** - Ready for integration
✅ **Backend Code Ready** - `AwsWebSocketService` handles everything
⚠️ **Not Yet Activated** - Needs Terraform configuration in 4_compute

## Architecture

```
Frontend (Flutter)
    ↓ WebSocket Connection (wss://)
AWS API Gateway WebSocket API
    ├── $connect → Main Backend Lambda
    ├── $disconnect → Main Backend Lambda
    └── $default → Main Backend Lambda
    ↓
Spring Boot Backend
    ├── AwsWebSocketService.registerConnection()
    ├── AwsWebSocketService.deregisterConnection()
    └── AwsWebSocketService.sendMessage()
    ↓
PostgreSQL (websocket_connections table)
```

**Key Point**: All three WebSocket routes ($connect, $disconnect, $default) point to the **SAME** main backend Lambda. Spring Boot handles the routing internally based on the API Gateway event type.

## Integration Steps

### Step 1: Update IAM Permissions (4_compute)

Add API Gateway Management API permissions to your Lambda execution role:

```hcl
# In terraform_aws/4_compute/iam.tf (or wherever Lambda IAM is defined)

resource "aws_iam_role_policy" "websocket_management" {
  name = "websocket-management-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "execute-api:ManageConnections",
          "execute-api:Invoke"
        ]
        Resource = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:*/@connections/*"
      }
    ]
  })
}
```

### Step 2: Activate WebSocket Module (2_general)

In `terraform_aws/2_general/main.tf`, uncomment and update the WebSocket module:

```hcl
module "websocket" {
  source = "./modules/websocket"

  default_tags = var.default_tags
  stage_name   = "prod"

  # All three routes point to the SAME main backend Lambda
  # The Lambda name should match your existing backend Lambda
  connect_lambda_function_name    = "cc-backend-main"  # Your Lambda name
  connect_lambda_invoke_arn       = data.terraform_remote_state.compute.outputs.backend_lambda_invoke_arn

  disconnect_lambda_function_name = "cc-backend-main"  # Same Lambda
  disconnect_lambda_invoke_arn    = data.terraform_remote_state.compute.outputs.backend_lambda_invoke_arn

  default_lambda_function_name    = "cc-backend-main"  # Same Lambda
  default_lambda_invoke_arn       = data.terraform_remote_state.compute.outputs.backend_lambda_invoke_arn
}
```

### Step 3: Add Environment Variable

After deploying, get the WebSocket management endpoint:

```bash
cd terraform_aws/2_general
terraform apply
terraform output websocket_management_endpoint
```

Add this to your Lambda environment variables (in 4_compute):

```hcl
resource "aws_lambda_function" "backend" {
  # ... existing config ...

  environment {
    variables = {
      # ... existing vars ...
      AWS_WEBSOCKET_API_GATEWAY_ENDPOINT = data.terraform_remote_state.general.outputs.websocket_management_endpoint
    }
  }
}
```

Or add it to SSM Parameter Store and reference it.

### Step 4: Deploy

```bash
# Deploy general infrastructure first
cd terraform_aws/2_general
terraform init
terraform plan
terraform apply

# Then update compute with environment variable
cd ../4_compute
terraform plan
terraform apply
```

## How Spring Boot Handles WebSocket Events

The Spring Boot backend automatically detects WebSocket events from API Gateway:

### $connect Event
```java
// In AwsWebSocketService.registerConnection()
// Called when a client connects
// Stores connection in PostgreSQL
```

### $disconnect Event
```java
// In AwsWebSocketService.deregisterConnection()
// Called when a client disconnects
// Marks connection as inactive in PostgreSQL
```

### $default Event
```java
// Routes to existing Spring controllers
// Can handle custom message types
// Updates last activity timestamp
```

### Sending Messages (from backend)
```java
// In AwsWebSocketService.sendEmailVerificationNotification()
// Uses API Gateway Management API
// Retrieves connection from PostgreSQL
// Posts message to client
```

## Frontend Connection

The frontend already has WebSocket support in `EmailVerificationDialog`:

```dart
// Connects with query parameters
final wsUrl = Uri.parse(
  'wss://[api-id].execute-api.us-east-1.amazonaws.com/prod?email=${email}&type=email-verification'
);
_wsChannel = WebSocketChannel.connect(wsUrl);
```

The backend extracts these parameters in `registerConnection()`.

## Testing

### 1. Test Connection
```bash
# Install wscat if needed: npm install -g wscat

wscat -c "wss://[api-id].execute-api.us-east-1.amazonaws.com/prod?email=test@example.com&type=email-verification"
```

### 2. Check Database
```sql
-- View active connections
SELECT * FROM websocket_connections WHERE is_active = true;

-- View by email
SELECT * FROM websocket_connections WHERE user_email = 'test@example.com';
```

### 3. Test Email Verification Flow
1. Register a new user in the app
2. EmailVerificationDialog opens and connects via WebSocket
3. Check CloudWatch logs to see connection registered
4. Click email verification link
5. Backend calls `AwsWebSocketService.sendEmailVerificationNotification()`
6. Dialog receives message and closes automatically

### 4. Monitor CloudWatch Logs
```bash
# API Gateway logs
aws logs tail /aws/apigateway/cc-websocket-api --follow

# Lambda logs
aws logs tail /aws/lambda/cc-backend-main --follow
```

## Configuration Summary

### Backend (Already Done)
✅ `WebSocketConnection` model - Auto-creates DB table
✅ `WebSocketConnectionRepository` - Database queries
✅ `AwsWebSocketService` - Connection management
✅ `AuthService` - Sends verification notifications
✅ `application-prod.properties` - WebSocket config

### Terraform (To Do)
- [ ] Add IAM permissions for API Gateway Management API
- [ ] Uncomment WebSocket module in 2_general/main.tf
- [ ] Reference main backend Lambda (3 times for 3 routes)
- [ ] Add `AWS_WEBSOCKET_API_GATEWAY_ENDPOINT` to Lambda env vars
- [ ] Deploy

### Frontend (Already Done)
✅ `EmailVerificationDialog` - WebSocket connection
✅ `websocket_backend_service.dart` - WebSocket service
✅ Fallback to HTTP polling if WebSocket unavailable

## Troubleshooting

### "Connection refused" or timeout
- Verify Lambda has VPC access to database
- Check security groups allow outbound HTTPS
- Ensure Lambda execution role has correct permissions

### "403 Forbidden" from API Gateway
- Check IAM role has `execute-api:ManageConnections`
- Verify `AWS_WEBSOCKET_API_GATEWAY_ENDPOINT` is set correctly
- Ensure it's the **Management API** endpoint, not the WebSocket endpoint

### Messages not received by client
- Check connection is registered: `SELECT * FROM websocket_connections`
- Verify `connectionId` matches in logs
- Review CloudWatch logs for API Gateway Management API errors

### Stale connections in database
- Run cleanup: `AwsWebSocketService.cleanupExpiredConnections()`
- Consider adding a scheduled EventBridge rule to run cleanup
- Default TTL: 2 hours (configurable via `connection-ttl-minutes`)

## Cost Estimate

- **API Gateway WebSocket**: $1.00 per million messages
- **Connection minutes**: $0.25 per million minutes
- **CloudWatch Logs**: ~$0.50 per GB
- **Lambda**: No additional cost (uses existing backend Lambda)

**Example**: 1,000 users, 5 min average connection, 10 messages each
- Connection minutes: 1,000 × 5 = 5,000 minutes = **$0.00125**
- Messages: 1,000 × 10 = 10,000 messages = **$0.01**
- Total: **< $0.02/day** or **~$0.60/month**

## Next Steps

1. ✅ Add IAM permissions for API Gateway Management API
2. ✅ Uncomment WebSocket module in main.tf
3. ✅ Deploy with terraform apply
4. ✅ Set environment variable
5. ✅ Test email verification flow
6. Consider adding CloudWatch alarms for:
   - High connection count
   - High error rates
   - Failed message delivery

## Key Takeaway

**You don't need separate Lambda functions!** Your existing Spring Boot Lambda handles everything. The `AwsWebSocketService` class automatically manages WebSocket connections and messages. Just connect the API Gateway routes and add the IAM permissions.
