variable "app_name" {
  description = "Name of the Amplify app"
  type        = string
}

variable "repository_url" {
  description = "GitHub repository URL"
  type        = string
}

variable "access_token" {
  description = "GitHub access token"
  type        = string
  sensitive   = true
}

variable "build_spec" {
  description = "Build specification for the Amplify app"
  type        = string
}

variable "environment_variables" {
  description = "Environment variables for the Amplify app"
  type        = map(string)
  default     = {}
}

variable "enable_auto_branch_creation" {
  description = "Enable automatic branch creation"
  type        = bool
  default     = true
}

variable "auto_branch_creation_patterns" {
  description = "Patterns for automatic branch creation"
  type        = list(string)
  default     = ["main", "develop", "feature/*"]
}

variable "auto_branch_creation_config" {
  description = "Configuration for automatic branch creation"
  type = object({
    enable_auto_build     = bool
    environment_variables = map(string)
  })
  default = {
    enable_auto_build     = true
    environment_variables = {}
  }
}

variable "custom_rules" {
  description = "Custom rules for the Amplify app"
  type = list(object({
    source = string
    status = string
    target = string
  }))
  default = [
    {
      source = "/<*>"
      status = "404-200"
      target = "/index.html"
    }
  ]
}

variable "branches" {
  description = "List of branches to create"
  type = list(object({
    branch_name           = string
    environment_variables = map(string)
    enable_webhook        = bool
    webhook_description   = string
  }))
  default = []
}

variable "domain_config" {
  description = "Domain configuration for the Amplify app"
  type = object({
    domain_name = string
    sub_domains = list(object({
      branch_name = string
      prefix      = string
    }))
  })
  default = null
}

variable "enable_basic_auth" {
  description = "Enable basic authentication"
  type        = bool
  default     = false
}

variable "basic_auth_credentials" {
  description = "Basic authentication credentials (base64 encoded)"
  type        = string
  sensitive   = true
}

variable "oauth_token" {
  description = "OAuth token for repository access"
  type        = string
  sensitive   = true
  default     = null
}

variable "enable_branch_auto_build" {
  description = "Enable automatic build for branches"
  type        = bool
  default     = true
}

variable "enable_branch_auto_deletion" {
  description = "Enable automatic deletion of branches"
  type        = bool
  default     = false
}

variable "framework" {
  description = "Framework for the Amplify app"
  type        = string
  default     = "React"
}

variable "stage" {
  description = "Stage for the Amplify app"
  type        = string
  default     = "PRODUCTION"
}

variable "tags" {
  description = "Tags to be added to the Amplify app and related resources"
  type        = map(string)
  default     = {}
}