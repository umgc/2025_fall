# Configure the AWS provider
provider "aws" {
  region = var.aws_region
}

# Get the current AWS account ID and region to build ARNs dynamically
data "aws_caller_identity" "current" {}

# 1. CONFIGURE GITHUB AS AN OIDC IDENTITY PROVIDER
# This tells your AWS account to trust GitHub's OIDC tokens.
# It's a one-time setup per AWS account. Terraform is smart enough not to
# re-create it if it already exists with this URL.
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # Standard thumbprint for GitHub OIDC
}

# 2. CREATE THE IAM POLICY FOR THE ROLE
# This policy defines what actions the role can perform. In this case, it's
# limited to uploading objects to a specific folder in your S3 bucket.
resource "aws_iam_policy" "github_actions_s3_policy" {
  name        = "GitHubActionsS3UploadPolicy"
  description = "Allows uploading files to the cc_backend_builds S3 folder."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:PutObject"
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/${var.s3_bucket_backend_folder}/*"
      },
      {
        Action   = "s3:PutObject"
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/${var.s3_bucket_frontend_folder}/*"
      },
    ]
  })
}

# 3. CREATE THE IAM ROLE
# This is the role that GitHub Actions will assume.
# It contains a trust policy that links it to the OIDC provider.
resource "aws_iam_role" "github_actions_role" {
  name = "GitHubActionsRole"

  # The trust policy is the most critical part for security.
  # It specifies that only GitHub Actions from your specific repository's
  # 'main' branch can assume this role.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringEquals = {
            # This condition restricts access to a specific repository and branch
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:ref:refs/heads/${var.github_branch}"
          }
        }
      },
    ]
  })
}

# 4. ATTACH THE POLICY TO THE ROLE
# This connects the permissions (the policy) to the identity (the role).
resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_actions_s3_policy.arn
}

resource "aws_s3_object" "backend_folder" {
  bucket = var.s3_bucket_name
  key    = "${var.s3_bucket_backend_folder}/"
  content = "" # Creates an empty object to represent the folder
}

resource "aws_s3_object" "frontend_folder" {
  bucket = var.s3_bucket_name
  key    = "${var.s3_bucket_frontend_folder}/"
  content = "" # Creates an empty object to represent the folder
}
