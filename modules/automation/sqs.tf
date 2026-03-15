# Per-job-type SQS queues and DLQs will be added here as job types
# are registered. This file contains the watcher trigger queue
# which all job types share.

resource "aws_sqs_queue" "watcher_trigger_dlq" {
  name = "detent-watcher-trigger-dlq"
  tags = local.tags
}

resource "aws_sqs_queue" "watcher_trigger" {
  name = "detent-watcher-trigger"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.watcher_trigger_dlq.arn
    maxReceiveCount     = 3
  })

  tags = local.tags
}

resource "aws_sns_topic_subscription" "watcher_trigger" {
  topic_arn = aws_sns_topic.watcher_trigger.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.watcher_trigger.arn
}
