
output "main_api_endpoint" {
  value = module.main_api.cc_man_api_endpoint
}
output "main_api_id" {
  value = module.main_api.cc_man_api_id
}
output "cc_api_gw_role" {
  value = module.iam.cc_api_gw_role
}
output "cc_app_role_info" {
  value = module.iam.cc_app_role_info
}
output "cc_compute_sg_id" {
  value = module.vpc.cc_compute_sg_id
}
output "cc_rds_sg_id" {
  value = module.vpc.cc_rds_sg_id
}
output "cc_main_sbn_group_name" {
  value = module.vpc.cc_main_sbn_group_name
}
output "cc_sbn_ids" {
  value = module.vpc.cc_subnet_ids
}
output "amplify_url" {
  value = replace(module.amplify.amplify_branch_url, "/", ".")
}
output "cc_sensitive_env_variables_name" {
  value = {
    for key in local.params_keys : key => module.ssm.sensitive_params[key].name
  }
  sensitive = true
}
output "cc_deployment_sfn_arn" {
  value = module.sfn_sm.cc_deployment_sfn_arn
}
output "internal_s3_bucket" {
  value = module.s3_internal.internal_s3_bucket.bucket
}
output "ses_dkim_cname_records" {
  description = "The CNAME records to add to your DNS provider (Namecheap) for DKIM verification."
  value = {
    for token in aws_ses_domain_dkim.ses_domain_dkim.dkim_tokens :
    "${token}._domainkey.${var.domain_name}" => "${token}.dkim.amazonses.com"
  }
}

output "websocket_management_endpoint" {
  description = "WebSocket API Gateway Management API endpoint for Lambda to send messages"
  value       = module.websocket.websocket_management_endpoint
}

output "websocket_api_endpoint" {
  description = "WebSocket API endpoint URL for client connections"
  value       = module.websocket.websocket_stage_invoke_url
}