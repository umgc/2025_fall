terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

# Optional OIDC provider for GitHub. Create it here only if you set create_oidc_provider = true.
resource "aws_iam_openid_connect_provider" "github" {
  count           = var.create_oidc_provider ? 1 : 0
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.github_thumbprints
}

locals {
  bucket_arn                 = "arn:aws:s3:::${var.bucket_name}"
  objects_arn                = "arn:aws:s3:::${var.bucket_name}/${var.s3_prefix}/*"
  github_oidc_provider_arn   = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
  repo_subject_filter        = var.allowed_ref == "*" ? "repo:${var.repo_owner}/${var.repo_name}:*" : "repo:${var.repo_owner}/${var.repo_name}:ref:${var.allowed_ref}"
}

# Optionally create the bucket
resource "aws_s3_bucket" "artifacts" {
  count  = var.create_bucket ? 1 : 0
  bucket = var.bucket_name
}

resource "aws_s3_bucket_versioning" "artifacts_versioning" {
  count  = var.create_bucket && var.enable_bucket_versioning ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# Trust policy that allows only your repo and ref
data "aws_iam_policy_document" "github_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.repo_subject_filter]
    }
  }
}

resource "aws_iam_role" "github_deploy_role" {
  name                 = "github-deploy-role"
  assume_role_policy   = data.aws_iam_policy_document.github_trust.json
  max_session_duration = 3600
  description          = "Role assumed by GitHub Actions to upload build zips to S3"
}

# S3 upload permissions limited to your bucket and prefix
data "aws_iam_policy_document" "s3_put" {
  statement {
    sid       = "AllowListAndLocation"
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [local.bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${var.s3_prefix}/*"]
    }
  }

  statement {
    sid       = "AllowPutObjectsUnderPrefix"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:AbortMultipartUpload"]
    resources = [local.objects_arn]
  }

  dynamic "statement" {
    for_each = var.kms_key_arn != "" ? [1] : []
    content {
      sid       = "AllowKmsForUploads"
      effect    = "Allow"
      actions   = ["kms:Encrypt", "kms:GenerateDataKey*", "kms:Decrypt"]
      resources = [var.kms_key_arn]
    }
  }
}

resource "aws_iam_role_policy" "s3_inline" {
  name   = "s3-upload-policy"
  role   = aws_iam_role.github_deploy_role.id
  policy = data.aws_iam_policy_document.s3_put.json
}
