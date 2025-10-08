output "parameter_arns" {
  description = "ARNs of created SSM parameters"
  value       = { for k, v in aws_ssm_parameter.this : k => v.arn }
}

output "parameter_names" {
  description = "Names of created SSM parameters"
  value       = { for k, v in aws_ssm_parameter.this : k => v.name }
}
