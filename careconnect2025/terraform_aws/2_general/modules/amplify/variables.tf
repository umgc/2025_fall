variable "default_tags" {
  type = map(any)
}
variable "primary_region" {
  type = string
}
variable "github_repo" {
  description = "GitHub repo HTTPS URL (e.g., https://github.com/umgc/summer2025)"
  type        = string
  default     = "https://github.com/umgc/2025_fall"
}
variable "github_branch" {
  description = "The branch name to connect to Amplify"
  default     = "developer"
}
variable "cc_app_role_arn" {
  type        = string
  description = "The compute role ARN to access AWS services"
}