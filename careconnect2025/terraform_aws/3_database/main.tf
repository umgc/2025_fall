# 1. Networking Setup
# A dedicated VPC for the database
resource "aws_vpc" "aurora_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "aurora-vpc"
  }
}

# Subnets in different Availability Zones 
resource "aws_subnet" "aurora_subnet_a" {
  vpc_id            = aws_vpc.aurora_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "aurora-subnet-a"
  }
}

resource "aws_subnet" "aurora_subnet_b" {
  vpc_id            = aws_vpc.aurora_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = "aurora-subnet-b"
  }
}

# Create explicit route table for private subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.aurora_vpc.id

  tags = {
    Name = "aurora-private-route-table"
  }
}

# Associate route table with subnet A
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.aurora_subnet_a.id
  route_table_id = aws_route_table.private.id
}

# Associate route table with subnet B
resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.aurora_subnet_b.id
  route_table_id = aws_route_table.private.id
}

# A subnet group for the Aurora cluster
resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "careconnect-subnet-group"
  subnet_ids = [aws_subnet.aurora_subnet_a.id, aws_subnet.aurora_subnet_b.id]

  tags = {
    Name = "CareConnect Subnet Group"
  }
}

# A security group to control access to the database
resource "aws_security_group" "aurora_sg" {
  name        = "aurora-careconnect-sg"
  description = "Allow PostgreSQL inbound traffic"
  vpc_id      = aws_vpc.aurora_vpc.id

  # Allow inbound traffic on the PostgreSQL port from within the VPC
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.aurora_vpc.cidr_block]
  }

  # Allow inbound traffic from resources within the same security group (Lambda)
  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    self      = true
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aurora-sg"
  }
}


# 2. Aurora Serverless v2 Cluster
resource "aws_rds_cluster" "careconnect_db" {
  cluster_identifier = "careconnect"
  engine             = "aurora-postgresql"
  
  # NOTE: Aurora engine versions are specific for auto-puase, the database engine must be running at least version 16.3, 15.7, 14.12, or 13.15.
 
  engine_version     = "16.3"
  
  database_name    = "careconnect"
  master_username  = var.rds_username
  #master_password  = var.rds_password
  manage_master_user_password = true  # aws will generate this
  # Enable IAM Database Authentication
  iam_database_authentication_enabled = true
  
  # Networking
  db_subnet_group_name   = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids = [aws_security_group.aurora_sg.id]

  # Serverless v2 Scaling Configuration
  # NOTE: The minimum capacity for Serverless v2 is 0.5 ACUs, not 0.
  serverlessv2_scaling_configuration {
    min_capacity = 0
    max_capacity = 1.0
  }

  # Configuration for Dev/Test Environment
  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Project     = "CareConnect"
    Environment = "Dev"
  }
}

# At least one instance is required for the cluster
resource "aws_rds_cluster_instance" "careconnect_db_instance" {
  cluster_identifier = aws_rds_cluster.careconnect_db.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.careconnect_db.engine
  engine_version     = aws_rds_cluster.careconnect_db.engine_version
}

# VPC Endpoints for Lambda to access AWS services from private VPC
# This allows Lambda in the database VPC to access AWS services without internet gateway

# Security group for VPC endpoints
resource "aws_security_group" "vpc_endpoints_sg" {
  name        = "vpc-endpoints-sg"
  description = "Allow HTTPS inbound for VPC endpoints"
  vpc_id      = aws_vpc.aurora_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.aurora_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpc-endpoints-sg"
  }
}

# SSM Parameter Store endpoint
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.aurora_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.aurora_subnet_a.id, aws_subnet.aurora_subnet_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoints_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "ssm-endpoint"
  }
}

# Secrets Manager endpoint
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.aurora_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.aurora_subnet_a.id, aws_subnet.aurora_subnet_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoints_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "secretsmanager-endpoint"
  }
}

# S3 endpoint (Gateway type - no additional charges)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.aurora_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name = "s3-endpoint"
  }
}