module "app_security_group" {
  source = "./modules/security_group"
  vpc_id        = module.vpc.vpc_id
  name          = "${var.project}-app-sg"
  description   = "Security group for application EC2 instance"
  ingress_rules = var.ec2.ingress_rules
  egress_rules  = var.ec2.egress_rules
}

module "app_ec2" {
  source = "./modules/ec2"
  name                        = "${var.project}-app"
  instance_type               = var.ec2.instance_type
  subnet_id                   = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids      = [module.app_security_group.security_group_id]
  associate_public_ip_address = var.ec2.associate_public_ip_address
  monitoring                  = var.ec2.monitoring
  # AMI configuration
  ami_id = var.ec2.ami_id
  # Root volume configuration
  root_volume_size       = var.ec2.root_volume_size
  root_volume_type       = var.ec2.root_volume_type
  root_volume_encrypted  = var.ec2.root_volume_encrypted
  root_volume_throughput = 125
  root_volume_iops       = 3000
  # SSH Key configuration
  create_key_pair     = true
  key_name            = "${var.project}-app-key"
  ssh_key_output_path = "./keys"
  # Elastic IP configuration
  create_elastic_ip = var.ec2.create_elastic_ip
  # User data script
  user_data_template_path = var.ec2.user_data_script_path
}