# ================================================================
# AURORA DSQL CLUSTER MODULE
# ================================================================
module "dsql_cluster" {
  source = "./modules/dsql"

  cluster_name                = var.dsql.cluster_name
  deletion_protection_enabled = var.dsql.deletion_protection_enabled
  create_iam_role            = var.dsql.create_iam_role
  additional_policy_arns     = var.dsql.additional_policy_arns

  environment = var.environment
  project     = var.project
  owner       = var.owner
  tags        = local.default_tags
}
