module "org" {
  source = "../../modules/org"

  workload_ou_id = var.workload_ou_id
}

output "scp_id" {
  value = module.org.scp_id
}
