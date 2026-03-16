# Shared ECS cluster with EC2 (controller) and Fargate (agents, Sweeper).

resource "aws_ecs_cluster" "detent" {
  name = "detent"
  tags = local.tags

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "detent" {
  cluster_name = aws_ecs_cluster.detent.name

  capacity_providers = [
    aws_ecs_capacity_provider.controller.name,
    "FARGATE",
  ]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}

# --- EC2 capacity provider for the controller ---

resource "aws_ecs_capacity_provider" "controller" {
  name = "detent-controller"
  tags = local.tags

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.controller.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 100
    }
  }
}

# --- Launch template for the controller EC2 instance ---

data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

resource "aws_launch_template" "controller" {
  name_prefix   = "detent-jenkins-ctrl-"
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = var.controller_instance_type
  tags          = local.tags

  key_name = var.controller_key_name != "" ? var.controller_key_name : null

  iam_instance_profile {
    arn = aws_iam_instance_profile.controller_instance.arn
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.controller.id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "ECS_CLUSTER=${aws_ecs_cluster.detent.name}" >> /etc/ecs/ecs.config
    echo "ECS_ENABLE_TASK_IAM_ROLE=true" >> /etc/ecs/ecs.config
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.tags, { Name = "detent-jenkins-controller" })
  }
}

# --- ASG: single instance for the controller ---

resource "aws_autoscaling_group" "controller" {
  name_prefix      = "detent-jenkins-ctrl-"
  min_size         = 1
  max_size         = 1
  desired_capacity = 1

  vpc_zone_identifier = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.controller.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }

  protect_from_scale_in = true

  lifecycle {
    create_before_destroy = true
  }
}
