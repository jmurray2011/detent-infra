output "ecs_cluster_arn" {
  value = aws_ecs_cluster.detent.arn
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.detent.name
}

output "jenkins_url" {
  value = var.certificate_arn != "" ? "https://${var.domain_name}" : "http://${aws_lb.jenkins.dns_name}"
}

output "alb_dns_name" {
  value = aws_lb.jenkins.dns_name
}

output "controller_security_group_id" {
  value = aws_security_group.controller.id
}

output "agent_security_group_id" {
  value = aws_security_group.agent.id
}

output "agent_task_definition_arn" {
  value = aws_ecs_task_definition.agent.arn
}

output "agent_task_role_arn" {
  value = aws_iam_role.agent_task.arn
}

output "controller_ecr_repository_url" {
  value = aws_ecr_repository.jenkins_controller.repository_url
}

output "agent_ecr_repository_url" {
  value = aws_ecr_repository.jenkins_agent.repository_url
}

output "private_subnet_ids" {
  value = var.private_subnet_ids
}
