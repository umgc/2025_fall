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
  }
   sensitive = false //how do i get it, if it is sensitive ??
}
