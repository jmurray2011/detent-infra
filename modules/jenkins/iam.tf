# IAM roles for Jenkins controller and agents.

# --- EC2 instance profile for the controller container instance ---

resource "aws_iam_role" "controller_instance" {
  name = "detent-jenkins-controller-instance"
  tags = local.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "controller_instance_ecs" {
  role       = aws_iam_role.controller_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "controller_instance_ssm" {
  role       = aws_iam_role.controller_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "controller_instance" {
  name = "detent-jenkins-controller-instance"
  role = aws_iam_role.controller_instance.name
  tags = local.tags
}

# --- Controller execution role (pull image + write logs) ---

resource "aws_iam_role" "controller_execution" {
  name = "detent-jenkins-controller-execution"
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

resource "aws_iam_role_policy_attachment" "controller_execution" {
  role       = aws_iam_role.controller_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "controller_execution_secrets" {
  name = "secrets-access"
  role = aws_iam_role.controller_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "ReadJenkinsSecrets"
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = [var.jenkins_admin_password_secret_arn]
    }]
  })
}

# --- Controller task role (ECS plugin needs to launch agents) ---

resource "aws_iam_role" "controller_task" {
  name = "detent-jenkins-controller-task"
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

resource "aws_iam_role_policy" "controller_task" {
  name = "controller-task-policy"
  role = aws_iam_role.controller_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECSClusterScoped"
        Effect = "Allow"
        Action = [
          "ecs:RunTask",
          "ecs:StopTask",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:DescribeContainerInstances",
          "ecs:TagResource",
        ]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "ecs:cluster" = aws_ecs_cluster.detent.arn
          }
        }
      },
      {
        Sid    = "ECSGlobal"
        Effect = "Allow"
        Action = [
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition",
          "ecs:DeregisterTaskDefinition",
        ]
        Resource = "*"
      },
      {
        Sid    = "PassAgentRoles"
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = [
          aws_iam_role.agent_task.arn,
          aws_iam_role.agent_execution.arn,
        ]
      },
      {
        Sid    = "AgentLogs"
        Effect = "Allow"
        Action = ["logs:GetLogEvents"]
        Resource = "${aws_cloudwatch_log_group.agent.arn}:*"
      },
      {
        Sid    = "EFSAccess"
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
        ]
        Resource = aws_efs_file_system.jenkins_home.arn
      },
    ]
  })
}

# --- Agent execution role (pull image + write logs) ---

resource "aws_iam_role" "agent_execution" {
  name = "detent-jenkins-agent-execution"
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

resource "aws_iam_role_policy_attachment" "agent_execution" {
  role       = aws_iam_role.agent_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- Agent task role (what job code can do) ---

resource "aws_iam_role" "agent_task" {
  name = "detent-jenkins-agent-task"
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

resource "aws_iam_role_policy" "agent_task" {
  name = "agent-task-policy"
  role = aws_iam_role.agent_task.id

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
        Resource = "arn:aws:dynamodb:*:*:table/detent-*"
      },
      {
        Sid    = "SNS"
        Effect = "Allow"
        Action = ["sns:Publish", "sns:ListTopics"]
        Resource = "arn:aws:sns:*:*:detent-*"
      },
      {
        Sid    = "SQS"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
        ]
        Resource = "arn:aws:sqs:*:*:detent-*"
      },
      {
        Sid      = "CrossAccount"
        Effect   = "Allow"
        Action   = ["sts:AssumeRole"]
        Resource = var.automation_role_arn != "" ? [var.automation_role_arn] : ["arn:aws:iam::*:role/AutomationFrameworkAccess"]
      },
    ]
  })
}
