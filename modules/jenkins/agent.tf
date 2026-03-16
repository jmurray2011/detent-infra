# Jenkins agent ECS task definition.
# The ECS cloud plugin launches these dynamically per build.

resource "aws_cloudwatch_log_group" "agent" {
  name              = "/ecs/detent-jenkins-agent"
  retention_in_days = 30
  tags              = local.tags
}

resource "aws_ecs_task_definition" "agent" {
  family                   = "detent-agent"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.agent_cpu
  memory                   = var.agent_memory
  execution_role_arn       = aws_iam_role.agent_execution.arn
  task_role_arn            = aws_iam_role.agent_task.arn
  tags                     = local.tags

  container_definitions = jsonencode([{
    name      = "agent"
    image     = var.agent_image
    essential = true

    environment = [
      { name = "AWS_DEFAULT_REGION", value = data.aws_region.current.name },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.agent.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "agent"
      }
    }
  }])
}

resource "aws_security_group" "agent" {
  name_prefix = "detent-jenkins-agent-"
  vpc_id      = var.vpc_id
  description = "Jenkins agents"
  tags        = local.tags

  # No ingress — agents initiate outbound connections to controller:50000

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
