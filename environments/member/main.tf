module "member_accounts" {
  source = "../../modules/member-accounts"

  automation_account_id = var.automation_account_id
}
