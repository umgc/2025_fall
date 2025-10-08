output "app_id" {
  description = "ID of the Amplify app"
  value       = aws_amplify_app.this.id
}

output "app_arn" {
  description = "ARN of the Amplify app"
  value       = aws_amplify_app.this.arn
}

output "app_name" {
  description = "Name of the Amplify app"
  value       = aws_amplify_app.this.name
}

output "default_domain" {
  description = "Default domain of the Amplify app"
  value       = aws_amplify_app.this.default_domain
}

output "repository" {
  description = "Repository URL of the Amplify app"
  value       = aws_amplify_app.this.repository
}

output "production_branch" {
  description = "Production branch of the Amplify app"
  value       = aws_amplify_app.this.production_branch
}

output "branch_names" {
  description = "Names of the created branches"
  value       = aws_amplify_branch.branches[*].branch_name
}

output "branch_arns" {
  description = "ARNs of the created branches"
  value       = aws_amplify_branch.branches[*].arn
}

output "branch_urls" {
  description = "URLs of the created branches"
  value = [
    for branch in aws_amplify_branch.branches :
    "https://${branch.branch_name}.${aws_amplify_app.this.default_domain}"
  ]
}

output "webhook_urls" {
  description = "Webhook URLs for the branches"
  value       = aws_amplify_webhook.branch_webhooks[*].url
}

output "domain_association_arn" {
  description = "ARN of the domain association"
  value       = var.domain_config != null ? aws_amplify_domain_association.domain[0].arn : null
}

output "domain_association_certificate_verification_dns_record" {
  description = "DNS record for domain verification"
  value       = var.domain_config != null ? aws_amplify_domain_association.domain[0].certificate_verification_dns_record : null
}

output "sub_domain_urls" {
  description = "URLs of the sub domains"
  value = var.domain_config != null ? [
    for sub_domain in aws_amplify_domain_association.domain[0].sub_domain :
    "https://${sub_domain.prefix != "" ? "${sub_domain.prefix}." : ""}${var.domain_config.domain_name}"
  ] : []
}

output "app_url" {
  description = "Main URL of the Amplify app"
  value       = "https://${aws_amplify_app.this.default_domain}"
}
