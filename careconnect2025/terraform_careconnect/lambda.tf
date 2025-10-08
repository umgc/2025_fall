module "lambda_security_group" {
  source = "./modules/security_group"

  vpc_id        = module.vpc.vpc_id
  name          = "${var.project}-lambda-sg"
  description   = "Security group for Lambda function"
  ingress_rules = var.lambda.ingress_rules
  egress_rules  = var.lambda.egress_rules
}

module "api_lambda" {
  source = "./modules/lambda"

  function_name = var.lambda.function_name
  description   = "Main API Lambda function for CareConnect"
  runtime       = var.lambda.runtime
  handler       = var.lambda.handler
  timeout       = var.lambda.timeout
  memory_size   = var.lambda.memory_size
  
  # IAM role configuration
  role_name = "${var.project}-lambda-execution-role"
  
  # Attach AWS managed policies
  policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  ]
  
  # Custom policies for S3 and SSM access
  custom_policies = [
    jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject",
            "s3:ListBucket"
          ]
          Resource = [
            module.internal_storage.bucket_arn,
            "${module.internal_storage.bucket_arn}/*"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "ssm:GetParameter",
            "ssm:GetParameters",
            "ssm:GetParametersByPath"
          ]
          Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/${var.project}/${var.environment}/*"
        },
        {
          Effect = "Allow"
          Action = [
            "kms:Decrypt"
          ]
          Resource = "*"
        }
      ]
    })
  ]

  # Use S3 source
  use_s3_source = var.lambda.use_s3_source
  s3_bucket     = var.lambda.s3_bucket
  s3_key        = var.lambda.s3_key
  source_path   = null
  output_path   = null

  # Enable publishing and SnapStart
  publish = true

  environment_variables = merge(
    var.lambda.environment_variables,  # Includes SSM parameter names from prod.tfvars
    {
      # Infrastructure values
      AWS_S3_BUCKET         = module.internal_storage.bucket_id
      AWS_S3_BASE_URL       = "https://${module.internal_storage.bucket_id}.s3.${var.aws_region}.amazonaws.com"
      CC_APP_ROLE           = module.api_lambda.role_arn
      APP_FRONTEND_BASE_URL = "https://${module.frontend_app.default_domain}"
      BASE_URL              = module.main_api.stage_invoke_url
      CORS_ALLOWED_LIST     = join(",", var.lambda.cors_allowed_origins)
    }
  )

  vpc_config = {
    subnet_ids         = module.vpc.private_subnet_ids
    security_group_ids = [module.lambda_security_group.security_group_id]
  }

  log_retention_in_days = 90

  # Disable Function URL (using API Gateway instead)
  create_function_url = false

  tags = local.default_tags
}
