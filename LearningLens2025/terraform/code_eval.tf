# S3 bucket
resource "aws_s3_bucket" "edulense" {
  bucket = "edulense"
}

# IAM Policy for S3 read/write access
resource "aws_iam_policy" "edulense_rw" {
  name        = "EdulenseS3AccessPolicy"
  description = "Allow read/write access to the edulense bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::edulense"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::edulense/*"
        ]
      }
    ]
  })
}

# IAM Role for ECS Tasks
resource "aws_iam_role" "code_evaluator" {
  name = "CodeEvaluator"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach custom policy
resource "aws_iam_role_policy_attachment" "attach_custom" {
  role       = aws_iam_role.code_evaluator.name
  policy_arn = aws_iam_policy.edulense_rw.arn
}

# Attach AWS managed ECS Task Execution policy
resource "aws_iam_role_policy_attachment" "attach_ecs_managed" {
  role       = aws_iam_role.code_evaluator.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# lambda function for code evaluations
data "archive_file" "code_eval" {
  type = "zip"
  source_dir = "../lambda"
  excludes = ["../lambda/code_eval/code_eval.zip"]
  output_path = "../lambda/code_eval/code_eval.zip"
}
