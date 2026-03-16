# Jenkins controller ECS service on EC2.

resource "aws_cloudwatch_log_group" "controller" {
  name              = "/ecs/detent-jenkins-controller"
  retention_in_days = 30
  tags              = local.tags
}

resource "aws_ecs_task_definition" "controller" {
  family                   = "detent-jenkins-controller"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  execution_role_arn       = aws_iam_role.controller_execution.arn
  task_role_arn            = aws_iam_role.controller_task.arn
  tags                     = local.tags

  volume {
    name = "jenkins-home"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.jenkins_home.id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = aws_efs_access_point.jenkins_home.id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([{
    name      = "jenkins"
    image     = var.jenkins_image
    essential = true
    memory    = 1800

    portMappings = [
      { containerPort = 8080, hostPort = 8080, protocol = "tcp" },
      { containerPort = 50000, hostPort = 50000, protocol = "tcp" },
    ]

    mountPoints = [{
      sourceVolume  = "jenkins-home"
      containerPath = "/var/jenkins_home"
      readOnly      = false
    }]

    environment = [
      { name = "CASC_JENKINS_CONFIG", value = "/opt/casc/jenkins.yml" },
      { name = "JAVA_OPTS", value = "-Djenkins.install.runSetupWizard=false -Xmx1g" },
      { name = "JENKINS_URL", value = "https://${var.domain_name}/" },
      { name = "ECS_CLUSTER_ARN", value = aws_ecs_cluster.detent.arn },
      { name = "AGENT_TASK_DEFINITION_ARN", value = aws_ecs_task_definition.agent.arn },
      { name = "AGENT_SUBNET_IDS", value = join(",", var.private_subnet_ids) },
      { name = "AGENT_SECURITY_GROUP_ID", value = aws_security_group.agent.id },
      { name = "AWS_REGION", value = data.aws_region.current.name },
      { name = "AGENT_IMAGE", value = var.agent_image },
      { name = "AGENT_EXECUTION_ROLE_ARN", value = aws_iam_role.agent_execution.arn },
      { name = "AGENT_TASK_ROLE_ARN", value = aws_iam_role.agent_task.arn },
      { name = "DETENT_PIPELINES_REPO_URL", value = var.detent_pipelines_repo_url },
    ]

    secrets = [
      {
        name      = "JENKINS_ADMIN_PASSWORD"
        valueFrom = var.jenkins_admin_password_secret_arn
      },
    ]

    healthCheck = {
      command     = ["CMD-SHELL", "curl -sf http://localhost:8080/login || exit 1"]
      interval    = 30
      timeout     = 10
      retries     = 3
      startPeriod = 120
    }

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.controller.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "controller"
      }
    }
  }])
}

resource "aws_ecs_service" "controller" {
  name            = "detent-jenkins-controller"
  cluster         = aws_ecs_cluster.detent.id
  task_definition = aws_ecs_task_definition.controller.arn
  desired_count   = 1
  tags            = local.tags

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.controller.name
    weight            = 1
  }

  health_check_grace_period_seconds = 300

  load_balancer {
    target_group_arn = aws_lb_target_group.jenkins.arn
    container_name   = "jenkins"
    container_port   = 8080
  }

  enable_execute_command = true

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  ordered_placement_strategy {
    type  = "spread"
    field = "instanceId"
  }
}

resource "aws_security_group" "controller" {
  name_prefix = "detent-jenkins-ctrl-"
  vpc_id      = var.vpc_id
  description = "Jenkins controller EC2 instance"
  tags        = local.tags

  ingress {
    description     = "HTTP from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "JNLP from agents"
    from_port       = 50000
    to_port         = 50000
    protocol        = "tcp"
    security_groups = [aws_security_group.agent.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
