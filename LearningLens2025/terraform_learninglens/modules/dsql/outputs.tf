# ================================================================================
# DSQL Module Outputs
# ================================================================================

output "cluster_id" {
  description = "The ID of the DSQL cluster"
  value       = aws_dsql_cluster.main.identifier
}

output "cluster_arn" {
  description = "The ARN of the DSQL cluster"
  value       = aws_dsql_cluster.main.arn
}

output "cluster_endpoint" {
  description = "The endpoint of the DSQL cluster"
  value       = format("%s.dsql.%s.on.aws", aws_dsql_cluster.main.identifier, data.aws_region.current.id)
}

output "iam_role_arn" {
  description = "The ARN of the IAM role for DSQL access"
  value       = var.create_iam_role ? module.dsql_iam_role[0].role_arn : null
}

output "iam_role_name" {
  description = "The name of the IAM role for DSQL access"
  value       = var.create_iam_role ? module.dsql_iam_role[0].role_name : null
}

output "iam_policy_arn" {
  description = "The ARN of the IAM policy for DSQL access"
  value       = var.create_iam_role ? module.dsql_iam_role[0].policy_arns["dsql_policy"] : null
}