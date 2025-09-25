output "cc_db_endpoint" {
  value = aws_db_instance.cc_db.endpoint
}
output "cc_db_port" {
  value = aws_db_instance.cc_db.port
}
output "cc_db_name" {
  value = aws_db_instance.cc_db.db_name
}
output "sensitive_params" {
  value = module.ssm.sensitive_params
  sensitive = true
}
output "db_master_user_secret_arn" {
  value     = aws_rds_cluster.careconnect_db.master_user_secret[0].secret_arn
  sensitive = true
}
output "sensitive_params" {
  value = {
    DB_HOST                = aws_rds_cluster.careconnect_db.endpoint
    DB_PORT                = tostring(aws_rds_cluster.careconnect_db.port)
    DB_NAME                = aws_rds_cluster.careconnect_db.database_name
    DB_PASSWORD_SECRET_ARN = aws_rds_cluster.careconnect_db.master_user_secret[0].secret_arn
  }
  sensitive = true
}