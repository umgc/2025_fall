terraform {

  # Consider using workspaces for different environments backends like dev, staging, prod
  # That could help in naming the resources differently based on the environment
  backend "s3" {
    key          = "tf-state/careconnect-compute.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.90.0"
    }
  }
}
data "aws_s3_objects" "cc_package_list" { 
  bucket = var.cc_iac_bucket_name
  prefix = var.cc_main_backend_package_zip_s3key
}

data "terraform_remote_state" "cc_common_state" {
  backend = "s3"
  config = {
    bucket = "${var.cc_iac_bucket_name}"
    key    = "tf-state/careconnect.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "cc_db_state" {
  backend = "s3"
  config = {
    bucket = "${var.cc_iac_bucket_name}"
    key    = "careconnect-db-aurora-pg/terraform.tfstate"
    region = "us-east-1"
  }
}

# Zip up web app
data "archive_file" "web_app" {
  type        = "zip"
  source_dir  = var.absolute_path_to_frontend_webapp
  output_path = "${var.absolute_path_to_frontend_webapp}/../web.zip"
}

resource "aws_s3_object" "frontend_folder" {
  bucket = var.cc_iac_bucket_name
  key    = "${var.cc_main_frontend_build_prefix}/"
  content = "" # Creates an empty object to represent the folder
}

# Create backend folder in s3
resource "aws_s3_object" "backend_folder" {
  bucket = var.cc_iac_bucket_name
  key    = "${var.cc_main_backend_build_prefix}/"
  content = "" # Creates an empty object to represent the folder
}

# upload artifact
resource "aws_s3_object" "backend_object" {
  bucket = var.cc_iac_bucket_name
  key    = var.cc_main_backend_package_zip_s3key
  source = var.absolute_path_to_backend_artifact
  etag   = filemd5(var.absolute_path_to_backend_artifact)
}

# upload frontend artifact
resource "aws_s3_object" "frontend_object" {
  bucket = var.cc_iac_bucket_name
  key    = var.cc_main_frontend_package_zip_s3key
  source = data.archive_file.web_app.output_path
  etag   = data.archive_file.web_app.output_md5
}

resource "aws_cloudwatch_log_group" "cc_main_lambda_log_group" {
  name              = "/aws/lambda/cc_main_backend"
  retention_in_days = 90

  tags = merge(var.default_tags, {
    Name = "cc_lambda_main_backend_log_group"
  })
}

resource "aws_lambda_function" "cc_main_backend_lambda" {
  function_name = "cc_main_backend"
  description   = "Main backend Lambda function(Compute) for CareConnect"
  handler       = "com.careconnect.CcLambdaHandler::handleRequest"
  runtime       = "java17"
  role          = data.terraform_remote_state.cc_common_state.outputs.cc_app_role_info.arn
  memory_size   = 2048
  timeout       = 30
  s3_bucket     = aws_s3_object.backend_object.bucket
  s3_key        = aws_s3_object.backend_object.key
  publish       = true
  vpc_config {
    # Use the same VPC and security group as the RDS database for connectivity
    security_group_ids = [data.terraform_remote_state.cc_db_state.outputs.db_security_group_id]
    subnet_ids         = data.terraform_remote_state.cc_db_state.outputs.db_subnet_ids
  }
  environment {
    variables = merge(
      var.cc_main_compute_env_vars,
      data.terraform_remote_state.cc_common_state.outputs.cc_sensitive_env_variables_name,
      data.terraform_remote_state.cc_db_state.outputs.sensitive_params,
      {
        AWS_S3_BUCKET                       = data.terraform_remote_state.cc_common_state.outputs.internal_s3_bucket
        AWS_S3_BASE_URL                     = "https://${data.terraform_remote_state.cc_common_state.outputs.internal_s3_bucket}.s3.us-east-1.amazonaws.com"
        CC_APP_ROLE                         = "${data.terraform_remote_state.cc_common_state.outputs.cc_app_role_info.arn}"
        APP_FRONTEND_BASE_URL               = "https://${data.terraform_remote_state.cc_common_state.outputs.amplify_url}"
        BASE_URL                            = "${data.terraform_remote_state.cc_common_state.outputs.main_api_endpoint}"
        CORS_ALLOWED_LIST                   = "${var.cors_allowed_list},https://${data.terraform_remote_state.cc_common_state.outputs.amplify_url}"
        # WebSocket endpoint will be updated by null_resource after creation
        AWS_WEBSOCKET_API_GATEWAY_ENDPOINT  = ""
      }
    )
  }
  logging_config {
    log_group  = aws_cloudwatch_log_group.cc_main_lambda_log_group.name
    log_format = "Text"
  }
  snap_start {
    apply_on = "PublishedVersions"
  }
  tags = merge(var.default_tags, { Name = "cc_main_backend" })
  
}

resource "aws_iam_policy" "cc_app_role_policy" {
  name        = "CcApiGatewayLambdaPolicy"
  description = "This policy allows API Gateway to invoke the main backend Lambda function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaActions",
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",
          "lambda:UpdateFunctionCode",
          "lambda:PublishVersion",
        ]
        Resource = [
          "${aws_lambda_function.cc_main_backend_lambda.arn}",
          "${aws_lambda_function.cc_main_backend_lambda.arn}:*",
        ]
      }
    ]
  })
}

# IAM Policy for WebSocket API Gateway Management API
resource "aws_iam_policy" "websocket_management_policy" {
  name        = "CcWebSocketManagementPolicy"
  description = "Allows Lambda to manage WebSocket connections via API Gateway Management API"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowWebSocketManagement",
        Effect = "Allow"
        Action = [
          "execute-api:ManageConnections",
          "execute-api:Invoke"
        ]
        Resource = "arn:aws:execute-api:*:*:*/@connections/*"
      }
    ]
  })
}

# Attach WebSocket Management policy to Lambda execution role
resource "aws_iam_role_policy_attachment" "websocket_management_attach" {
  role       = data.terraform_remote_state.cc_common_state.outputs.cc_app_role_info.name
  policy_arn = aws_iam_policy.websocket_management_policy.arn
}

resource "aws_iam_role_policy_attachment" "cc_app_role_policy_attach" {
  role       = data.terraform_remote_state.cc_common_state.outputs.cc_api_gw_role.name
  policy_arn = aws_iam_policy.cc_app_role_policy.arn
}

resource "aws_apigatewayv2_integration" "main" {
  depends_on           = [aws_iam_role_policy_attachment.cc_app_role_policy_attach]
  api_id               = data.terraform_remote_state.cc_common_state.outputs.main_api_id
  description          = "CC APP Lambda Integration"
  integration_type     = "AWS_PROXY"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.cc_main_backend_lambda.qualified_arn
  credentials_arn      = data.terraform_remote_state.cc_common_state.outputs.cc_api_gw_role.arn
  timeout_milliseconds = 30000
}

resource "aws_apigatewayv2_route" "cc_api_main_proxy" {
  api_id    = data.terraform_remote_state.cc_common_state.outputs.main_api_id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.main.id}"
}

##### WebSocket API Gateway for real-time communication ######
# NOTE: WebSocket module moved here from 2_general to resolve circular dependency
# The Spring Boot backend has all WebSocket logic in AwsWebSocketService
# All three routes ($connect, $disconnect, $default) use the SAME main backend Lambda
module "websocket" {
  source = "../2_general/modules/websocket"

  default_tags = var.default_tags
  stage_name   = "prod"

  # All routes use the SAME main backend Lambda
  # Spring Boot routes internally based on the WebSocket event type
  connect_lambda_function_name    = aws_lambda_function.cc_main_backend_lambda.function_name
  connect_lambda_invoke_arn       = aws_lambda_function.cc_main_backend_lambda.invoke_arn

  disconnect_lambda_function_name = aws_lambda_function.cc_main_backend_lambda.function_name
  disconnect_lambda_invoke_arn    = aws_lambda_function.cc_main_backend_lambda.invoke_arn

  default_lambda_function_name    = aws_lambda_function.cc_main_backend_lambda.function_name
  default_lambda_invoke_arn       = aws_lambda_function.cc_main_backend_lambda.invoke_arn
}

# Update Lambda environment with WebSocket endpoint using AWS CLI
# This breaks the circular dependency by updating the Lambda after both Lambda and WebSocket are created
resource "null_resource" "update_lambda_websocket_env" {
  depends_on = [
    aws_lambda_function.cc_main_backend_lambda,
    module.websocket
  ]

  triggers = {
    websocket_endpoint = module.websocket.websocket_management_endpoint
    lambda_version     = aws_lambda_function.cc_main_backend_lambda.version
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Updating Lambda environment with WebSocket endpoint..."
      aws lambda update-function-configuration \
        --function-name ${aws_lambda_function.cc_main_backend_lambda.function_name} \
        --environment "Variables={$(aws lambda get-function-configuration --function-name ${aws_lambda_function.cc_main_backend_lambda.function_name} --query 'Environment.Variables' --output json | jq -r 'to_entries | map("\\(.key)=\\(.value)") | join(",")'),AWS_WEBSOCKET_API_GATEWAY_ENDPOINT=${module.websocket.websocket_management_endpoint}}" \
        --region us-east-1
      echo "Lambda environment updated with WebSocket endpoint"
    EOT
  }
}

# Create Amplify app
resource "aws_amplify_app" "careconnect" {
  name     = "careconnect-dev"
  platform = "WEB"
}

# Create branch
resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.careconnect.id
  branch_name = "dev"
}


# Trigger Amplify deployment from S3
resource "null_resource" "trigger_amplify_deployment" {
  triggers = {
    archive_md5 = data.archive_file.web_app.output_md5
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Starting Amplify deployment..."
      aws amplify start-deployment \
        --app-id ${aws_amplify_app.careconnect.id} \
        --branch-name ${aws_amplify_branch.main.branch_name} \
        --source-url s3://${var.cc_iac_bucket_name}/${aws_s3_object.frontend_object.key} \
        --region us-east-1 || echo "Deployment failed with error code $?"
      echo "Deployment command completed"
    EOT
  }

  depends_on = [aws_s3_object.frontend_object]
}

module "deployment" {
  source                       = "./modules/deployment"
  default_tags                 = var.default_tags
  cc_app_role_arn              = data.terraform_remote_state.cc_common_state.outputs.cc_app_role_info.arn
  cc_iac_bucket_name           = var.cc_iac_bucket_name
  cc_main_backend_build_prefix = var.cc_main_backend_build_prefix
  cc_lamnda_function_name      = aws_lambda_function.cc_main_backend_lambda.function_name
  cc_main_api_id               = data.terraform_remote_state.cc_common_state.outputs.main_api_id
  cc_deployment_sfn_arn        = data.terraform_remote_state.cc_common_state.outputs.cc_deployment_sfn_arn
  cc_api_integration_id        = aws_apigatewayv2_integration.main.id
  cc_apigw_role_arn            = data.terraform_remote_state.cc_common_state.outputs.cc_api_gw_role.arn
  cc_app_role_name             = data.terraform_remote_state.cc_common_state.outputs.cc_app_role_info.name
  cc_main_backend_lambda_arn   = aws_lambda_function.cc_main_backend_lambda.arn
}
