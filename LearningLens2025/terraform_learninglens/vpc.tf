module "vpc" {
  source = "./modules/vpc"

  vpc_name = "${var.project}-vpc-${var.environment}"
  vpc_cidr = var.vpc_cidr

  public_subnets = var.public_subnets
  private_subnets = var.private_subnets
  enable_dns_hostnames = true
  create_nat_gateway = var.create_nat_gateway
}