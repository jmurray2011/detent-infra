# SCP definition and OU attachment.
# Deployed once to the management account.

variable "workload_ou_id" {
  description = "ID of the workload OU where the SCP is attached."
  type        = string
}

resource "aws_organizations_policy" "permission_boundary_enforcement" {
  name        = "detent-require-permission-boundary"
  description = "Requires permission boundary on all new IAM roles in the workload OU."
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyRoleCreationWithoutBoundary"
        Effect    = "Deny"
        Action    = "iam:CreateRole"
        Resource  = "*"
        Condition = {
          StringNotLike = {
            "iam:PermissionsBoundary" = "arn:aws:iam::*:policy/detent-permission-boundary"
          }
          # Exempt SSO admin roles and OrganizationAccountAccessRole
          # so Terraform can provision infrastructure roles that
          # then have the boundary attached.
          ArnNotLike = {
            "aws:PrincipalArn" = [
              "arn:aws:iam::*:role/OrganizationAccountAccessRole",
              "arn:aws:iam::*:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_AWSAdministratorAccess_*",
            ]
          }
        }
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "workload_ou" {
  policy_id = aws_organizations_policy.permission_boundary_enforcement.id
  target_id = var.workload_ou_id
}
