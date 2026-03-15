# Permission boundary policy distributed via CloudFormation StackSet
# to all accounts in the workload OU.

variable "automation_account_id" {
  description = "Account ID of the automation account (for cross-account role ARN)."
  type        = string
}

resource "aws_iam_policy" "permission_boundary" {
  name        = "detent-permission-boundary"
  description = "Hard cap on permissions for all detent automation job roles."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAutomationServices"
        Effect = "Allow"
        Action = [
          "ec2:*",
          "ecr:*",
          "ssm:*",
          "dynamodb:*",
          "sns:*",
          "sqs:*",
          "autoscaling:*",
          "s3:*",
          "codeartifact:*",
          "imagebuilder:*",
          "sts:AssumeRole",
        ]
        Resource = "*"
      },
      {
        Sid      = "DenyDangerousServices"
        Effect   = "Deny"
        Action   = [
          "iam:*",
          "organizations:*",
          "aws-portal:*",
          "budgets:*",
          "account:*",
        ]
        Resource = "*"
      }
    ]
  })
}
