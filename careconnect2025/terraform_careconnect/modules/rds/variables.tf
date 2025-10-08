variable "identifier" {
  description = "The name of the RDS instance"
  type        = string
}

variable "engine" {
  description = "The database engine to use"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "The engine version to use"
  type        = string
}

variable "instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
}

variable "allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = number
}

variable "max_allocated_storage" {
  description = "The upper limit to which Amazon RDS can automatically scale the storage"
  type        = number
  default     = 0
}

variable "storage_type" {
  description = "One of standard, gp2, gp3, or io1"
  type        = string
  default     = "gp3"
}

variable "iops" {
  description = "The amount of provisioned IOPS"
  type        = number
  default     = null
}

variable "storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted"
  type        = bool
  default     = true
}

variable "db_name" {
  description = "The name of the database to create when the DB instance is created"
  type        = string
}

variable "username" {
  description = "Username for the master DB user"
  type        = string
  sensitive   = true
}

variable "password" {
  description = "Password for the master DB user (not required if manage_master_user_password is true)"
  type        = string
  sensitive   = true
  default     = null
}

variable "manage_master_user_password" {
  description = "Set to true to allow RDS to manage the master user password in Secrets Manager"
  type        = bool
  default     = false
}

variable "port" {
  description = "The port on which the DB accepts connections"
  type        = number
  default     = 5432
}

variable "subnet_ids" {
  description = "A list of VPC subnet IDs"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "List of VPC security groups to associate"
  type        = list(string)
}

variable "publicly_accessible" {
  description = "Bool to control if instance is publicly accessible"
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "The days to retain backups for"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "The daily time range during which automated backups are created"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "The window to perform maintenance in"
  type        = string
  default     = "mon:04:00-mon:05:00"
}

variable "deletion_protection" {
  description = "If the DB instance should have deletion protection enabled"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted"
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "The name of your final DB snapshot when this DB instance is deleted"
  type        = string
  default     = null
}

variable "parameter_group_family" {
  description = "The family of the DB parameter group"
  type        = string
  default     = "postgres16"
}

variable "parameters" {
  description = "A list of DB parameters to apply"
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string)
  }))
  default = []
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to enable for exporting to CloudWatch logs"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
