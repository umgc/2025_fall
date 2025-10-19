output "db_cluster_endpoint" {
  description = "The connection endpoint for the Aurora cluster."
  value       = aws_rds_cluster.careconnect_db.endpoint
}

output "db_cluster_port" {
  description = "The port for the Aurora cluster."
  value       = aws_rds_cluster.careconnect_db.port
}

output "db_cluster_name" {
  description = "The database name within the Aurora cluster."
  value       = aws_rds_cluster.careconnect_db.database_name
}

 
output "db_master_user_secret_arn" {
  description = "The database name secret."
  value     = try(one(aws_rds_cluster.careconnect_db.master_user_secret).secret_arn, null)
  sensitive = false
} 
 
output "sensitive_params" {
  value = {
    DB_HOST                = aws_rds_cluster.careconnect_db.endpoint
    DB_PORT                = tostring(aws_rds_cluster.careconnect_db.port)
    DB_NAME                = aws_rds_cluster.careconnect_db.database_name
    DB_PASSWORD_SECRET_ARN = try(one(aws_rds_cluster.careconnect_db.master_user_secret).secret_arn, null)
    JDBC_URI               = "jdbc:postgresql://${aws_rds_cluster.careconnect_db.endpoint}:${aws_rds_cluster.careconnect_db.port}/${aws_rds_cluster.careconnect_db.database_name}"
    DB_USER                = var.rds_username
  }
  sensitive = true
}

output "db_security_group_id" {
  description = "The ID of the database security group"
  value       = aws_security_group.aurora_sg.id
}

output "db_subnet_ids" {
  description = "The IDs of the database subnets"
  value       = [aws_subnet.aurora_subnet_a.id, aws_subnet.aurora_subnet_b.id]
}
