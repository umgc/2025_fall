output "db_instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.this.id
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.this.arn
}

output "db_instance_endpoint" {
  description = "The connection endpoint"
  value       = aws_db_instance.this.endpoint
}

output "db_instance_address" {
  description = "The hostname of the RDS instance"
  value       = aws_db_instance.this.address
}

output "db_instance_port" {
  description = "The database port"
  value       = aws_db_instance.this.port
}

output "db_instance_name" {
  description = "The database name"
  value       = aws_db_instance.this.db_name
}

output "db_subnet_group_id" {
  description = "The db subnet group name"
  value       = aws_db_subnet_group.this.id
}

output "db_parameter_group_id" {
  description = "The db parameter group id"
  value       = aws_db_parameter_group.this.id
}

output "master_user_secret_arn" {
  description = "The ARN of the master user secret (only available when manage_master_user_password is set to true)"
  value       = var.manage_master_user_password ? aws_db_instance.this.master_user_secret[0].secret_arn : null
}

output "master_user_secret_kms_key_id" {
  description = "The KMS key ID for the master user secret"
  value       = var.manage_master_user_password ? aws_db_instance.this.master_user_secret[0].kms_key_id : null
}
