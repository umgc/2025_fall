locals {
  module_name       = "tf-aws/ec2"
  module_version    = file("${path.module}/RELEASE")
  module_maintainer = "learninglens"
  default_tags = {
    ModuleName       = local.module_name
    ModuleVersion    = local.module_version
    ModuleMaintainer = local.module_maintainer
  }
}



# Generate SSH key pair
resource "tls_private_key" "this" {
  count = var.create_key_pair ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  count = var.create_key_pair ? 1 : 0

  key_name   = var.key_name
  public_key = tls_private_key.this[0].public_key_openssh

  tags = merge(local.default_tags, var.tags, {
    Name = var.key_name
  })
}

# Create SSH directory if it doesn't exist
resource "local_file" "ssh_directory" {
  count = var.create_key_pair ? 1 : 0

  content  = ""
  filename = "${var.ssh_key_output_path}/.gitkeep"
}

# Save private key to local file
resource "local_file" "private_key" {
  count = var.create_key_pair ? 1 : 0

  content         = tls_private_key.this[0].private_key_pem
  filename        = "${var.ssh_key_output_path}/${var.key_name}.pem"
  file_permission = "0600"

  depends_on = [local_file.ssh_directory]
}

# EC2 Instance
resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.create_key_pair ? aws_key_pair.this[0].key_name : var.key_name
  monitoring                  = var.monitoring
  vpc_security_group_ids      = var.vpc_security_group_ids
  subnet_id                   = var.subnet_id
  associate_public_ip_address = var.associate_public_ip_address

  # User data script
  user_data_base64 = var.user_data_template_path != "" ? base64encode(templatefile(var.user_data_template_path, {
    project_name = var.project
    environment  = var.environment
  })) : (var.user_data != "" ? base64encode(var.user_data) : null)

  # Root block device configuration
  root_block_device {
    volume_type = var.root_volume_type
    volume_size = var.root_volume_size
    encrypted   = var.root_volume_encrypted
    throughput  = var.root_volume_type == "gp3" ? var.root_volume_throughput : null
    iops        = var.root_volume_type == "gp3" ? var.root_volume_iops : null
  }

  # Instance tags
  tags = merge(local.default_tags, var.tags, {
    Name = var.name
  })

  volume_tags = merge(local.default_tags, var.tags, {
    Name = "${var.name}-volume"
  })
}

# Elastic IP
resource "aws_eip" "this" {
  count = var.create_elastic_ip ? 1 : 0

  domain = "vpc"

  tags = merge(local.default_tags, var.tags, {
    Name = "${var.name}-eip"
  })
}

# Elastic IP Association
resource "aws_eip_association" "this" {
  count = var.create_elastic_ip ? 1 : 0

  instance_id   = aws_instance.this.id
  allocation_id = aws_eip.this[0].id
}