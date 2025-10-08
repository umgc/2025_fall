# ================================================================
# API GATEWAY HTTP API
# ================================================================
module "main_api" {
  source = "./modules/api_gateway"

  api_name            = var.api_gateway.api_name
  protocol_type       = var.api_gateway.protocol_type
  description         = var.api_gateway.description
  stage_name          = var.api_gateway.stage_name
  auto_deploy         = var.api_gateway.auto_deploy
  create_log_group    = var.api_gateway.create_log_group
  log_retention_days  = var.api_gateway.log_retention_days
  cors_configuration  = var.api_gateway.cors_configuration

  lambda_integrations = var.lambda.enabled ? {
    main = {
      lambda_function_name   = module.api_lambda[0].function_name
      lambda_invoke_arn      = module.api_lambda[0].function_arn
      route_key              = "ANY /{proxy+}"
      payload_format_version = var.api_gateway.payload_format_version
    }
  } : {}

  tags = local.default_tags
}
