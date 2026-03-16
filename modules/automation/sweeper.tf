# Sweeper ECS scheduled task — scans for stuck operations every 5 minutes.

# --- ECR repository for Sweeper image ---

resource "aws_ecr_repository" "sweeper" {
  name                 = "detent-sweeper"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false
  tags                 = local.tags

  image_scanning_configuration {
    scan_on_push = true
  }
}

# --- CloudWatch log group ---

resource "aws_cloudwatch_log_group" "sweeper" {
  name              = "/ecs/detent-sweeper"
  retention_in_days = 30
  tags              = local.tags
}

# --- ECS task role (what the Sweeper code can do) ---

resource "aws_iam_role" "sweeper_task" {
  name = "detent-sweeper-task"
  tags = local.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "sweeper_task" {
  name = "sweeper-task-policy"
  role = aws_iam_role.sweeper_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDB"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
        ]
        Resource = [
          aws_dynamodb_table.operations.arn,
          "${aws_dynamodb_table.operations.arn}/index/*",
          aws_dynamodb_table.audit.arn,
          aws_dynamodb_table.locks.arn,
        ]
      },
      {
        Sid    = "SNSPublish"
        Effect = "Allow"
        Action = ["sns:Publish"]
        Resource = [
          aws_sns_topic.ops_events.arn,
          aws_sns_topic.ops_alerts.arn,
          aws_sns_topic.watcher_trigger.arn,
        ]
      },
      {
        Sid    = "SQSReadDLQ"
        Effect = "Allow"
        Action = [
          "sqs:GetQueueAttributes",
          "sqs:ListQueues",
        ]
        Resource = "arn:aws:sqs:*:*:detent-*"
      },
    ]
  })
}

# --- ECS execution role (pull image + write logs) ---

resource "aws_iam_role" "sweeper_execution" {
  name = "detent-sweeper-execution"
  tags = local.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "sweeper_execution" {
  role       = aws_iam_role.sweeper_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- ECS task definition ---

resource "aws_ecs_task_definition" "sweeper" {
  family                   = "detent-sweeper"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.sweeper_execution.arn
  task_role_arn            = aws_iam_role.sweeper_task.arn
  tags                     = local.tags

  container_definitions = jsonencode([{
    name      = "sweeper"
    image     = var.sweeper_image
    essential = true

    command = ["python", "-m", "detent.sweeper"]

    environment = [
      { name = "AWS_DEFAULT_REGION", value = data.aws_region.current.name },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.sweeper.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "sweeper"
      }
    }
  }])
}

data "aws_region" "current" {}

# --- EventBridge Scheduler (every 5 minutes) ---

resource "aws_iam_role" "sweeper_scheduler" {
  name = "detent-sweeper-scheduler"
  tags = local.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "sweeper_scheduler" {
  name = "sweeper-scheduler-policy"
  role = aws_iam_role.sweeper_scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "RunTask"
        Effect = "Allow"
        Action = ["ecs:RunTask"]
        Resource = aws_ecs_task_definition.sweeper.arn
        Condition = {
          ArnEquals = {
            "ecs:cluster" = var.ecs_cluster_arn
          }
        }
      },
      {
        Sid    = "PassRole"
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = [
          aws_iam_role.sweeper_task.arn,
          aws_iam_role.sweeper_execution.arn,
        ]
      },
    ]
  })
}

resource "aws_scheduler_schedule" "sweeper" {
  name       = "detent-sweeper"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "rate(5 minutes)"

  target {
    arn      = var.ecs_cluster_arn
    role_arn = aws_iam_role.sweeper_scheduler.arn

    ecs_parameters {
      task_definition_arn = aws_ecs_task_definition.sweeper.arn
      launch_type         = "FARGATE"

      network_configuration {
        subnets          = var.sweeper_subnet_ids
        security_groups  = var.sweeper_security_group_ids
        assign_public_ip = false
      }
    }
  }
}
