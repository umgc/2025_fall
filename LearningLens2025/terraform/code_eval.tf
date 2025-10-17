# Get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Get the default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Get the default security group for the default VPC
data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
  filter {
    name   = "group-name"
    values = ["default"]
  }
}

# S3 bucket
resource "aws_s3_bucket" "edulense" {
  bucket_prefix = "edulense-"
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
          "arn:aws:s3:::${aws_s3_bucket.edulense.id}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:HeadObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.edulense.id}/*"
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

# Attach custom policy for s3 read/write access to code_evaluator role
resource "aws_iam_role_policy_attachment" "s3_read_write_code_evaluator" {
  role       = aws_iam_role.code_evaluator.name
  policy_arn = aws_iam_policy.edulense_rw.arn
}

# Attach custom policy for s3 read/write access to lambda role
resource "aws_iam_role_policy_attachment" "s3_read_write_lambda_token" {
  role       = aws_iam_role.lambda_token.name
  policy_arn = aws_iam_policy.edulense_rw.arn
}

# Attach AWS managed ECS Task Execution policy for ECS role
resource "aws_iam_role_policy_attachment" "attach_ecs_managed" {
  role       = aws_iam_role.code_evaluator.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Moodle service account username
variable "moodle_username" {
  type = string
}

# Moodle service account password
variable "moodle_password"{
  type = string
  sensitive = true
}

# Run npm install before zipping
resource "null_resource" "npm_install_code_eval" {
  triggers = {
    # Trigger npm install when package.json or lock file changes
    package_json = filemd5("../lambda/code_eval/package.json")
    package_lock = filemd5("../lambda/code_eval/package-lock.json")
  }

  provisioner "local-exec" {
    command = "cd ../lambda/code_eval && npm install"
  }
}

# lambda function for code evaluations
data "archive_file" "code_eval" {
  type = "zip"
  source_dir = "../lambda/code_eval/"
  excludes = ["../lambda/code_eval/code_eval.zip"]
  output_path = "../lambda/code_eval/code_eval.zip"

  depends_on = [null_resource.npm_install_code_eval]
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  role       = aws_iam_role.lambda_token.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_lambda_function" "code_eval_lambda" {
  filename = data.archive_file.code_eval.output_path
  function_name = "evaluate_code"
  role = aws_iam_role.lambda_token.arn
  handler = "index.handler"
  source_code_hash = data.archive_file.code_eval.output_base64sha256
  runtime = "nodejs20.x"
  timeout = "10"


  environment {
    variables = {
      ENVIRONMENT = "production"
      LOG_LEVEL = "info"
      AWS_DB_CLUSTER = format("%s.dsql.%s.on.aws", aws_dsql_cluster.edulense.identifier, data.aws_region.current.region)
      MOODLE_USERNAME = var.moodle_username
      MOODLE_PASSWORD = var.moodle_password
      MOODLE_URL = "http://${aws_instance.moodle_instance.public_dns}"
      ECS_TASK_NAME = aws_ecs_task_definition.eval_code_task.family
      ECS_CLUSTER_ARN = aws_ecs_cluster.eval_code_cluster.arn
      SUBNET_IDS      = join(",", data.aws_subnets.default.ids)
      SECURITY_GROUP_IDS = data.aws_security_group.default.id
      S3_BUCKET = aws_s3_bucket.edulense.bucket
    }
  }
}

resource "aws_lambda_function_url" "code_eval_url" {
  function_name = aws_lambda_function.code_eval_lambda.function_name
  authorization_type = "NONE"
  cors {
    allow_methods = ["GET", "POST", "DELETE"]
    allow_origins = ["*"]
    allow_headers = ["content-type"]
  }
}

# Logging for ECS containers
resource "aws_cloudwatch_log_group" "eval_code_logs" {
  name              = "/ecs/eval_code"
  retention_in_days = 14
}

resource "aws_ecs_task_definition" "eval_code_task" {
  family                   = "eval_code"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"   # 1 vCPU
  memory                   = "3072"   # 3 GB
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.code_evaluator.arn
  task_role_arn            = aws_iam_role.code_evaluator.arn
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "edulense_program_grader"
      image     = aws_ecr_repository.edulense_program_grader.repository_url
      essential = true

      environment = [
        {
          name  = "CODE_S3_URI"
          value = ""  # Fill this with the S3 URI at runtime
        },
        {
          name  = "LAMBDA_NAME"
          value = "" # Fill this with the name of the lambda function at runtime
        },
        {
          name  = "ASSIGNMENT_ID"
          value = "" # Fill this with id of the assignment the evalation is for at runtime
        },
        {
          name  = "COURSE_ID"
          value = "" # Fill this with id of the course the evalation is for at runtime
        },
        {
          name  = "LANGUAGE"
          value = "" # Fill this with programming language the submissions are supposed to be at runtime
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.eval_code_logs.name
          awslogs-region        = data.aws_region.current.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  
}

resource "aws_ecs_cluster" "eval_code_cluster" {
  name = "eval-code-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "eval_code_cluster" {
  cluster_name = aws_ecs_cluster.eval_code_cluster.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}

# Grant lambda permissions to start ECS tasks
data "aws_iam_policy_document" "lambda_ecs_permissions" {
  statement {
    effect = "Allow"

    actions = [
      "ecs:RunTask",
      "ecs:DescribeTasks",
    ]

    resources = [
      aws_ecs_cluster.eval_code_cluster.arn,
      "${aws_ecs_task_definition.eval_code_task.arn_without_revision}:*"
    ]
  }

  # Allow Lambda to pass the ECS task execution role
  statement {
    effect = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      aws_iam_role.code_evaluator.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = ["ecs:DescribeTaskDefinition"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lambda_ecs_permissions" {
  name   = "lambda-ecs-run-task"
  role   = aws_iam_role.lambda_token.id
  policy = data.aws_iam_policy_document.lambda_ecs_permissions.json
}

# Grant ECS permission to invoke lambda (for posting program assessment results)
data "aws_iam_policy_document" "ecs_invoke_lambda" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      aws_lambda_function.code_eval_lambda.arn
    ]
  }
}

resource "aws_iam_policy" "ecs_invoke_lambda" {
  name        = "ECSInvokeCodeEvalLambda"
  description = "Allow eval_c ECS task to invoke code_eval_lambda"
  policy      = data.aws_iam_policy_document.ecs_invoke_lambda.json
}

resource "aws_iam_role_policy_attachment" "ecs_invoke_lambda" {
  role       = aws_iam_role.code_evaluator.name
  policy_arn = aws_iam_policy.ecs_invoke_lambda.arn
}