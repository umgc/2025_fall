output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC."
  value       = aws_vpc.main.cidr_block
}

output "vpc_arn" {
  description = "The ARN of the VPC."
  value       = aws_vpc.main.arn
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway."
  value       = aws_internet_gateway.main.id
}

output "public_subnet_ids" {
  description = "List of IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of IDs of the private subnets."
  value       = aws_subnet.private[*].id
}

output "public_subnet_cidrs" {
  description = "List of CIDR blocks of the public subnets."
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "List of CIDR blocks of the private subnets."
  value       = aws_subnet.private[*].cidr_block
}

output "public_route_table_id" {
  description = "ID of the public route table."
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table."
  value       = var.create_nat_gateway && length(var.private_subnets) > 0 ? aws_route_table.private[0].id : null
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway."
  value       = var.create_nat_gateway ? aws_nat_gateway.main[0].id : null
}

output "nat_gateway_public_ip" {
  description = "Public IP address of the NAT Gateway."
  value       = var.create_nat_gateway ? aws_eip.nat[0].public_ip : null
}

output "flow_logs_log_group_name" {
  description = "The name of the CloudWatch log group for VPC flow logs."
  value       = aws_cloudwatch_log_group.flow_logs.name
}

output "flow_logs_log_group_arn" {
  description = "The ARN of the CloudWatch log group for VPC flow logs."
  value       = aws_cloudwatch_log_group.flow_logs.arn
}

output "s3_endpoint_id" {
  description = "The ID of the S3 VPC endpoint."
  value       = var.enable_s3_endpoint ? aws_vpc_endpoint.s3[0].id : null
}