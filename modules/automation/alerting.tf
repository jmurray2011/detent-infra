# Alerter downstream wiring — Slack Lambda + email subscriptions.

# --- Slack notifier Lambda ---

data "archive_file" "slack_notifier" {
  type        = "zip"
  source_file = "${path.module}/lambda/slack-notifier/handler.py"
  output_path = "${path.module}/lambda/slack-notifier/handler.zip"
}

resource "aws_iam_role" "slack_notifier" {
  name = "detent-slack-notifier-lambda"
  tags = local.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "slack_notifier" {
  name = "slack-notifier-policy"
  role = aws_iam_role.slack_notifier.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "Logs"
      Effect   = "Allow"
      Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "arn:aws:logs:*:*:*"
    }]
  })
}

variable "slack_webhook_url" {
  description = "Slack incoming webhook URL for alert notifications."
  type        = string
  default     = ""
  sensitive   = true
}

resource "aws_lambda_function" "slack_notifier" {
  function_name    = "detent-slack-notifier"
  handler          = "handler.handler"
  runtime          = "python3.10"
  role             = aws_iam_role.slack_notifier.arn
  filename         = data.archive_file.slack_notifier.output_path
  source_code_hash = data.archive_file.slack_notifier.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
    }
  }

  tags = local.tags
}

resource "aws_lambda_permission" "slack_notifier_alerts" {
  statement_id  = "AllowSNSInvokeAlerts"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.ops_alerts.arn
}

resource "aws_lambda_permission" "slack_notifier_events" {
  statement_id  = "AllowSNSInvokeEvents"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.ops_events.arn
}

# Subscribe to both topics
resource "aws_sns_topic_subscription" "slack_alerts" {
  topic_arn = aws_sns_topic.ops_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notifier.arn
}

resource "aws_sns_topic_subscription" "slack_events" {
  topic_arn = aws_sns_topic.ops_events.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notifier.arn
}

# --- Email subscriptions for ops-alerts ---

variable "alert_email_addresses" {
  description = "Email addresses to subscribe to ops-alerts for hard failures."
  type        = list(string)
  default     = []
}

resource "aws_sns_topic_subscription" "email_alerts" {
  for_each  = toset(var.alert_email_addresses)
  topic_arn = aws_sns_topic.ops_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}
