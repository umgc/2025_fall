output "github_actions_role_arn" {
  description = "The ARN of the IAM role for GitHub Actions. Set this as the AWS_ROLE_ARN secret in your GitHub repository."
  value       = aws_iam_role.github_actions_role.arn
}
