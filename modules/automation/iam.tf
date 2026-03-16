# Cross-account role assumed by job task roles in member accounts.
# Grants the minimum permissions required to interact with the
# framework state store, messaging, and alerting.

resource "aws_iam_role" "automation_framework_access" {
  name = "AutomationFrameworkAccess"
  tags = local.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "*" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "aws:PrincipalOrgID" = var.org_id
        }
        "ForAnyValue:StringLike" = {
          "aws:PrincipalOrgPaths" = "${var.org_id}/*/${var.workload_ou_id}/*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "automation_framework_access" {
  name = "automation-framework-access"
  role = aws_iam_role.automation_framework_access.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBState"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
        ]
        Resource = [
          aws_dynamodb_table.operations.arn,
          "${aws_dynamodb_table.operations.arn}/index/*",
          aws_dynamodb_table.audit.arn,
          aws_dynamodb_table.locks.arn,
        ]
      },
      {
        Sid    = "SNSPublish"
        Effect = "Allow"
        Action = ["sns:Publish"]
        Resource = [
          aws_sns_topic.ops_events.arn,
          aws_sns_topic.ops_alerts.arn,
        ]
      },
      {
        Sid    = "SQSTrigger"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
        ]
        Resource = aws_sqs_queue.watcher_trigger.arn
      },
    ]
  })
}
