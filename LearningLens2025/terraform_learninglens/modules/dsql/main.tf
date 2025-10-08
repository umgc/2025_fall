# ================================================================================
# DSQL Module - Aurora DSQL Cluster
# ================================================================================

# ================================================================================
# DATA SOURCES
# ================================================================================

data "aws_region" "current" {}

# ================================================================================
# LOCALS
# ================================================================================

locals {
  module_name       = "tf-aws/dsql"
  module_version    = file("${path.module}/RELEASE")
  module_maintainer = "learninglens"
  default_tags = {
    ModuleName       = local.module_name
    ModuleVersion    = local.module_version
    ModuleMaintainer = local.module_maintainer
  }
}

# ================================================================================
# Aurora DSQL Cluster
# ================================================================================

resource "aws_dsql_cluster" "main" {
  deletion_protection_enabled = var.deletion_protection_enabled
  
  tags = merge(local.default_tags, var.tags, {
    Name = var.cluster_name
  })
}

# ================================================================================
# IAM Role for DSQL Access (if create_iam_role is true)
# ================================================================================

data "aws_iam_policy_document" "dsql_assume_role" {
  count = var.create_iam_role ? 1 : 0
  
  statement {
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "dsql_policy" {
  count = var.create_iam_role ? 1 : 0
  
  statement {
    effect = "Allow"
    
    actions = [
      "dsql:DbConnect",
      "dsql:DbConnectAdmin"
    ]
    
    resources = [
      aws_dsql_cluster.main.arn
    ]
  }
}

module "dsql_iam_role" {
  count = var.create_iam_role ? 1 : 0
  
  source = "../iam"
  
  role_name           = "${var.cluster_name}-dsql-role"
  assume_role_policy  = data.aws_iam_policy_document.dsql_assume_role[0].json
  managed_policy_arns = var.additional_policy_arns
  custom_policies = {
    dsql_policy = {
      description = "IAM policy for DSQL access"
      policy      = data.aws_iam_policy_document.dsql_policy[0].json
    }
  }
  
  tags = merge(local.default_tags, var.tags)
}