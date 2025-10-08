variable "name" {
  description = "Name prefix for the EC2 instance and related resources"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "ami_id" {
  description = "AMI ID to use for the instance"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs to associate with the instance"
  type        = list(string)
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with the instance"
  type        = bool
  default     = true
}

variable "monitoring" {
  description = "Enable detailed monitoring for the instance"
  type        = bool
  default     = true
}

variable "user_data" {
  description = "User data script to run on instance startup"
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Type of the root volume"
  type        = string
  default     = "gp3"
}

variable "root_volume_encrypted" {
  description = "Whether to encrypt the root volume"
  type        = bool
  default     = true
}

variable "root_volume_throughput" {
  description = "Throughput for gp3 volumes"
  type        = number
  default     = 125
}

variable "root_volume_iops" {
  description = "IOPS for gp3 volumes"
  type        = number
  default     = 3000
}

variable "create_key_pair" {
  description = "Whether to create a new key pair for the instance"
  type        = bool
  default     = true
}

variable "key_name" {
  description = "Name of the key pair to use"
  type        = string
}

variable "ssh_key_output_path" {
  description = "Path where to save the private SSH key file"
  type        = string
  default     = ".ssh"
}

variable "project" {
  description = "Project name for user data template"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name for user data template"
  type        = string
  default     = ""
}

variable "user_data_template_path" {
  description = "Path to user data template file"
  type        = string
  default     = ""
}

variable "service" {
  description = "Service name for tagging and identification"
  type        = string
  default     = "app"
}

variable "create_elastic_ip" {
  description = "Whether to create and associate an Elastic IP with the instance"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to be added to the EC2 instance and related resources"
  type        = map(string)
  default     = {}
}