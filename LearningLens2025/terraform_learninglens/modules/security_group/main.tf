locals {
  module_name       = "tf-aws/security-group"
  module_version    = file("${path.module}/RELEASE")
  module_maintainer = "learninglens"
  default_tags = {
    ModuleName       = local.module_name
    ModuleVersion    = local.module_version
    ModuleMaintainer = local.module_maintainer
  }
}

resource "aws_security_group" "this" {
  name        = var.name
  vpc_id      = var.vpc_id
  description = var.description

  dynamic "ingress" {
    for_each = var.ingress_rules
    iterator = item

    content {
      description     = item.value.description
      from_port       = item.value.from_port
      to_port         = item.value.to_port
      protocol        = item.value.protocol
      prefix_list_ids = length(item.value.prefix_list_ids) > 0 ? item.value.prefix_list_ids : null
      cidr_blocks     = length(item.value.cidr_blocks) > 0 ? item.value.cidr_blocks : null
      security_groups = length(item.value.security_groups) > 0 ? item.value.security_groups : null
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    iterator = item

    content {
      description     = item.value.description
      from_port       = item.value.from_port
      to_port         = item.value.to_port
      protocol        = item.value.protocol
      cidr_blocks     = length(item.value.cidr_blocks) > 0 ? item.value.cidr_blocks : null
      security_groups = length(item.value.security_groups) > 0 ? item.value.security_groups : null
    }
  }

  tags = merge(local.default_tags, var.tags, {
    Name = var.name
  })
}