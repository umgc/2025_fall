# CareConnect 2025 Deployment and Operations Guide

## Table of Contents

1. [Infrastructure Overview](#infrastructure-overview)
2. [Environment Setup](#environment-setup)
3. [AWS Infrastructure Deployment](#aws-infrastructure-deployment)
4. [Application Deployment](#application-deployment)
5. [Database Management](#database-management)
6. [CI/CD Pipeline](#cicd-pipeline)
7. [Monitoring and Logging](#monitoring-and-logging)
8. [Security and Compliance](#security-and-compliance)
9. [Backup and Disaster Recovery](#backup-and-disaster-recovery)
10. [Performance Optimization](#performance-optimization)
11. [Scaling Strategies](#scaling-strategies)
12. [Maintenance Procedures](#maintenance-procedures)
13. [Troubleshooting](#troubleshooting)
14. [Security Incident Response](#security-incident-response)
15. [Compliance and Auditing](#compliance-and-auditing)

## Infrastructure Overview

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                           Internet                                   │
└─────────────────────────┬───────────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────────┐
│                    Route 53 (DNS)                                   │
└─────────────────────────┬───────────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────────┐
│                   CloudFront CDN                                     │
└─────────────────────────┬───────────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────────┐
│                 Application Load Balancer                           │
└─────────────────────────┬───────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
┌───────▼────┐    ┌──────▼──────┐    ┌─────▼──────┐
│   Web App  │    │   Backend   │    │   Admin    │
│   (S3 +    │    │   (ECS +    │    │   Portal   │
│ CloudFront)│    │  Fargate)   │    │   (EC2)    │
└────────────┘    └─────────────┘    └────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
┌───────▼────┐    ┌──────▼──────┐    ┌─────▼──────┐
│    RDS     │    │  ElastiCache│    │   Lambda   │
│   MySQL    │    │    Redis    │    │ Functions  │
└────────────┘    └─────────────┘    └────────────┘
        │
┌───────▼────┐
│     S3     │
│  File      │
│ Storage    │
└────────────┘
```

### Technology Stack

**Infrastructure:**
- **Cloud Provider**: Amazon Web Services (AWS)
- **Infrastructure as Code**: Terraform
- **Container Orchestration**: ECS with Fargate
- **Load Balancer**: Application Load Balancer (ALB)
- **CDN**: CloudFront
- **DNS**: Route 53

**Compute:**
- **Backend**: ECS Fargate containers
- **Frontend**: S3 + CloudFront static hosting
- **Functions**: Lambda for serverless tasks
- **Admin**: EC2 instances for administrative tasks

**Storage:**
- **Database**: RDS MySQL (Multi-AZ)
- **Cache**: ElastiCache Redis
- **Files**: S3 buckets
- **Backup**: S3 with lifecycle policies

**Security:**
- **WAF**: AWS WAF for application protection
- **Certificates**: ACM (AWS Certificate Manager)
- **Secrets**: AWS Secrets Manager
- **IAM**: Role-based access control

## Environment Setup

### Environment Structure

CareConnect uses four distinct environments:

1. **Development** (`dev`): Local and feature development
2. **Staging** (`staging`): Integration testing and QA
3. **Production** (`prod`): Live production environment
4. **DR** (`dr`): Disaster recovery environment

### Environment Configuration

#### Development Environment

```bash
# Local development configuration
export ENVIRONMENT=dev
export DATABASE_URL=jdbc:mysql://localhost:3306/careconnect_dev
export REDIS_URL=redis://localhost:6379
export JWT_SECRET=dev_jwt_secret_key_32_characters
export AWS_REGION=us-east-1
export S3_BUCKET=careconnect-dev-files
```

#### Staging Environment

```bash
# Staging environment configuration
export ENVIRONMENT=staging
export DATABASE_URL=jdbc:mysql://staging-db.region.rds.amazonaws.com:3306/careconnect
export REDIS_URL=staging-cache.region.cache.amazonaws.com:6379
export JWT_SECRET=${JWT_SECRET_STAGING}  # From AWS Secrets Manager
export AWS_REGION=us-east-1
export S3_BUCKET=careconnect-staging-files
```

#### Production Environment

```bash
# Production environment configuration
export ENVIRONMENT=prod
export DATABASE_URL=jdbc:mysql://prod-db.region.rds.amazonaws.com:3306/careconnect
export REDIS_URL=prod-cache.region.cache.amazonaws.com:6379
export JWT_SECRET=${JWT_SECRET_PROD}  # From AWS Secrets Manager
export AWS_REGION=us-east-1
export S3_BUCKET=careconnect-prod-files
```

## AWS Infrastructure Deployment

### Terraform Configuration

#### Main Infrastructure Configuration

```hcl
# terraform_aws/main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "careconnect-terraform-state"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "CareConnect"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# Modules
module "vpc" {
  source = "./modules/vpc"

  environment             = var.environment
  vpc_cidr               = var.vpc_cidr
  availability_zones     = data.aws_availability_zones.available.names
  enable_nat_gateway     = true
  enable_vpn_gateway     = false
  enable_dns_hostnames   = true
  enable_dns_support     = true
}

module "security_groups" {
  source = "./modules/security_groups"

  environment = var.environment
  vpc_id      = module.vpc.vpc_id
}

module "rds" {
  source = "./modules/rds"

  environment                = var.environment
  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = module.vpc.database_subnet_ids
  security_group_ids        = [module.security_groups.rds_security_group_id]

  db_name                   = var.db_name
  db_username              = var.db_username
  db_password              = var.db_password
  db_instance_class        = var.db_instance_class
  allocated_storage        = var.db_allocated_storage
  max_allocated_storage    = var.db_max_allocated_storage

  backup_retention_period  = var.environment == "prod" ? 30 : 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  multi_az               = var.environment == "prod" ? true : false
  deletion_protection    = var.environment == "prod" ? true : false
}

module "elasticache" {
  source = "./modules/elasticache"

  environment        = var.environment
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_ids = [module.security_groups.cache_security_group_id]

  node_type         = var.cache_node_type
  num_cache_nodes   = var.cache_num_nodes
  parameter_group   = "default.redis7"
  port             = 6379
}

module "ecs" {
  source = "./modules/ecs"

  environment               = var.environment
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnet_ids
  security_group_ids       = [module.security_groups.ecs_security_group_id]

  cluster_name             = "careconnect-${var.environment}"
  task_definition_family   = "careconnect-backend"
  container_image          = var.backend_container_image
  container_port          = 8080

  cpu                     = var.ecs_cpu
  memory                  = var.ecs_memory
  desired_count           = var.ecs_desired_count

  database_url            = module.rds.database_url
  redis_url              = module.elasticache.redis_url

  log_group_name         = "/ecs/careconnect-${var.environment}"
  log_retention_days     = var.environment == "prod" ? 365 : 30
}

module "alb" {
  source = "./modules/alb"

  environment            = var.environment
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.public_subnet_ids
  security_group_ids    = [module.security_groups.alb_security_group_id]

  certificate_arn       = module.acm.certificate_arn
  target_group_arn      = module.ecs.target_group_arn
}

module "s3" {
  source = "./modules/s3"

  environment           = var.environment
  frontend_bucket_name  = "careconnect-${var.environment}-frontend"
  files_bucket_name     = "careconnect-${var.environment}-files"
  logs_bucket_name      = "careconnect-${var.environment}-logs"

  enable_versioning     = var.environment == "prod" ? true : false
  enable_logging        = true
}

module "cloudfront" {
  source = "./modules/cloudfront"

  environment         = var.environment
  s3_bucket_domain   = module.s3.frontend_bucket_domain
  alb_domain         = module.alb.dns_name
  certificate_arn    = module.acm.certificate_arn

  web_acl_id         = module.waf.web_acl_id
}

module "route53" {
  source = "./modules/route53"

  domain_name          = var.domain_name
  cloudfront_domain   = module.cloudfront.domain_name
  cloudfront_zone_id  = module.cloudfront.hosted_zone_id

  create_health_check = var.environment == "prod" ? true : false
}

module "acm" {
  source = "./modules/acm"

  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  route53_zone_id          = module.route53.zone_id
}

module "waf" {
  source = "./modules/waf"

  environment = var.environment

  rate_limit           = var.environment == "prod" ? 10000 : 2000
  enable_geo_blocking  = var.environment == "prod" ? true : false
  blocked_countries    = ["CN", "RU"]  # Example blocked countries
}

module "monitoring" {
  source = "./modules/monitoring"

  environment = var.environment

  cluster_name = module.ecs.cluster_name
  service_name = module.ecs.service_name

  rds_instance_id = module.rds.instance_id
  cache_cluster_id = module.elasticache.cluster_id

  alb_arn = module.alb.arn
  cloudfront_distribution_id = module.cloudfront.distribution_id

  notification_email = var.notification_email
}
```

#### VPC Module

```hcl
# terraform_aws/modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = {
    Name = "careconnect-${var.environment}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "careconnect-${var.environment}-igw"
  }
}

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "careconnect-${var.environment}-public-${count.index + 1}"
    Type = "Public"
  }
}

resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "careconnect-${var.environment}-private-${count.index + 1}"
    Type = "Private"
  }
}

resource "aws_subnet" "database" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 20)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "careconnect-${var.environment}-database-${count.index + 1}"
    Type = "Database"
  }
}

# NAT Gateways
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? length(var.availability_zones) : 0
  domain = "vpc"

  tags = {
    Name = "careconnect-${var.environment}-nat-eip-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? length(var.availability_zones) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "careconnect-${var.environment}-nat-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "careconnect-${var.environment}-public-rt"
  }
}

resource "aws_route_table" "private" {
  count = length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[count.index].id
    }
  }

  tags = {
    Name = "careconnect-${var.environment}-private-rt-${count.index + 1}"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "database" {
  count = length(aws_subnet.database)

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
```

#### ECS Module

```hcl
# terraform_aws/modules/ecs/main.tf
resource "aws_ecs_cluster" "main" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = var.cluster_name
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# Task Definition
resource "aws_ecs_task_definition" "main" {
  family                   = var.task_definition_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn           = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "careconnect-backend"
      image = var.container_image

      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "SERVER_PORT"
          value = tostring(var.container_port)
        },
        {
          name  = "SPRING_DATASOURCE_URL"
          value = var.database_url
        },
        {
          name  = "SPRING_REDIS_HOST"
          value = var.redis_url
        }
      ]

      secrets = [
        {
          name      = "SPRING_DATASOURCE_PASSWORD"
          valueFrom = var.db_password_secret_arn
        },
        {
          name      = "JWT_SECRET"
          valueFrom = var.jwt_secret_arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.log_group_name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}/actuator/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name = var.task_definition_family
  }
}

# ECS Service
resource "aws_ecs_service" "main" {
  name            = "${var.cluster_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count

  launch_type = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "careconnect-backend"
    container_port   = var.container_port
  }

  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100

    deployment_circuit_breaker {
      enable   = true
      rollback = true
    }
  }

  service_registries {
    registry_arn = aws_service_discovery_service.main.arn
  }

  depends_on = [
    aws_lb_listener.main,
    aws_iam_role_policy_attachment.ecs_execution_role_policy
  ]

  tags = {
    Name = "${var.cluster_name}-service"
  }
}

# Auto Scaling
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_cpu" {
  name               = "${var.cluster_name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# IAM Roles
resource "aws_iam_role" "ecs_execution" {
  name = "${var.cluster_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-ecs-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
```

### Deployment Commands

#### Initial Infrastructure Deployment

```bash
# Navigate to terraform directory
cd terraform_aws

# Initialize Terraform
terraform init

# Create workspace for environment
terraform workspace new prod
terraform workspace select prod

# Plan deployment
terraform plan -var-file="environments/prod.tfvars" -out=tfplan

# Review and apply
terraform apply tfplan

# Save outputs
terraform output > ../infrastructure-outputs.txt
```

#### Environment-Specific Variables

```hcl
# terraform_aws/environments/prod.tfvars
environment = "prod"
aws_region  = "us-east-1"

# Networking
vpc_cidr = "10.0.0.0/16"

# Database
db_name               = "careconnect"
db_username          = "careconnect_user"
db_instance_class    = "db.r6g.large"
db_allocated_storage = 100
db_max_allocated_storage = 1000

# Cache
cache_node_type = "cache.r6g.large"
cache_num_nodes = 2

# ECS
ecs_cpu           = 1024
ecs_memory        = 2048
ecs_desired_count = 3
ecs_min_capacity  = 2
ecs_max_capacity  = 10

# Domain
domain_name = "careconnect.example.com"

# Notifications
notification_email = "ops@example.com"

# Container Images
backend_container_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/careconnect-backend:latest"
```

## Application Deployment

### Backend Deployment

#### Docker Build and Push

```bash
# Build backend Docker image
cd backend/core

# Build the application
./mvnw clean package -DskipTests

# Build Docker image
docker build -t careconnect-backend:latest .

# Tag for ECR
docker tag careconnect-backend:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/careconnect-backend:latest

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

# Push to ECR
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/careconnect-backend:latest
```

#### ECS Service Update

```bash
# Update ECS service with new image
aws ecs update-service \
    --cluster careconnect-prod \
    --service careconnect-prod-service \
    --force-new-deployment

# Monitor deployment
aws ecs wait services-stable \
    --cluster careconnect-prod \
    --services careconnect-prod-service
```

### Frontend Deployment

#### Build and Deploy to S3

```bash
cd frontend

# Install dependencies
flutter pub get

# Build for web
flutter build web --release

# Deploy to S3
aws s3 sync build/web s3://careconnect-prod-frontend --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
    --distribution-id E1234567890123 \
    --paths "/*"
```

#### Mobile App Deployment

```bash
# Android
flutter build appbundle --release

# Upload to Google Play Console
# (Manual process through Google Play Console)

# iOS
flutter build ios --release

# Archive and upload to App Store Connect
# (Use Xcode or Application Loader)
```

### Blue-Green Deployment Strategy

#### Automated Blue-Green Deployment

```bash
#!/bin/bash
# scripts/blue-green-deploy.sh

set -e

CLUSTER_NAME="careconnect-prod"
SERVICE_NAME="careconnect-prod-service"
NEW_IMAGE="123456789012.dkr.ecr.us-east-1.amazonaws.com/careconnect-backend:$BUILD_NUMBER"

echo "Starting blue-green deployment..."

# Get current task definition
CURRENT_TASK_DEF=$(aws ecs describe-services \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --query 'services[0].taskDefinition' \
    --output text)

echo "Current task definition: $CURRENT_TASK_DEF"

# Create new task definition with new image
NEW_TASK_DEF=$(aws ecs describe-task-definition \
    --task-definition $CURRENT_TASK_DEF \
    --query 'taskDefinition' | \
    jq --arg IMAGE "$NEW_IMAGE" '.containerDefinitions[0].image = $IMAGE' | \
    jq 'del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .placementConstraints, .compatibilities, .registeredAt, .registeredBy)')

NEW_TASK_DEF_ARN=$(echo $NEW_TASK_DEF | aws ecs register-task-definition --cli-input-json file:///dev/stdin --query 'taskDefinition.taskDefinitionArn' --output text)

echo "New task definition: $NEW_TASK_DEF_ARN"

# Update service with new task definition
aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --task-definition $NEW_TASK_DEF_ARN

# Wait for deployment to complete
echo "Waiting for deployment to complete..."
aws ecs wait services-stable \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME

# Health check
echo "Performing health check..."
HEALTH_CHECK_URL="https://api.careconnect.example.com/actuator/health"

for i in {1..10}; do
    if curl -f $HEALTH_CHECK_URL > /dev/null 2>&1; then
        echo "Health check passed"
        break
    else
        echo "Health check failed, attempt $i/10"
        if [ $i -eq 10 ]; then
            echo "Health check failed after 10 attempts, rolling back..."
            # Rollback logic here
            exit 1
        fi
        sleep 30
    fi
done

echo "Blue-green deployment completed successfully!"
```

## Database Management

### Database Initialization

#### Production Database Setup

```sql
-- scripts/init-prod-db.sql

-- Create database
CREATE DATABASE IF NOT EXISTS careconnect
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Create application user
CREATE USER 'careconnect_app'@'%' IDENTIFIED BY 'secure_password_here';
GRANT SELECT, INSERT, UPDATE, DELETE ON careconnect.* TO 'careconnect_app'@'%';

-- Create read-only user for reporting
CREATE USER 'careconnect_readonly'@'%' IDENTIFIED BY 'readonly_password_here';
GRANT SELECT ON careconnect.* TO 'careconnect_readonly'@'%';

-- Create backup user
CREATE USER 'careconnect_backup'@'%' IDENTIFIED BY 'backup_password_here';
GRANT SELECT, LOCK TABLES ON careconnect.* TO 'careconnect_backup'@'%';

FLUSH PRIVILEGES;

-- Create initial tables (will be managed by Flyway migrations)
USE careconnect;

-- Enable binary logging for replication
SET GLOBAL log_bin = 1;
SET GLOBAL binlog_format = 'ROW';

-- Configure performance parameters
SET GLOBAL innodb_buffer_pool_size = 1024 * 1024 * 1024; -- 1GB
SET GLOBAL max_connections = 200;
SET GLOBAL slow_query_log = 1;
SET GLOBAL long_query_time = 2;
```

### Database Migration Strategy

#### Flyway Migration Setup

```xml
<!-- backend/core/pom.xml - Flyway plugin -->
<plugin>
    <groupId>org.flywaydb</groupId>
    <artifactId>flyway-maven-plugin</artifactId>
    <version>9.16.0</version>
    <configuration>
        <url>jdbc:mysql://${db.host}:${db.port}/${db.name}</url>
        <user>${db.username}</user>
        <password>${db.password}</password>
        <locations>
            <location>filesystem:src/main/resources/db/migration</location>
        </locations>
        <baselineOnMigrate>true</baselineOnMigrate>
        <validateOnMigrate>true</validateOnMigrate>
    </configuration>
</plugin>
```

#### Sample Migration Files

```sql
-- src/main/resources/db/migration/V001__Create_initial_schema.sql
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role ENUM('PATIENT', 'CAREGIVER', 'FAMILY_MEMBER') NOT NULL,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_users_email (email),
    INDEX idx_users_role (role),
    INDEX idx_users_active (active)
);

-- src/main/resources/db/migration/V002__Create_vital_signs_table.sql
CREATE TABLE vital_signs (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    type VARCHAR(50) NOT NULL,
    value DECIMAL(10,2) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    notes TEXT,
    measurement_time DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,

    INDEX idx_vital_signs_user_id (user_id),
    INDEX idx_vital_signs_type (type),
    INDEX idx_vital_signs_measurement_time (measurement_time),
    INDEX idx_vital_signs_user_type_time (user_id, type, measurement_time DESC)
);

-- src/main/resources/db/migration/V003__Add_health_monitoring_tables.sql
CREATE TABLE medications (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    dosage VARCHAR(100),
    frequency VARCHAR(100),
    start_date DATE,
    end_date DATE,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_medications_user_id (user_id),
    INDEX idx_medications_active (active)
);

CREATE TABLE allergies (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    allergen VARCHAR(255) NOT NULL,
    severity ENUM('MILD', 'MODERATE', 'SEVERE') NOT NULL,
    reaction TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_allergies_user_id (user_id)
);
```

### Database Backup Strategy

#### Automated Backup Script

```bash
#!/bin/bash
# scripts/backup-database.sh

set -e

# Configuration
DB_HOST="prod-db.region.rds.amazonaws.com"
DB_NAME="careconnect"
DB_USER="careconnect_backup"
DB_PASSWORD="$DB_BACKUP_PASSWORD"
S3_BUCKET="careconnect-prod-backups"
BACKUP_PREFIX="database"
RETENTION_DAYS=30

# Create timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILENAME="${BACKUP_PREFIX}_${TIMESTAMP}.sql.gz"

echo "Starting database backup: $BACKUP_FILENAME"

# Create backup
mysqldump \
    --host=$DB_HOST \
    --user=$DB_USER \
    --password=$DB_PASSWORD \
    --single-transaction \
    --routines \
    --triggers \
    --add-drop-database \
    --databases $DB_NAME | \
    gzip > /tmp/$BACKUP_FILENAME

# Upload to S3
aws s3 cp /tmp/$BACKUP_FILENAME s3://$S3_BUCKET/database/

# Clean up local file
rm /tmp/$BACKUP_FILENAME

# Clean up old backups
aws s3 ls s3://$S3_BUCKET/database/ | \
    awk '{print $4}' | \
    head -n -$RETENTION_DAYS | \
    while read file; do
        aws s3 rm s3://$S3_BUCKET/database/$file
    done

echo "Database backup completed: $BACKUP_FILENAME"

# Verify backup
BACKUP_SIZE=$(aws s3 ls s3://$S3_BUCKET/database/$BACKUP_FILENAME --summarize | grep "Total Size" | awk '{print $3}')

if [ "$BACKUP_SIZE" -gt 1000000 ]; then  # 1MB minimum
    echo "Backup verification passed: $BACKUP_SIZE bytes"
else
    echo "Backup verification failed: $BACKUP_SIZE bytes"
    exit 1
fi
```

#### Point-in-Time Recovery

```bash
#!/bin/bash
# scripts/restore-database.sh

set -e

# Parameters
RESTORE_TIME="$1"  # Format: YYYY-MM-DD HH:MM:SS
SOURCE_DB_INSTANCE="careconnect-prod-db"
TARGET_DB_INSTANCE="careconnect-restore-$(date +%Y%m%d%H%M%S)"

if [ -z "$RESTORE_TIME" ]; then
    echo "Usage: $0 'YYYY-MM-DD HH:MM:SS'"
    exit 1
fi

echo "Starting point-in-time recovery to: $RESTORE_TIME"

# Create restored DB instance
aws rds restore-db-instance-to-point-in-time \
    --target-db-instance-identifier $TARGET_DB_INSTANCE \
    --source-db-instance-identifier $SOURCE_DB_INSTANCE \
    --restore-time "$RESTORE_TIME" \
    --db-instance-class db.r6g.large \
    --no-multi-az \
    --no-publicly-accessible

echo "Restore initiated. Instance: $TARGET_DB_INSTANCE"

# Wait for instance to be available
aws rds wait db-instance-available \
    --db-instance-identifier $TARGET_DB_INSTANCE

echo "Database restore completed: $TARGET_DB_INSTANCE"

# Get endpoint
RESTORE_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier $TARGET_DB_INSTANCE \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

echo "Restored database endpoint: $RESTORE_ENDPOINT"
```

## CI/CD Pipeline

### GitHub Actions Workflow

```yaml
# .github/workflows/deploy-production.yml
name: Deploy to Production

on:
  push:
    branches: [main]
  workflow_dispatch:

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: careconnect-backend
  ECS_CLUSTER: careconnect-prod
  ECS_SERVICE: careconnect-prod-service

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: test
          MYSQL_DATABASE: careconnect_test
        ports:
          - 3306:3306
        options: --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=3

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up JDK 17
      uses: actions/setup-java@v3
      with:
        java-version: '17'
        distribution: 'adopt'

    - name: Cache Maven packages
      uses: actions/cache@v3
      with:
        path: ~/.m2
        key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}
        restore-keys: ${{ runner.os }}-m2

    - name: Run backend tests
      working-directory: backend/core
      run: ./mvnw test
      env:
        SPRING_DATASOURCE_URL: jdbc:mysql://localhost:3306/careconnect_test
        SPRING_DATASOURCE_USERNAME: root
        SPRING_DATASOURCE_PASSWORD: test

    - name: Set up Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.9.2'

    - name: Run frontend tests
      working-directory: frontend
      run: |
        flutter pub get
        flutter test

  build-and-deploy-backend:
    needs: test
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v3
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}

    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v1

    - name: Build and tag Docker image
      working-directory: backend/core
      run: |
        ./mvnw clean package -DskipTests
        docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$GITHUB_SHA .
        docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$GITHUB_SHA $ECR_REGISTRY/$ECR_REPOSITORY:latest
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}

    - name: Push image to Amazon ECR
      run: |
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:$GITHUB_SHA
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}

    - name: Deploy to Amazon ECS
      run: |
        # Get current task definition
        TASK_DEFINITION=$(aws ecs describe-task-definition --task-definition careconnect-backend --query 'taskDefinition')

        # Create new task definition with new image
        NEW_TASK_DEFINITION=$(echo $TASK_DEFINITION | jq --arg IMAGE "$ECR_REGISTRY/$ECR_REPOSITORY:$GITHUB_SHA" '.containerDefinitions[0].image = $IMAGE' | jq 'del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .placementConstraints, .compatibilities, .registeredAt, .registeredBy)')

        # Register new task definition
        NEW_TASK_DEF_ARN=$(echo $NEW_TASK_DEFINITION | aws ecs register-task-definition --cli-input-json file:///dev/stdin --query 'taskDefinition.taskDefinitionArn' --output text)

        # Update service
        aws ecs update-service --cluster $ECS_CLUSTER --service $ECS_SERVICE --task-definition $NEW_TASK_DEF_ARN

        # Wait for deployment
        aws ecs wait services-stable --cluster $ECS_CLUSTER --services $ECS_SERVICE
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}

  build-and-deploy-frontend:
    needs: test
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.9.2'

    - name: Build web app
      working-directory: frontend
      run: |
        flutter pub get
        flutter build web --release

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v3
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}

    - name: Deploy to S3
      working-directory: frontend
      run: |
        aws s3 sync build/web s3://careconnect-prod-frontend --delete

    - name: Invalidate CloudFront
      run: |
        DISTRIBUTION_ID=$(aws cloudfront list-distributions --query "DistributionList.Items[?contains(Aliases.Items, 'careconnect.example.com')].Id" --output text)
        aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths "/*"

  run-migrations:
    needs: [build-and-deploy-backend]
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up JDK 17
      uses: actions/setup-java@v3
      with:
        java-version: '17'
        distribution: 'adopt'

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v3
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}

    - name: Run database migrations
      working-directory: backend/core
      run: |
        # Get database credentials from Secrets Manager
        DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id careconnect/prod/db-password --query SecretString --output text)

        ./mvnw flyway:migrate \
          -Dflyway.url=jdbc:mysql://prod-db.region.rds.amazonaws.com:3306/careconnect \
          -Dflyway.user=careconnect_app \
          -Dflyway.password=$DB_PASSWORD

  smoke-tests:
    needs: [build-and-deploy-backend, build-and-deploy-frontend, run-migrations]
    runs-on: ubuntu-latest

    steps:
    - name: Health check API
      run: |
        curl -f https://api.careconnect.example.com/actuator/health
        curl -f https://api.careconnect.example.com/actuator/info

    - name: Health check frontend
      run: |
        curl -f https://careconnect.example.com

    - name: Run API tests
      run: |
        # Run basic API tests
        curl -X POST https://api.careconnect.example.com/api/auth/login \
          -H "Content-Type: application/json" \
          -d '{"email":"test@example.com","password":"invalid"}' \
          | grep -q "Invalid credentials"

  notify:
    needs: [build-and-deploy-backend, build-and-deploy-frontend, run-migrations, smoke-tests]
    runs-on: ubuntu-latest
    if: always()

    steps:
    - name: Notify success
      if: ${{ success() }}
      run: |
        curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
          -H 'Content-type: application/json' \
          --data '{"text":"✅ Production deployment successful!"}'

    - name: Notify failure
      if: ${{ failure() }}
      run: |
        curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
          -H 'Content-type: application/json' \
          --data '{"text":"❌ Production deployment failed!"}'
```

### Rollback Strategy

```bash
#!/bin/bash
# scripts/rollback.sh

set -e

CLUSTER_NAME="careconnect-prod"
SERVICE_NAME="careconnect-prod-service"

echo "Starting rollback process..."

# Get current and previous task definitions
CURRENT_TASK_DEF=$(aws ecs describe-services \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --query 'services[0].taskDefinition' \
    --output text)

echo "Current task definition: $CURRENT_TASK_DEF"

# Extract revision number
CURRENT_REVISION=$(echo $CURRENT_TASK_DEF | grep -o '[0-9]*$')
PREVIOUS_REVISION=$((CURRENT_REVISION - 1))

if [ $PREVIOUS_REVISION -lt 1 ]; then
    echo "Cannot rollback: no previous revision available"
    exit 1
fi

PREVIOUS_TASK_DEF=$(echo $CURRENT_TASK_DEF | sed "s/:$CURRENT_REVISION/:$PREVIOUS_REVISION/")

echo "Rolling back to: $PREVIOUS_TASK_DEF"

# Update service with previous task definition
aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --task-definition $PREVIOUS_TASK_DEF

# Wait for rollback to complete
echo "Waiting for rollback to complete..."
aws ecs wait services-stable \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME

# Health check
echo "Performing health check..."
sleep 30  # Wait for service to fully start

HEALTH_CHECK_URL="https://api.careconnect.example.com/actuator/health"

for i in {1..5}; do
    if curl -f $HEALTH_CHECK_URL > /dev/null 2>&1; then
        echo "Rollback successful - health check passed"
        exit 0
    else
        echo "Health check failed, attempt $i/5"
        sleep 30
    fi
done

echo "Rollback failed - health check did not pass"
exit 1
```

## Monitoring and Logging

### CloudWatch Dashboard

```json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/ECS", "CPUUtilization", "ServiceName", "careconnect-prod-service", "ClusterName", "careconnect-prod"],
          [".", "MemoryUtilization", ".", ".", ".", "."]
        ],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1",
        "title": "ECS Service Metrics"
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "careconnect-prod-db"],
          [".", "DatabaseConnections", ".", "."],
          [".", "ReadLatency", ".", "."],
          [".", "WriteLatency", ".", "."]
        ],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1",
        "title": "RDS Metrics"
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "careconnect-prod-alb"],
          [".", "TargetResponseTime", ".", "."],
          [".", "HTTPCode_Target_2XX_Count", ".", "."],
          [".", "HTTPCode_Target_4XX_Count", ".", "."],
          [".", "HTTPCode_Target_5XX_Count", ".", "."]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "us-east-1",
        "title": "Load Balancer Metrics"
      }
    }
  ]
}
```

### Application Metrics

```java
// config/MetricsConfig.java
@Configuration
public class MetricsConfig {

    @Bean
    public MeterRegistry meterRegistry() {
        return new CloudWatchMeterRegistry(
            CloudWatchConfig.DEFAULT,
            Clock.SYSTEM,
            CloudWatchAsyncClient.create()
        );
    }

    @Bean
    @ConditionalOnMissingBean
    public TimedAspect timedAspect(MeterRegistry registry) {
        return new TimedAspect(registry);
    }
}

// Custom metrics in service classes
@Service
public class HealthService {

    private final Counter vitalSignsRecorded;
    private final Timer apiResponseTime;
    private final Gauge activeUsers;

    public HealthService(MeterRegistry meterRegistry) {
        this.vitalSignsRecorded = Counter.builder("careconnect.vitalsigns.recorded")
            .description("Number of vital signs recorded")
            .register(meterRegistry);

        this.apiResponseTime = Timer.builder("careconnect.api.response.time")
            .description("API response time")
            .register(meterRegistry);

        this.activeUsers = Gauge.builder("careconnect.users.active")
            .description("Number of active users")
            .register(meterRegistry, this, HealthService::getActiveUserCount);
    }

    @Timed(value = "careconnect.vitalsigns.record", description = "Time to record vital sign")
    public VitalSign recordVitalSign(VitalSignRequest request) {
        // Implementation
        vitalSignsRecorded.increment();
        return vitalSign;
    }

    private int getActiveUserCount() {
        // Implementation to count active users
        return 0;
    }
}
```

### Alerting Configuration

```yaml
# cloudwatch-alarms.yml (for Terraform or CloudFormation)
HighCPUUtilization:
  Type: AWS::CloudWatch::Alarm
  Properties:
    AlarmDescription: High CPU utilization on ECS service
    MetricName: CPUUtilization
    Namespace: AWS/ECS
    Statistic: Average
    Period: 300
    EvaluationPeriods: 2
    Threshold: 80
    ComparisonOperator: GreaterThanThreshold
    Dimensions:
      - Name: ServiceName
        Value: careconnect-prod-service
      - Name: ClusterName
        Value: careconnect-prod
    AlarmActions:
      - !Ref SNSTopic

HighMemoryUtilization:
  Type: AWS::CloudWatch::Alarm
  Properties:
    AlarmDescription: High memory utilization on ECS service
    MetricName: MemoryUtilization
    Namespace: AWS/ECS
    Statistic: Average
    Period: 300
    EvaluationPeriods: 2
    Threshold: 85
    ComparisonOperator: GreaterThanThreshold
    Dimensions:
      - Name: ServiceName
        Value: careconnect-prod-service
      - Name: ClusterName
        Value: careconnect-prod
    AlarmActions:
      - !Ref SNSTopic

DatabaseConnectionsHigh:
  Type: AWS::CloudWatch::Alarm
  Properties:
    AlarmDescription: High database connections
    MetricName: DatabaseConnections
    Namespace: AWS/RDS
    Statistic: Average
    Period: 300
    EvaluationPeriods: 2
    Threshold: 80
    ComparisonOperator: GreaterThanThreshold
    Dimensions:
      - Name: DBInstanceIdentifier
        Value: careconnect-prod-db
    AlarmActions:
      - !Ref SNSTopic

APIErrorRate:
  Type: AWS::CloudWatch::Alarm
  Properties:
    AlarmDescription: High API error rate
    MetricName: HTTPCode_Target_5XX_Count
    Namespace: AWS/ApplicationELB
    Statistic: Sum
    Period: 300
    EvaluationPeriods: 2
    Threshold: 10
    ComparisonOperator: GreaterThanThreshold
    Dimensions:
      - Name: LoadBalancer
        Value: careconnect-prod-alb
    AlarmActions:
      - !Ref SNSTopic
```

### Log Aggregation

```yaml
# cloudwatch-logs.yml
version: '3'

x-logging: &default-logging
  driver: "awslogs"
  options:
    awslogs-group: "/ecs/careconnect-prod"
    awslogs-region: "us-east-1"
    awslogs-stream-prefix: "ecs"

services:
  backend:
    logging: *default-logging
    environment:
      - LOGGING_LEVEL_ROOT=INFO
      - LOGGING_LEVEL_COM_CARECONNECT=DEBUG
      - LOGGING_PATTERN_CONSOLE=%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n
      - LOGGING_PATTERN_FILE=%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n
```

## Security and Compliance

### Security Hardening

#### Network Security

```hcl
# Security Groups
resource "aws_security_group" "alb" {
  name_prefix = "${var.environment}-alb-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-alb-sg"
  }
}

resource "aws_security_group" "ecs" {
  name_prefix = "${var.environment}-ecs-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-ecs-sg"
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "${var.environment}-rds-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  tags = {
    Name = "${var.environment}-rds-sg"
  }
}
```

#### WAF Configuration

```hcl
# Web Application Firewall
resource "aws_wafv2_web_acl" "main" {
  name  = "careconnect-${var.environment}-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Rate limiting rule
  rule {
    name     = "RateLimitRule"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 10000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  # SQL injection protection
  rule {
    name     = "SQLInjectionRule"
    priority = 2

    action {
      block {}
    }

    statement {
      sqli_match_statement {
        field_to_match {
          body {}
        }

        text_transformation {
          priority = 0
          type     = "URL_DECODE"
        }

        text_transformation {
          priority = 1
          type     = "HTML_ENTITY_DECODE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLInjectionRule"
      sampled_requests_enabled   = true
    }
  }

  # XSS protection
  rule {
    name     = "XSSRule"
    priority = 3

    action {
      block {}
    }

    statement {
      xss_match_statement {
        field_to_match {
          body {}
        }

        text_transformation {
          priority = 0
          type     = "URL_DECODE"
        }

        text_transformation {
          priority = 1
          type     = "HTML_ENTITY_DECODE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "XSSRule"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "careconnect-${var.environment}-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "careconnect-${var.environment}-waf"
  }
}
```

### Secrets Management

#### AWS Secrets Manager Configuration

```hcl
# Database password
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "careconnect/${var.environment}/db-password"
  description             = "Database password for CareConnect ${var.environment}"
  recovery_window_in_days = var.environment == "prod" ? 30 : 0

  tags = {
    Name        = "careconnect-${var.environment}-db-password"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}

# JWT secret
resource "aws_secretsmanager_secret" "jwt_secret" {
  name                    = "careconnect/${var.environment}/jwt-secret"
  description             = "JWT secret for CareConnect ${var.environment}"
  recovery_window_in_days = var.environment == "prod" ? 30 : 0

  tags = {
    Name        = "careconnect-${var.environment}-jwt-secret"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = var.jwt_secret
}

# API keys
resource "aws_secretsmanager_secret" "api_keys" {
  name                    = "careconnect/${var.environment}/api-keys"
  description             = "API keys for CareConnect ${var.environment}"
  recovery_window_in_days = var.environment == "prod" ? 30 : 0

  tags = {
    Name        = "careconnect-${var.environment}-api-keys"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "api_keys" {
  secret_id = aws_secretsmanager_secret.api_keys.id
  secret_string = jsonencode({
    deepseek_api_key = var.deepseek_api_key
    openai_api_key   = var.openai_api_key
    stripe_secret_key = var.stripe_secret_key
  })
}
```

### HIPAA Compliance

#### Encryption Configuration

```yaml
# RDS Encryption
DBInstance:
  Type: AWS::RDS::DBInstance
  Properties:
    StorageEncrypted: true
    KmsKeyId: !Ref DatabaseKMSKey

# S3 Bucket Encryption
S3Bucket:
  Type: AWS::S3::Bucket
  Properties:
    BucketEncryption:
      ServerSideEncryptionConfiguration:
        - ServerSideEncryptionByDefault:
            SSEAlgorithm: aws:kms
            KMSMasterKeyID: !Ref S3KMSKey

# ECS Task Definition - Encryption in transit
TaskDefinition:
  Type: AWS::ECS::TaskDefinition
  Properties:
    ContainerDefinitions:
      - Name: careconnect-backend
        Environment:
          - Name: SERVER_SSL_ENABLED
            Value: "true"
          - Name: SERVER_SSL_KEY_STORE_TYPE
            Value: "PKCS12"
```

#### Audit Logging

```java
// Audit configuration
@Configuration
@EnableJpaAuditing
public class AuditConfig {

    @Bean
    public AuditorAware<String> auditorProvider() {
        return new SpringSecurityAuditorAware();
    }
}

// Audit entity
@Entity
@Table(name = "audit_logs")
public class AuditLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String userId;

    @Column(nullable = false)
    private String action;

    @Column(nullable = false)
    private String resource;

    @Column(columnDefinition = "TEXT")
    private String details;

    @Column(nullable = false)
    private String ipAddress;

    @Column(nullable = false)
    private String userAgent;

    @CreationTimestamp
    private LocalDateTime timestamp;

    // Constructors, getters, setters
}

// Audit service
@Service
public class AuditService {

    private final AuditLogRepository auditLogRepository;

    @Async
    public void logAction(String userId, String action, String resource, String details) {
        AuditLog auditLog = new AuditLog();
        auditLog.setUserId(userId);
        auditLog.setAction(action);
        auditLog.setResource(resource);
        auditLog.setDetails(details);
        auditLog.setIpAddress(getCurrentUserIpAddress());
        auditLog.setUserAgent(getCurrentUserAgent());

        auditLogRepository.save(auditLog);
    }
}
```

## Backup and Disaster Recovery

### Backup Strategy

#### Automated RDS Backups

```hcl
# RDS instance with automated backups
resource "aws_db_instance" "main" {
  # ... other configuration

  # Automated backups
  backup_retention_period = var.environment == "prod" ? 30 : 7
  backup_window          = "03:00-04:00"  # UTC
  copy_tags_to_snapshot  = true
  delete_automated_backups = false

  # Point-in-time recovery
  enabled_cloudwatch_logs_exports = ["error", "general", "slow-query"]

  # Final snapshot
  final_snapshot_identifier = "${var.environment}-db-final-snapshot-${formatdate("YYYYMMDD-hhmm", timestamp())}"
  skip_final_snapshot      = var.environment == "dev" ? true : false

  # Cross-region backup
  dynamic "restore_to_point_in_time" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      restore_time = "2023-01-01T00:00:00Z"  # Example
    }
  }
}

# Cross-region snapshot copy
resource "aws_db_snapshot_copy" "cross_region" {
  count = var.environment == "prod" ? 1 : 0

  source_db_snapshot_identifier = aws_db_instance.main.latest_restorable_time
  target_db_snapshot_identifier = "${var.environment}-cross-region-backup-${formatdate("YYYYMMDD", timestamp())}"

  kms_key_id = var.kms_key_id

  tags = {
    Name        = "${var.environment}-cross-region-backup"
    Environment = var.environment
  }
}
```

#### S3 Backup Configuration

```hcl
# S3 bucket for backups
resource "aws_s3_bucket" "backups" {
  bucket = "careconnect-${var.environment}-backups"

  tags = {
    Name        = "careconnect-${var.environment}-backups"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.backups.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    id     = "database_backups"
    status = "Enabled"

    filter {
      prefix = "database/"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = 2557  # 7 years for HIPAA compliance
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}
```

### Disaster Recovery Plan

#### RTO/RPO Requirements

- **Recovery Time Objective (RTO)**: 4 hours
- **Recovery Point Objective (RPO)**: 1 hour
- **Data Retention**: 7 years (HIPAA compliance)

#### DR Site Setup

```hcl
# DR region configuration
provider "aws" {
  alias  = "dr"
  region = var.dr_region
}

# DR VPC
module "vpc_dr" {
  source = "./modules/vpc"
  providers = {
    aws = aws.dr
  }

  environment = "${var.environment}-dr"
  vpc_cidr    = "10.1.0.0/16"
}

# DR RDS (read replica)
resource "aws_db_instance" "dr_replica" {
  provider = aws.dr

  identifier = "careconnect-${var.environment}-dr"

  replicate_source_db = aws_db_instance.main.identifier

  instance_class    = var.db_instance_class
  publicly_accessible = false

  auto_minor_version_upgrade = true
  backup_retention_period    = 7
  backup_window             = "03:00-04:00"

  tags = {
    Name        = "careconnect-${var.environment}-dr"
    Environment = var.environment
    Type        = "DR"
  }
}

# DR ECS cluster (minimal capacity)
module "ecs_dr" {
  source = "./modules/ecs"
  providers = {
    aws = aws.dr
  }

  environment = "${var.environment}-dr"
  vpc_id      = module.vpc_dr.vpc_id
  subnet_ids  = module.vpc_dr.private_subnet_ids

  cluster_name    = "careconnect-${var.environment}-dr"
  desired_count   = 0  # Scale up during disaster
  min_capacity    = 0
  max_capacity    = 10

  container_image = var.backend_container_image
  database_url    = aws_db_instance.dr_replica.endpoint
}
```

#### Disaster Recovery Runbook

```bash
#!/bin/bash
# scripts/disaster-recovery.sh

set -e

DR_REGION="us-west-2"
PRIMARY_REGION="us-east-1"
ENVIRONMENT="prod"

echo "Starting disaster recovery process..."

# Step 1: Promote DR database
echo "Promoting read replica to primary..."
aws rds promote-read-replica \
    --db-instance-identifier careconnect-${ENVIRONMENT}-dr \
    --region $DR_REGION

aws rds wait db-instance-available \
    --db-instance-identifier careconnect-${ENVIRONMENT}-dr \
    --region $DR_REGION

# Step 2: Scale up DR ECS service
echo "Scaling up DR ECS service..."
aws ecs update-service \
    --cluster careconnect-${ENVIRONMENT}-dr \
    --service careconnect-${ENVIRONMENT}-dr-service \
    --desired-count 3 \
    --region $DR_REGION

aws ecs wait services-stable \
    --cluster careconnect-${ENVIRONMENT}-dr \
    --services careconnect-${ENVIRONMENT}-dr-service \
    --region $DR_REGION

# Step 3: Update DNS to point to DR site
echo "Updating DNS to DR site..."
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones \
    --query "HostedZones[?Name=='careconnect.example.com.'].Id" \
    --output text | cut -d'/' -f3)

DR_ALB_DNS=$(aws elbv2 describe-load-balancers \
    --region $DR_REGION \
    --query "LoadBalancers[?contains(LoadBalancerName, 'careconnect-${ENVIRONMENT}-dr')].DNSName" \
    --output text)

aws route53 change-resource-record-sets \
    --hosted-zone-id $HOSTED_ZONE_ID \
    --change-batch file://<(cat <<EOF
{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "api.careconnect.example.com",
        "Type": "CNAME",
        "TTL": 60,
        "ResourceRecords": [
          {
            "Value": "$DR_ALB_DNS"
          }
        ]
      }
    }
  ]
}
EOF
)

# Step 4: Verify DR site
echo "Verifying DR site..."
sleep 60  # Wait for DNS propagation

curl -f https://api.careconnect.example.com/actuator/health

echo "Disaster recovery completed successfully!"

# Step 5: Notify stakeholders
curl -X POST $SLACK_WEBHOOK_URL \
    -H 'Content-type: application/json' \
    --data '{"text":"🚨 Disaster recovery activated. Site is now running from DR region."}'
```

### Recovery Testing

#### Monthly DR Tests

```bash
#!/bin/bash
# scripts/dr-test.sh

set -e

echo "Starting monthly DR test..."

# Create test environment in DR region
terraform workspace new dr-test
terraform plan -var-file="environments/dr-test.tfvars"
terraform apply -auto-approve

# Run smoke tests against DR environment
./scripts/smoke-tests.sh https://dr-test.careconnect.example.com

# Generate DR test report
echo "DR Test Results:" > dr-test-report.txt
echo "Date: $(date)" >> dr-test-report.txt
echo "RTO Achieved: $(cat rto-time.txt)" >> dr-test-report.txt
echo "RPO Achieved: $(cat rpo-time.txt)" >> dr-test-report.txt

# Cleanup test environment
terraform destroy -auto-approve
terraform workspace delete dr-test

echo "DR test completed successfully"
```

## Performance Optimization

### Database Optimization

#### Query Optimization

```sql
-- Analyze slow queries
SELECT
    query_time,
    lock_time,
    rows_sent,
    rows_examined,
    sql_text
FROM mysql.slow_log
WHERE start_time >= DATE_SUB(NOW(), INTERVAL 1 DAY)
ORDER BY query_time DESC
LIMIT 20;

-- Optimize frequently accessed tables
ANALYZE TABLE users, vital_signs, medications;

-- Add missing indexes
CREATE INDEX idx_vital_signs_user_type_date
ON vital_signs(user_id, type, measurement_time DESC);

CREATE INDEX idx_messages_conversation_unread
ON messages(conversation_id, is_read, created_at DESC);

-- Partition large tables
ALTER TABLE vital_signs
PARTITION BY RANGE (YEAR(measurement_time)) (
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION p2026 VALUES LESS THAN MAXVALUE
);
```

#### Connection Pooling

```properties
# application-prod.properties

# HikariCP configuration
spring.datasource.hikari.connection-timeout=20000
spring.datasource.hikari.idle-timeout=300000
spring.datasource.hikari.max-lifetime=1200000
spring.datasource.hikari.maximum-pool-size=20
spring.datasource.hikari.minimum-idle=5
spring.datasource.hikari.pool-name=CareConnectHikariPool

# Connection validation
spring.datasource.hikari.connection-test-query=SELECT 1
spring.datasource.hikari.validation-timeout=5000

# Performance monitoring
spring.datasource.hikari.register-mbeans=true
```

### Caching Strategy

#### Redis Configuration

```yaml
# Redis cluster configuration
spring:
  redis:
    cluster:
      nodes:
        - prod-cache-001.region.cache.amazonaws.com:6379
        - prod-cache-002.region.cache.amazonaws.com:6379
        - prod-cache-003.region.cache.amazonaws.com:6379
    timeout: 2000ms
    lettuce:
      pool:
        max-active: 20
        max-idle: 5
        min-idle: 0
        time-between-eviction-runs: 60s
```

#### Cache Implementation

```java
@Service
public class CachedHealthService {

    @Cacheable(value = "userVitals", key = "#userId", unless = "#result.isEmpty()")
    public List<VitalSignDTO> getVitalSigns(Long userId) {
        return healthRepository.findByUserIdOrderByMeasurementTimeDesc(userId)
            .stream()
            .map(this::convertToDTO)
            .collect(Collectors.toList());
    }

    @CacheEvict(value = "userVitals", key = "#userId")
    public VitalSignDTO recordVitalSign(Long userId, VitalSignRequest request) {
        // Implementation
    }

    @Cacheable(value = "healthSummary", key = "#userId")
    public HealthSummaryDTO getHealthSummary(Long userId) {
        // Expensive aggregation query
    }

    @CacheEvict(value = {"userVitals", "healthSummary"}, key = "#userId")
    public void evictUserCache(Long userId) {
        // Manual cache eviction
    }
}
```

### CDN Optimization

#### CloudFront Configuration

```hcl
resource "aws_cloudfront_distribution" "main" {
  origin {
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.frontend.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }

  # API origin
  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = "ALB-${aws_lb.main.name}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  # Static assets caching
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.frontend.id}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 86400    # 1 day
    max_ttl     = 31536000 # 1 year
  }

  # API caching
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ALB-${aws_lb.main.name}"
    compress         = true

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Content-Type"]
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "https-only"
    min_ttl               = 0
    default_ttl           = 0
    max_ttl               = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.main.arn
    ssl_support_method  = "sni-only"
  }

  web_acl_id = aws_wafv2_web_acl.main.arn

  tags = {
    Name = "careconnect-${var.environment}-cdn"
  }
}
```

## Scaling Strategies

### Horizontal Scaling

#### Auto Scaling Configuration

```hcl
# ECS Auto Scaling
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = {
    Name = "${var.cluster_name}-scaling-target"
  }
}

# CPU-based scaling
resource "aws_appautoscaling_policy" "ecs_cpu" {
  name               = "${var.cluster_name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

# Memory-based scaling
resource "aws_appautoscaling_policy" "ecs_memory" {
  name               = "${var.cluster_name}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 80.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Custom metric scaling (API request rate)
resource "aws_appautoscaling_policy" "ecs_requests" {
  name               = "${var.cluster_name}-requests-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    customized_metric_specification {
      metric_name = "RequestCountPerTarget"
      namespace   = "AWS/ApplicationELB"
      statistic   = "Sum"

      dimensions = {
        TargetGroup  = aws_lb_target_group.main.arn_suffix
        LoadBalancer = aws_lb.main.arn_suffix
      }
    }
    target_value = 1000.0
  }
}
```

### Database Scaling

#### Read Replicas

```hcl
# Read replica for reporting
resource "aws_db_instance" "read_replica" {
  identifier = "careconnect-${var.environment}-read-replica"

  replicate_source_db = aws_db_instance.main.identifier

  instance_class         = var.read_replica_instance_class
  publicly_accessible    = false
  auto_minor_version_upgrade = true

  # Performance Insights
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.enhanced_monitoring.arn

  tags = {
    Name        = "careconnect-${var.environment}-read-replica"
    Environment = var.environment
    Type        = "ReadReplica"
  }
}

# Connection routing in application
@Configuration
public class DatabaseConfig {

    @Bean
    @Primary
    public DataSource primaryDataSource() {
        return DataSourceBuilder.create()
            .url("jdbc:mysql://prod-db.region.rds.amazonaws.com:3306/careconnect")
            .username("careconnect_app")
            .password("${spring.datasource.password}")
            .build();
    }

    @Bean
    public DataSource readOnlyDataSource() {
        return DataSourceBuilder.create()
            .url("jdbc:mysql://prod-db-read-replica.region.rds.amazonaws.com:3306/careconnect")
            .username("careconnect_readonly")
            .password("${spring.datasource.readonly.password}")
            .build();
    }

    @Bean
    public JdbcTemplate readOnlyJdbcTemplate() {
        return new JdbcTemplate(readOnlyDataSource());
    }
}
```

## Maintenance Procedures

### Scheduled Maintenance

#### Maintenance Window Planning

```bash
#!/bin/bash
# scripts/maintenance-window.sh

set -e

MAINTENANCE_START=$(date)
CLUSTER_NAME="careconnect-prod"
SERVICE_NAME="careconnect-prod-service"

echo "Starting maintenance window: $MAINTENANCE_START"

# 1. Enable maintenance mode
echo "Enabling maintenance mode..."
aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service maintenance-service \
    --desired-count 1

# 2. Scale down main service
echo "Scaling down main service..."
aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --desired-count 0

aws ecs wait services-stable \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME

# 3. Database maintenance
echo "Starting database maintenance..."

# Update RDS instance class if needed
if [ "$UPGRADE_DB_INSTANCE" = "true" ]; then
    aws rds modify-db-instance \
        --db-instance-identifier careconnect-prod-db \
        --db-instance-class $NEW_DB_INSTANCE_CLASS \
        --apply-immediately

    aws rds wait db-instance-available \
        --db-instance-identifier careconnect-prod-db
fi

# Run database maintenance
mysql -h prod-db.region.rds.amazonaws.com -u admin -p << EOF
OPTIMIZE TABLE users, vital_signs, medications, allergies;
ANALYZE TABLE users, vital_signs, medications, allergies;
EOF

# 4. Update infrastructure if needed
if [ -f "infrastructure-updates.tf" ]; then
    echo "Applying infrastructure updates..."
    terraform plan -out=maintenance.tfplan
    terraform apply maintenance.tfplan
fi

# 5. Deploy application updates
if [ "$DEPLOY_NEW_VERSION" = "true" ]; then
    echo "Deploying new application version..."
    ./scripts/blue-green-deploy.sh
else
    # Scale service back up
    echo "Scaling service back up..."
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $SERVICE_NAME \
        --desired-count 3

    aws ecs wait services-stable \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME
fi

# 6. Disable maintenance mode
echo "Disabling maintenance mode..."
aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service maintenance-service \
    --desired-count 0

# 7. Run post-maintenance tests
echo "Running post-maintenance tests..."
./scripts/smoke-tests.sh

MAINTENANCE_END=$(date)
echo "Maintenance window completed: $MAINTENANCE_END"

# 8. Generate maintenance report
cat << EOF > maintenance-report-$(date +%Y%m%d).txt
Maintenance Window Report
========================

Start Time: $MAINTENANCE_START
End Time: $MAINTENANCE_END
Duration: $(($(date -d "$MAINTENANCE_END" +%s) - $(date -d "$MAINTENANCE_START" +%s))) seconds

Activities Performed:
- Database optimization: $(if [ "$DB_OPTIMIZED" = "true" ]; then echo "Completed"; else echo "Skipped"; fi)
- Infrastructure updates: $(if [ -f "infrastructure-updates.tf" ]; then echo "Applied"; else echo "None"; fi)
- Application deployment: $(if [ "$DEPLOY_NEW_VERSION" = "true" ]; then echo "Deployed"; else echo "Skipped"; fi)

Post-maintenance test results: $(if ./scripts/smoke-tests.sh > /dev/null 2>&1; then echo "Passed"; else echo "Failed"; fi)
EOF

echo "Maintenance report generated: maintenance-report-$(date +%Y%m%d).txt"
```

### System Updates

#### Security Patching

```bash
#!/bin/bash
# scripts/security-patching.sh

set -e

echo "Starting security patching process..."

# 1. Check for available security updates
echo "Checking for security updates..."

# Update base Docker images
docker pull openjdk:17-jdk-slim
docker pull mysql:8.0

# Check for OS-level patches (for EC2 instances if any)
yum list-security --security 2>/dev/null || true

# 2. Update dependencies
echo "Updating application dependencies..."

# Backend dependencies
cd backend/core
./mvnw versions:display-dependency-updates
./mvnw versions:use-latest-versions -DallowSnapshots=false
./mvnw clean test  # Ensure tests still pass

# Frontend dependencies
cd ../../frontend
flutter pub upgrade
flutter test

# 3. Build new container images
echo "Building updated container images..."

cd ../backend/core
docker build -t careconnect-backend:security-patch-$(date +%Y%m%d) .

# 4. Deploy to staging first
echo "Deploying to staging for testing..."
./scripts/deploy-staging.sh security-patch-$(date +%Y%m%d)

# 5. Run security tests
echo "Running security tests..."
./scripts/security-tests.sh staging

# 6. Deploy to production if tests pass
if [ $? -eq 0 ]; then
    echo "Security tests passed. Deploying to production..."
    ./scripts/blue-green-deploy.sh security-patch-$(date +%Y%m%d)
else
    echo "Security tests failed. Aborting production deployment."
    exit 1
fi

echo "Security patching completed successfully."
```

## Troubleshooting

### Common Issues and Solutions

#### Application Won't Start

```bash
# Check ECS service logs
aws logs filter-log-events \
    --log-group-name "/ecs/careconnect-prod" \
    --start-time $(date -d '1 hour ago' +%s)000

# Check service status
aws ecs describe-services \
    --cluster careconnect-prod \
    --services careconnect-prod-service

# Check task definition
aws ecs describe-task-definition \
    --task-definition careconnect-backend

# Check security groups and network connectivity
aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=careconnect-prod-*"
```

#### Database Connection Issues

```bash
# Test database connectivity
mysql -h prod-db.region.rds.amazonaws.com \
      -u careconnect_app \
      -p careconnect \
      -e "SELECT 1"

# Check database performance
mysql -h prod-db.region.rds.amazonaws.com \
      -u admin -p \
      -e "SHOW PROCESSLIST; SHOW ENGINE INNODB STATUS;"

# Check RDS metrics
aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name DatabaseConnections \
    --dimensions Name=DBInstanceIdentifier,Value=careconnect-prod-db \
    --start-time $(date -d '1 hour ago' --iso-8601) \
    --end-time $(date --iso-8601) \
    --period 300 \
    --statistics Average,Maximum
```

#### High Response Times

```bash
# Check ALB metrics
aws cloudwatch get-metric-statistics \
    --namespace AWS/ApplicationELB \
    --metric-name TargetResponseTime \
    --dimensions Name=LoadBalancer,Value=app/careconnect-prod/1234567890abcdef \
    --start-time $(date -d '1 hour ago' --iso-8601) \
    --end-time $(date --iso-8601) \
    --period 300 \
    --statistics Average,Maximum

# Check ECS service CPU/Memory usage
aws cloudwatch get-metric-statistics \
    --namespace AWS/ECS \
    --metric-name CPUUtilization \
    --dimensions Name=ServiceName,Value=careconnect-prod-service Name=ClusterName,Value=careconnect-prod \
    --start-time $(date -d '1 hour ago' --iso-8601) \
    --end-time $(date --iso-8601) \
    --period 300 \
    --statistics Average,Maximum

# Analyze application logs for slow queries
aws logs filter-log-events \
    --log-group-name "/ecs/careconnect-prod" \
    --filter-pattern "Query took longer than" \
    --start-time $(date -d '1 hour ago' +%s)000
```

### Diagnostic Tools

#### Health Check Script

```bash
#!/bin/bash
# scripts/health-check.sh

set -e

echo "Running comprehensive health check..."

# 1. API Health Check
echo "Checking API health..."
API_HEALTH=$(curl -s https://api.careconnect.example.com/actuator/health)
if echo "$API_HEALTH" | grep -q '"status":"UP"'; then
    echo "✅ API is healthy"
else
    echo "❌ API is unhealthy: $API_HEALTH"
    exit 1
fi

# 2. Database Health Check
echo "Checking database connectivity..."
DB_CHECK=$(mysql -h prod-db.region.rds.amazonaws.com \
               -u careconnect_app \
               -p$DB_PASSWORD \
               careconnect \
               -e "SELECT 1" 2>&1)
if [ $? -eq 0 ]; then
    echo "✅ Database is accessible"
else
    echo "❌ Database connection failed: $DB_CHECK"
    exit 1
fi

# 3. Cache Health Check
echo "Checking Redis connectivity..."
REDIS_CHECK=$(redis-cli -h prod-cache.region.cache.amazonaws.com ping 2>&1)
if [ "$REDIS_CHECK" = "PONG" ]; then
    echo "✅ Redis is responding"
else
    echo "❌ Redis connection failed: $REDIS_CHECK"
    exit 1
fi

# 4. ECS Service Health Check
echo "Checking ECS service status..."
RUNNING_TASKS=$(aws ecs describe-services \
    --cluster careconnect-prod \
    --services careconnect-prod-service \
    --query 'services[0].runningCount' \
    --output text)

DESIRED_TASKS=$(aws ecs describe-services \
    --cluster careconnect-prod \
    --services careconnect-prod-service \
    --query 'services[0].desiredCount' \
    --output text)

if [ "$RUNNING_TASKS" -eq "$DESIRED_TASKS" ]; then
    echo "✅ All ECS tasks are running ($RUNNING_TASKS/$DESIRED_TASKS)"
else
    echo "❌ ECS tasks mismatch: $RUNNING_TASKS/$DESIRED_TASKS running"
fi

# 5. Load Balancer Health Check
echo "Checking load balancer target health..."
HEALTHY_TARGETS=$(aws elbv2 describe-target-health \
    --target-group-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/careconnect-prod/1234567890abcdef \
    --query 'TargetHealthDescriptions[?TargetHealth.State==`healthy`] | length(@)' \
    --output text)

if [ "$HEALTHY_TARGETS" -gt 0 ]; then
    echo "✅ Load balancer has $HEALTHY_TARGETS healthy targets"
else
    echo "❌ No healthy targets in load balancer"
    exit 1
fi

# 6. SSL Certificate Check
echo "Checking SSL certificate validity..."
SSL_EXPIRY=$(echo | openssl s_client -servername careconnect.example.com -connect careconnect.example.com:443 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2)
SSL_EXPIRY_EPOCH=$(date -d "$SSL_EXPIRY" +%s)
CURRENT_EPOCH=$(date +%s)
DAYS_UNTIL_EXPIRY=$(( ($SSL_EXPIRY_EPOCH - $CURRENT_EPOCH) / 86400 ))

if [ "$DAYS_UNTIL_EXPIRY" -gt 30 ]; then
    echo "✅ SSL certificate is valid for $DAYS_UNTIL_EXPIRY more days"
else
    echo "⚠️  SSL certificate expires in $DAYS_UNTIL_EXPIRY days"
fi

echo "Health check completed successfully!"
```

---

*This deployment and operations guide provides comprehensive instructions for managing the CareConnect platform in production. Regular updates to this document ensure operational procedures remain current with infrastructure changes.*

*Last Updated: October 2025*
*Version: 2025.1.0*