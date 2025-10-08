locals {
  module_name       = "tf-aws/vpc"
  module_version    = file("${path.module}/RELEASE")
  module_maintainer = "careconnect"
  default_tags = {
    ModuleName       = local.module_name
    ModuleVersion    = local.module_version
    ModuleMaintainer = local.module_maintainer
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(local.default_tags, var.tags, {
    Name = var.vpc_name
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.default_tags, var.tags, {
    Name = "${var.vpc_name}-internet-gateway"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index].cidr
  availability_zone       = var.public_subnets[count.index].availability_zone
  map_public_ip_on_launch = var.public_subnets[count.index].map_public_ip_on_launch

  tags = merge(local.default_tags, var.tags, {
    Name = "${var.vpc_name}-public-subnet-${var.public_subnets[count.index].availability_zone}"
    Type = "Public"
  })
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.default_tags, var.tags, {
    Name = "${var.vpc_name}-public-route-table"
    Type = "Public"
  })
}

# Public Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index].cidr
  availability_zone = var.private_subnets[count.index].availability_zone

  tags = merge(local.default_tags, var.tags, {
    Name = "${var.vpc_name}-private-subnet-${var.private_subnets[count.index].availability_zone}"
    Type = "Private"
  })
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  count = var.create_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = merge(local.default_tags, var.tags, {
    Name = "${var.vpc_name}-nat-eip"
  })

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  count = var.create_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(local.default_tags, var.tags, {
    Name = "${var.vpc_name}-nat-gateway"
  })

  depends_on = [aws_internet_gateway.main]
}

# Private Route Table
resource "aws_route_table" "private" {
  count = var.create_nat_gateway && length(var.private_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id
  }

  tags = merge(local.default_tags, var.tags, {
    Name = "${var.vpc_name}-private-route-table"
    Type = "Private"
  })
}

# Private Route Table Associations
resource "aws_route_table_association" "private" {
  count = var.create_nat_gateway && length(var.private_subnets) > 0 ? length(var.private_subnets) : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

# S3 VPC Endpoint Service Data Source
data "aws_vpc_endpoint_service" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0
  
  service = "s3"
}

# S3 VPC Endpoint
resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0

  vpc_id            = aws_vpc.main.id
  service_name      = data.aws_vpc_endpoint_service.s3[0].service_name
  vpc_endpoint_type = "Gateway"

  tags = merge(local.default_tags, var.tags, {
    Name = "${var.vpc_name}-s3-endpoint"
  })
}

# VPC Flow Logs
resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/flowlogs/${var.vpc_name}"
  retention_in_days = var.vpc_flow_logs_retention_in_days

  tags = merge(local.default_tags, var.tags, {
    Name = "${var.vpc_name}-flow-logs"
  })
  
  # Handle existing log groups gracefully
  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_iam_role" "flow_logs" {
  name = "${var.vpc_name}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.default_tags, var.tags)
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "${var.vpc_name}-flow-logs-policy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "vpc" {
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
  log_format      = var.vpc_flow_logs_log_format

  tags = merge(local.default_tags, var.tags, {
    Name = "${var.vpc_name}-flow-logs"
  })
}

# Data sources
data "aws_region" "current" {}