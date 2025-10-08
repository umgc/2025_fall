output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.this.arn
}

output "instance_state" {
  description = "State of the EC2 instance"
  value       = aws_instance.this.instance_state
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.this.public_ip
}

output "private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.this.private_ip
}

output "public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.this.public_dns
}

output "private_dns" {
  description = "Private DNS name of the EC2 instance"
  value       = aws_instance.this.private_dns
}

output "availability_zone" {
  description = "Availability zone of the EC2 instance"
  value       = aws_instance.this.availability_zone
}

output "subnet_id" {
  description = "Subnet ID of the EC2 instance"
  value       = aws_instance.this.subnet_id
}

output "vpc_security_group_ids" {
  description = "Security group IDs associated with the EC2 instance"
  value       = aws_instance.this.vpc_security_group_ids
}

output "key_name" {
  description = "Key pair name used by the EC2 instance"
  value       = aws_instance.this.key_name
}

output "ami_id" {
  description = "AMI ID used by the EC2 instance"
  value       = aws_instance.this.ami
}

output "instance_type" {
  description = "Instance type of the EC2 instance"
  value       = aws_instance.this.instance_type
}

output "root_block_device" {
  description = "Root block device information"
  value       = aws_instance.this.root_block_device
}

output "ssh_private_key_pem" {
  description = "Private SSH key in PEM format (sensitive)"
  value       = var.create_key_pair ? tls_private_key.this[0].private_key_pem : null
  sensitive   = true
}

output "ssh_public_key" {
  description = "Public SSH key"
  value       = var.create_key_pair ? tls_private_key.this[0].public_key_openssh : null
}

output "ssh_key_file_path" {
  description = "Path to the private SSH key file"
  value       = var.create_key_pair ? "${var.ssh_key_output_path}/${var.key_name}.pem" : null
}

output "elastic_ip" {
  description = "Elastic IP address associated with the instance"
  value       = var.create_elastic_ip ? aws_eip.this[0].public_ip : null
}

output "elastic_ip_allocation_id" {
  description = "Allocation ID of the Elastic IP"
  value       = var.create_elastic_ip ? aws_eip.this[0].id : null
}