resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.identifier}-subnet-group"
  })
}

resource "aws_db_parameter_group" "this" {
  name   = "${var.identifier}-params-${replace(var.parameter_group_family, ".", "-")}"
  family = var.parameter_group_family

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = var.tags
}

resource "aws_db_instance" "this" {
  identifier     = var.identifier
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  iops                  = var.iops
  storage_encrypted     = var.storage_encrypted

  db_name  = var.db_name
  username = var.username
  # Only set password when NOT using AWS managed password
  password = var.manage_master_user_password ? null : var.password
  port     = var.port

  # Only set manage_master_user_password when it's true
  manage_master_user_password = var.manage_master_user_password ? true : null

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.vpc_security_group_ids
  publicly_accessible    = var.publicly_accessible
  multi_az               = var.multi_az

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : var.final_snapshot_identifier

  parameter_group_name = aws_db_parameter_group.this.name

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  tags = merge(var.tags, {
    Name = var.identifier
  })
}
