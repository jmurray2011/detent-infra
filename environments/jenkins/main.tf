module "network" {
  source = "../../modules/network"

  cidr_block         = var.cidr_block
  availability_zones = var.availability_zones
  domain_name        = var.domain_name
}

module "jenkins" {
  source = "../../modules/jenkins"

  vpc_id                 = module.network.vpc_id
  private_subnet_ids     = module.network.private_subnet_ids
  public_subnet_ids      = module.network.public_subnet_ids
  certificate_arn        = module.network.certificate_arn
  jenkins_image          = var.jenkins_image
  agent_image            = var.agent_image
  domain_name            = var.domain_name
  jenkins_admin_password_secret_arn = var.jenkins_admin_password_secret_arn
  automation_role_arn    = var.automation_role_arn
}

# --- Outputs ---

output "vpc_id" {
  value = module.network.vpc_id
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "name_servers" {
  description = "Delegate these NS records to complete DNS setup."
  value       = module.network.name_servers
}

output "ecs_cluster_arn" {
  value = module.jenkins.ecs_cluster_arn
}

output "jenkins_url" {
  value = module.jenkins.jenkins_url
}

output "alb_dns_name" {
  value = module.jenkins.alb_dns_name
}

output "controller_ecr_repository_url" {
  value = module.jenkins.controller_ecr_repository_url
}

output "agent_ecr_repository_url" {
  value = module.jenkins.agent_ecr_repository_url
}
