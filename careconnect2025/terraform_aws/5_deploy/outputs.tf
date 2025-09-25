output "role_arn" {
  description = "IAM role ARN to use in aws-actions/configure-aws-credentials"
  value       = aws_iam_role.github_deploy_role.arn
}

output "bucket_arn" {
  description = "Target S3 bucket ARN"
  value       = local.bucket_arn
}

output "upload_prefix" {
  description = "S3 prefix used for uploads"
  value       = var.s3_prefix
}
