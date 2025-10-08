resource "aws_ssm_parameter" "this" {
  for_each = { for k, v in var.parameters : k => v if v.value != "" && v.value != null }

  name        = each.key
  description = lookup(each.value, "description", null)
  type        = lookup(each.value, "type", "SecureString")
  value       = each.value.value
  tier        = lookup(each.value, "tier", "Standard")
  key_id      = lookup(each.value, "type", "SecureString") == "SecureString" ? var.kms_key_id : null

  tags = var.tags
}
