variable "vpc_id" {
  description = "The ID of the VPC where the security group will be created."
  type        = string
}

variable "description" {
  description = "A description of the security group being created."
  type        = string
}

variable "name" {
  description = "The name to assign to the security group."
  type        = string
}

variable "ingress_rules" {
  description = <<-EOT
    A list of ingress rules to allow inbound traffic to the security group.
    Each rule includes ports, protocols, and source CIDRs or security groups.
  EOT
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string), [])
    security_groups = optional(list(string), [])
    prefix_list_ids = optional(list(string), [])
  }))
  default = []
}

variable "egress_rules" {
  description = <<-EOT
    A list of egress rules to allow outbound traffic from the security group.
    Each rule includes ports, protocols, and destination CIDRs or security groups.
  EOT
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string), [])
    security_groups = optional(list(string), [])
  }))
  default = [
    {
      description     = "Allow all outbound traffic"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  ]
}

variable "tags" {
  description = "Tags to be added to the provisioned security group."
  type        = map(string)
  default     = {}
}