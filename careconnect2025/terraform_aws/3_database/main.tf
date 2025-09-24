# 1. Networking Setup
# A dedicated VPC for the database
resource "aws_vpc" "aurora_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "aurora-vpc"
  }
}

# At least two subnets in different Availability Zones are required
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
  
  # NOTE: Aurora engine versions are specific. '16.2' is compatible with PostgreSQL 16.
  # The version you specified, '16.6', is not a valid Aurora engine version.
  engine_version     = "16.2"
  
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
    min_capacity = 0.5
    max_capacity = 2.0
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