# ================================================================
# API GATEWAY HTTP API
# ================================================================
module "main_api" {
  source = "./modules/api_gateway"

  api_name            = "${var.project}-main-api"
  protocol_type       = "HTTP"
  description         = "Main API Gateway for CareConnect"
  stage_name          = "$default"
  auto_deploy         = true
  create_log_group    = true
  log_retention_days  = 60
  cors_configuration = {
    allow_credentials = true
    allow_headers     = ["*"]
    allow_methods     = ["*"]
    allow_origins     = ["http://*", "https://*"]
    expose_headers    = ["*"]
    max_age           = 360
  }

  lambda_integrations = {
    main = {
      lambda_function_name = module.api_lambda.function_name
      lambda_invoke_arn    = module.api_lambda.function_arn
      route_key            = "ANY /{proxy+}"
    }
  }

  tags = local.default_tags
}
