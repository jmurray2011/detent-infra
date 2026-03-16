module "automation" {
  source = "../../modules/automation"

  workload_ou_arn            = var.workload_ou_arn
  workload_ou_id             = var.workload_ou_id
  org_id                     = var.org_id
  sweeper_image              = var.sweeper_image
  ecs_cluster_arn            = var.ecs_cluster_arn
  sweeper_subnet_ids         = var.sweeper_subnet_ids
  sweeper_security_group_ids = var.sweeper_security_group_ids
  jenkins_url                = var.jenkins_url
  jenkins_user               = var.jenkins_user
  jenkins_token              = var.jenkins_token
  job_routes                 = var.job_routes
  slack_webhook_url          = var.slack_webhook_url
  alert_email_addresses      = var.alert_email_addresses
}

output "operations_table_name" {
  value = module.automation.operations_table_name
}

output "automation_role_arn" {
  value = module.automation.automation_role_arn
}

output "codeartifact_domain_name" {
  value = module.automation.codeartifact_domain_name
}

output "sweeper_ecr_repository_url" {
  value = module.automation.sweeper_ecr_repository_url
}
