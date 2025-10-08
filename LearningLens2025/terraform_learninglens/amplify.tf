# ================================================================
# AMPLIFY FRONTEND APPLICATION
# ================================================================
module "frontend_app" {
  source = "./modules/amplify"

  app_name       = var.frontend.app_name
  repository_url = var.frontend.repository
  access_token   = var.github_token
  build_spec     = var.frontend.build_spec
  framework      = var.frontend.framework

  environment_variables = merge(
    var.frontend.environment_variables,
    fileexists("${path.module}/${var.frontend.env_file_path}") ? {
      for line in compact(split("\n", file("${path.module}/${var.frontend.env_file_path}"))) :
      trimspace(split("=", line)[0]) => trimspace(join("=", slice(split("=", line), 1, length(split("=", line)))))
      if length(regexall("^[^#].*=.*", trimspace(line))) > 0
    } : {}
  )

  # Branch configuration
  branches = [
    {
      branch_name = var.frontend.branch_name
      environment_variables = merge(
        var.frontend.environment_variables,
        fileexists("${path.module}/${var.frontend.env_file_path}") ? {
          for line in compact(split("\n", file("${path.module}/${var.frontend.env_file_path}"))) :
          trimspace(split("=", line)[0]) => trimspace(join("=", slice(split("=", line), 1, length(split("=", line)))))
          if length(regexall("^[^#].*=.*", trimspace(line))) > 0
        } : {}
      )
      enable_webhook      = var.frontend.enable_webhook
      webhook_description = "Auto deployment webhook for ${var.frontend.branch_name} branch"
    }
  ]

  # Basic authentication
  enable_basic_auth      = var.amplify_basic_auth_credentials != "" ? true : false
  basic_auth_credentials = var.amplify_basic_auth_credentials

  # Domain configuration (set to null if not using custom domain)
  domain_config = null

  tags = local.default_tags
}
