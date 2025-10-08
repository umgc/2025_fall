variable "vpc_cidr" {
  description = "The CIDR block to assign to the VPC."
  type        = string
}

variable "vpc_name" {
  description = "The name to assign to the VPC."
  type        = string
}

variable "enable_dns_support" {
  description = "Indicates whether DNS support is enabled for the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Indicates whether DNS hostnames are enabled for the VPC."
  type        = bool
  default     = true
}

variable "public_subnets" {
  description = "A list of public subnets with CIDR blocks, availability zones, and mapping options for public IPs."
  type = list(object({
    cidr                    = string
    availability_zone       = string
    map_public_ip_on_launch = bool
  }))
  default = []
}

variable "private_subnets" {
  description = "A list of private subnets with CIDR blocks and availability zones."
  type = list(object({
    cidr              = string
    availability_zone = string
  }))
  default = []
}

variable "create_nat_gateway" {
  description = "Whether to create a NAT gateway for private subnets."
  type        = bool
  default     = false
}

variable "enable_s3_endpoint" {
  description = "Whether to create a VPC endpoint for S3."
  type        = bool
  default     = false
}

variable "vpc_flow_logs_retention_in_days" {
  description = "The number of days to retain VPC flow log events in the specified log group."
  type        = number
  default     = 90
}

variable "vpc_flow_logs_log_format" {
  description = "The format of the VPC flow log records, specifying the fields to include."
  type        = string
  default     = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status}"
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}