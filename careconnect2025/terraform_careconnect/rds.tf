module "rds_security_group" {
  source = "./modules/security_group"

  vpc_id        = module.vpc.vpc_id
  name          = "${var.project}-rds-sg"
  description   = "Security group for RDS PostgreSQL database"
  ingress_rules = var.rds.ingress_rules
  egress_rules  = var.rds.egress_rules
}

module "database" {
  source = "./modules/rds"

  identifier     = var.rds.identifier
  engine         = var.rds.engine
  engine_version = var.rds.engine_version
  instance_class = var.rds.instance_class

  allocated_storage     = var.rds.allocated_storage
  max_allocated_storage = var.rds.max_allocated_storage
  storage_type          = var.rds.storage_type
  iops                  = var.rds.iops
  storage_encrypted     = var.rds.storage_encrypted

  db_name                     = var.rds.db_name
  username                    = var.rds.username
  password                    = var.rds.password
  port                        = var.rds.port
  manage_master_user_password = var.rds.manage_master_user_password

  subnet_ids             = module.vpc.private_subnet_ids
  vpc_security_group_ids = [module.rds_security_group.security_group_id]
  publicly_accessible    = var.rds.publicly_accessible
  multi_az               = var.rds.multi_az

  backup_retention_period = var.rds.backup_retention_period
  backup_window           = var.rds.backup_window
  maintenance_window      = var.rds.maintenance_window

  deletion_protection       = var.rds.deletion_protection
  skip_final_snapshot       = var.rds.skip_final_snapshot
  final_snapshot_identifier = var.rds.final_snapshot_identifier

  enabled_cloudwatch_logs_exports = var.rds.enabled_cloudwatch_logs_exports

  tags = local.default_tags
}
