terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.92.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}

data "aws_ami" "moodle" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-moodle-4.5.6-r03-debian-12-amd64"]
  }

  owners = ["979382823631"]
}

resource "tls_private_key" "moodle-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "moodle-key-pair" {
  key_name   = "moodle-key-pair"
  public_key = tls_private_key.moodle-key.public_key_openssh
}

resource "aws_instance" "moodle_instance" {
  ami           = data.aws_ami.moodle.id
  instance_type = "t3.micro"
  tags = {
    Name = "SWEN670 Moodle Instance"
  }
  vpc_security_group_ids = [aws_security_group.moodle_security_group.id]
  key_name = aws_key_pair.moodle-key-pair.key_name
}

resource "aws_eip" "lb" {
  instance = aws_instance.moodle_instance.id
  domain   = "vpc"
}

resource "local_sensitive_file" "pem_file" {
  filename = pathexpand("~/.ssh/${aws_key_pair.moodle-key-pair.key_name}.pem")
  file_permission = "600"
  directory_permission = "700"
  content = tls_private_key.moodle-key.private_key_pem
}

resource "aws_security_group" "moodle_security_group" {
  name        = "moode-security-group"
  description = "Allow SSH, HTTP, HTTPS traffic"
  # Allow inbound traffic
  ingress {
    from_port   = 22      # SSH port
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH from anywhere
  }
  ingress {
    from_port   = 80      # HTTP port
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP from anywhere
  }
  ingress {
    from_port   = 443      # HTTPS port
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTPS from anywhere
  }
  # Allow outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # All protocols
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }
}

variable "github_token" {
  type = string
}

resource "aws_amplify_app" "edulenseweb" {
  name = "EduLenseApp"
  repository = "https://github.com/rappleb1/2025_fall/"
  access_token = var.github_token
  enable_branch_auto_build = true

  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - echo "Installing Flutter SDK"
            - git clone https://github.com/flutter/flutter.git -b stable --depth 1
            - export PATH="$PATH:$(pwd)/flutter/bin"
            - flutter config --no-analytics
            - flutter doctor
            - echo "Installing dependencies"
            - cd LearningLens2025/teamA/
            - flutter pub get
            - flutter create . --platforms web
        build:
          commands:
            - echo "Building Flutter web application"
            - echo "$ENV_FILE" > .env
            - export ENV_FILE=
            - flutter build web
      artifacts:
        baseDirectory: LearningLens2025/teamA/build/web/
        files:
          - '**/*'
          - '.env'
          - 'assets/.env'
    test:
      phases:
        test:
          commands:
            - echo "Exporting Artifacts"
      artifacts:
        baseDirectory: LearningLens2025/teamA/build/web/
        files:
          - '**/*'
          - '.env'
          - 'assets/.env'
    cache:
      paths:
        - flutter/.pub-cache
  EOT

  environment_variables = {
    ENV_FILE = file("../teamA/.env")
  }
}

resource "aws_amplify_branch" "master" {
  app_id      = aws_amplify_app.edulenseweb.id
  branch_name = "team_e"

  stage = "PRODUCTION"
}

data "aws_region" "current" {}

resource "aws_ecr_repository" "edulense_program_grader_java" {
  name = "edulense-program-grader-ecr-java"
}

resource "null_resource" "build_docker_java_image" {
  triggers = {
    script_hash = sha1(file("../docker/dockerupload.ps1"))
    docker_hash = sha1(file("../docker/Dockerjava"))
  }
  provisioner "local-exec" {
    working_dir = "../docker/"
    command = "powershell.exe -ExecutionPolicy Bypass -File ./dockerupload.ps1"
    environment = {
      AWS_REGION = replace(data.aws_region.current.name, "-", "-")
      AWS_REPO_URL = trimspace(aws_ecr_repository.edulense_program_grader_java.repository_url)
      AWS_REG_ID = trimspace(aws_ecr_repository.edulense_program_grader_java.registry_id)
      AWS_NAME = trimspace(aws_ecr_repository.edulense_program_grader_java.name)
      ENV_LANG = "java"
    }
  }
}

resource "time_sleep" "after_java" {
  triggers = {
    dep_id = null_resource.build_docker_java_image.id
  }
  create_duration = "10s"
}

resource "aws_ecr_repository" "edulense_program_grader_python" {
  name = "edulense-program-grader-ecr-python"
}

resource "null_resource" "build_docker_python_image" {
  triggers = {
    dep_id = time_sleep.after_java.triggers["dep_id"]
    script_hash = sha1(file("../docker/dockerupload.ps1"))
    docker_hash = sha1(file("../docker/Dockerpython"))
  }
  provisioner "local-exec" {
    working_dir = "../docker/"
    command = "powershell.exe -ExecutionPolicy Bypass -File ./dockerupload.ps1"
    environment = {
      AWS_REGION = replace(data.aws_region.current.name, "-", "-")
      AWS_REPO_URL = trimspace(aws_ecr_repository.edulense_program_grader_python.repository_url)
      AWS_REG_ID = trimspace(aws_ecr_repository.edulense_program_grader_python.registry_id)
      AWS_NAME = trimspace(aws_ecr_repository.edulense_program_grader_python.name)
      ENV_LANG = "python"
    }
  }
}

resource "time_sleep" "after_python" {
  triggers = {
    dep_id = null_resource.build_docker_python_image.id
  }
  create_duration = "10s"
}

resource "aws_ecr_repository" "edulense_program_grader_c" {
  name = "edulense-program-grader-ecr-c"
}

resource "null_resource" "build_docker_c_image" {
  triggers = {
    dep_id = time_sleep.after_python.triggers["dep_id"]
    script_hash = sha1(file("../docker/dockerupload.ps1"))
    docker_hash = sha1(file("../docker/Dockerc"))
  }
  provisioner "local-exec" {
    working_dir = "../docker/"
    command = "powershell.exe -ExecutionPolicy Bypass -File ./dockerupload.ps1"
    environment = {
      AWS_REGION = replace(data.aws_region.current.name, "-", "-")
      AWS_REPO_URL = trimspace(aws_ecr_repository.edulense_program_grader_c.repository_url)
      AWS_REG_ID = trimspace(aws_ecr_repository.edulense_program_grader_c.registry_id)
      AWS_NAME = trimspace(aws_ecr_repository.edulense_program_grader_c.name)
      ENV_LANG = "c"
    }
  }
}
