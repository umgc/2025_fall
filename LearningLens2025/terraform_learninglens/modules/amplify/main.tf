locals {
  module_name       = "tf-aws/amplify"
  module_version    = file("${path.module}/RELEASE")
  module_maintainer = "learninglens"
  default_tags = {
    ModuleName       = local.module_name
    ModuleVersion    = local.module_version
    ModuleMaintainer = local.module_maintainer
  }
}

# Amplify App
resource "aws_amplify_app" "this" {
  name         = var.app_name
  repository   = var.repository_url
  access_token = var.access_token

  build_spec = var.build_spec

  environment_variables = var.environment_variables

  # Custom rules
  dynamic "custom_rule" {
    for_each = var.custom_rules
    content {
      source = custom_rule.value.source
      status = custom_rule.value.status
      target = custom_rule.value.target
    }
  }

  # Auto branch creation
  enable_auto_branch_creation   = var.enable_auto_branch_creation
  auto_branch_creation_patterns = var.auto_branch_creation_patterns

  dynamic "auto_branch_creation_config" {
    for_each = var.enable_auto_branch_creation ? [var.auto_branch_creation_config] : []
    content {
      enable_auto_build     = var.enable_branch_auto_build
      environment_variables = auto_branch_creation_config.value.environment_variables
      framework             = var.framework
      stage                 = var.stage
      enable_basic_auth     = var.enable_basic_auth
      basic_auth_credentials = var.enable_basic_auth && var.basic_auth_credentials != "" ? var.basic_auth_credentials : null
    }
  }

  # Basic authentication
  enable_basic_auth      = var.enable_basic_auth
  basic_auth_credentials = var.enable_basic_auth && var.basic_auth_credentials != "" ? var.basic_auth_credentials : null

  # Branch settings
  enable_branch_auto_build    = var.enable_branch_auto_build
  enable_branch_auto_deletion = var.enable_branch_auto_deletion

  tags = merge(local.default_tags, var.tags, {
    Name = var.app_name
  })
}

# Amplify Branches
resource "aws_amplify_branch" "branches" {
  count       = length(var.branches)
  app_id      = aws_amplify_app.this.id
  branch_name = var.branches[count.index].branch_name

  environment_variables = var.branches[count.index].environment_variables

  enable_auto_build = var.enable_branch_auto_build
  framework         = var.framework
  stage             = var.stage

  tags = merge(local.default_tags, var.tags, {
    Name   = "${var.app_name}-${var.branches[count.index].branch_name}"
    Branch = var.branches[count.index].branch_name
  })
}

# Webhooks for branches
resource "aws_amplify_webhook" "branch_webhooks" {
  count       = length([for branch in var.branches : branch if branch.enable_webhook])
  app_id      = aws_amplify_app.this.id
  branch_name = aws_amplify_branch.branches[count.index].branch_name
  description = var.branches[count.index].webhook_description
}

# Domain association (optional)
resource "aws_amplify_domain_association" "domain" {
  count       = var.domain_config != null ? 1 : 0
  app_id      = aws_amplify_app.this.id
  domain_name = var.domain_config.domain_name

  dynamic "sub_domain" {
    for_each = var.domain_config.sub_domains
    content {
      branch_name = sub_domain.value.branch_name
      prefix      = sub_domain.value.prefix
    }
  }

  depends_on = [aws_amplify_branch.branches]
}
