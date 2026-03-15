output "operations_table_name" {
  value = aws_dynamodb_table.operations.name
}

output "operations_table_arn" {
  value = aws_dynamodb_table.operations.arn
}

output "audit_table_arn" {
  value = aws_dynamodb_table.audit.arn
}

output "locks_table_arn" {
  value = aws_dynamodb_table.locks.arn
}

output "ops_events_topic_arn" {
  value = aws_sns_topic.ops_events.arn
}

output "ops_alerts_topic_arn" {
  value = aws_sns_topic.ops_alerts.arn
}

output "watcher_trigger_topic_arn" {
  value = aws_sns_topic.watcher_trigger.arn
}

output "watcher_trigger_queue_arn" {
  value = aws_sqs_queue.watcher_trigger.arn
}
