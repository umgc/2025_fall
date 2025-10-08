output "role_arn" {
  description = "ARN of the IAM role"
  value       = var.create_role ? aws_iam_role.this[0].arn : null
}

output "role_name" {
  description = "Name of the IAM role"
  value       = var.create_role ? aws_iam_role.this[0].name : null
}

output "role_id" {
  description = "ID of the IAM role"
  value       = var.create_role ? aws_iam_role.this[0].id : null
}

output "policy_arns" {
  description = "ARNs of created IAM policies"
  value       = { for k, v in aws_iam_policy.this : k => v.arn }
}