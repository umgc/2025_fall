# ================================================================
# SECURITY GROUP FOR LAMBDA
# ================================================================

module "api_security_group" {
  source = "./modules/security_group"

  vpc_id        = module.vpc.vpc_id
  name          = "${var.project}-api-sg"
  description   = "Security group for API Lambda function"
  ingress_rules = []
  egress_rules = var.lambda.egress_rules
}

module "api_lambda" {
  count  = var.lambda.enabled ? 1 : 0
  source = "./modules/lambda"

  function_name = var.lambda.function_name
  description   = "API Lambda function"
  runtime       = var.lambda.runtime
  handler       = var.lambda.handler
  timeout       = var.lambda.timeout
  memory_size   = var.lambda.memory_size

  # IAM role configuration
  role_name = "${var.project}-lambda-execution-role"
  policy_arns = concat(
    [
      "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    ],
    var.dsql.create_iam_role ? [module.dsql_cluster.iam_policy_arn] : []
  )

  # S3 source (required for S3-only deployment)
  s3_bucket = var.lambda.s3_bucket
  s3_key    = var.lambda.s3_key

  # Enable publishing
  publish = true

  environment_variables = var.lambda.environment_variables

  vpc_config = {
    subnet_ids         = module.vpc.private_subnet_ids
    security_group_ids = [module.api_security_group.security_group_id]
  }

  log_retention_in_days = 14

  # Function URL configuration
  create_function_url    = true
  function_url_auth_type = var.lambda.function_url_auth_type
  function_url_cors      = var.lambda.function_url_cors

  tags = local.default_tags
}