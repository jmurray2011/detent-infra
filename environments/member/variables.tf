variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "target_account_role_arn" {
  description = "Role ARN to assume in the target member account."
  type        = string
}

variable "automation_account_id" {
  description = "Account ID of the automation account."
  type        = string
}
