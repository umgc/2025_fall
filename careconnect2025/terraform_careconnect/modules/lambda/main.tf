locals {
  module_name       = "tf-aws/lambda"
  module_version    = file("${path.module}/RELEASE")
  module_maintainer = "careconnect"
  default_tags = {
    ModuleName       = local.module_name
    ModuleVersion    = local.module_version
    ModuleMaintainer = local.module_maintainer
  }
}

# ================================================================
# LAMBDA FUNCTION URL
# ================================================================
resource "aws_lambda_function_url" "function_url" {
  count              = var.create_function_url ? 1 : 0
  function_name      = aws_lambda_function.this.function_name
  authorization_type = var.function_url_auth_type

  dynamic "cors" {
    for_each = var.function_url_cors != null ? [var.function_url_cors] : []
    content {
      allow_credentials = cors.value.allow_credentials
      allow_origins     = cors.value.allow_origins
      allow_methods     = cors.value.allow_methods
      allow_headers     = cors.value.allow_headers
      expose_headers    = cors.value.expose_headers
      max_age          = cors.value.max_age
    }
  }
}

# ================================================================
# IAM ROLE AND POLICIES
# ================================================================
resource "aws_iam_role" "lambda_role" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.default_tags, var.tags)
}

# Attach managed policies to the role
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  count      = length(var.policy_arns)
  role       = aws_iam_role.lambda_role.name
  policy_arn = var.policy_arns[count.index]
}

# Attach custom policies to the role
resource "aws_iam_role_policy" "lambda_custom_policy" {
  count  = length(var.custom_policies)
  name   = "${var.role_name}-custom-policy-${count.index}"
  role   = aws_iam_role.lambda_role.id
  policy = var.custom_policies[count.index]
}

# VPC policy attachment (if VPC config is provided)
resource "aws_iam_role_policy_attachment" "lambda_vpc_policy" {
  count      = var.vpc_config != null ? 1 : 0
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# ================================================================
# LAMBDA FUNCTION
# ================================================================
resource "aws_lambda_function" "this" {
  # S3 source configuration
  s3_bucket = var.s3_bucket
  s3_key    = var.s3_key
  
  function_name                  = var.function_name
  role                          = aws_iam_role.lambda_role.arn
  handler                       = var.handler
  runtime                       = var.runtime
  timeout                       = var.timeout
  memory_size                   = var.memory_size
  reserved_concurrent_executions = var.reserved_concurrent_executions
  publish                       = var.publish
  layers                        = var.layers
  description                   = var.description

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  dynamic "dead_letter_config" {
    for_each = var.dead_letter_config != null ? [var.dead_letter_config] : []
    content {
      target_arn = dead_letter_config.value.target_arn
    }
  }

  dynamic "tracing_config" {
    for_each = [var.tracing_config]
    content {
      mode = tracing_config.value.mode
    }
  }

  dynamic "snap_start" {
    for_each = var.runtime == "java17" && var.enable_snap_start ? [1] : []
    content {
      apply_on = "PublishedVersions"
    }
  }

  tags = merge(local.default_tags, var.tags)

  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy,
    aws_iam_role_policy.lambda_custom_policy,
    aws_cloudwatch_log_group.lambda_log_group,
  ]
}

# ================================================================
# CLOUDWATCH LOG GROUP
# ================================================================
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  count             = var.create_log_group ? 1 : 0
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_in_days

  tags = merge(local.default_tags, var.tags)
}