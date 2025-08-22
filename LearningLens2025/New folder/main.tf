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
