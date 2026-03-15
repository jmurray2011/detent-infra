# SQS-to-Jenkins trigger Lambda.
# Reads from the watcher-trigger SQS queue and calls the Jenkins API
# to invoke the appropriate Watcher job.

data "archive_file" "sqs_trigger" {
  type        = "zip"
  source_file = "${path.module}/lambda/sqs-trigger/handler.py"
  output_path = "${path.module}/lambda/sqs-trigger/handler.zip"
}

resource "aws_iam_role" "sqs_trigger" {
  name = "detent-sqs-trigger-lambda"
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

resource "aws_iam_role_policy" "sqs_trigger" {
  name = "sqs-trigger-policy"
  role = aws_iam_role.sqs_trigger.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SQSRead"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
        ]
        Resource = aws_sqs_queue.watcher_trigger.arn
      },
      {
        Sid      = "Logs"
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
    ]
  })
}

variable "jenkins_url" {
  description = "Jenkins base URL for the trigger Lambda."
  type        = string
  default     = "http://jenkins:8080"
}

variable "jenkins_user" {
  description = "Jenkins API user."
  type        = string
  default     = "admin"
}

variable "jenkins_token" {
  description = "Jenkins API token."
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "job_routes" {
  description = "JSON map of job_type to Jenkins job path."
  type        = string
  default     = "{\"LAMBDA_DEPLOY\": \"lambda-deploy/watcher\"}"
}

resource "aws_lambda_function" "sqs_trigger" {
  function_name    = "detent-sqs-trigger"
  handler          = "handler.handler"
  runtime          = "python3.10"
  role             = aws_iam_role.sqs_trigger.arn
  filename         = data.archive_file.sqs_trigger.output_path
  source_code_hash = data.archive_file.sqs_trigger.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      JENKINS_URL   = var.jenkins_url
      JENKINS_USER  = var.jenkins_user
      JENKINS_TOKEN = var.jenkins_token
      JOB_ROUTES    = var.job_routes
    }
  }

  tags = local.tags
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.watcher_trigger.arn
  function_name    = aws_lambda_function.sqs_trigger.arn
  batch_size       = 1
}
