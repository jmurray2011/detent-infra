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

output "automation_role_arn" {
  value = aws_iam_role.automation_framework_access.arn
}

output "codeartifact_domain_name" {
  value = aws_codeartifact_domain.detent.domain
}

output "codeartifact_repository_name" {
  value = aws_codeartifact_repository.detent_lib.repository
}

output "sweeper_task_definition_arn" {
  value = aws_ecs_task_definition.sweeper.arn
}

output "sweeper_log_group_name" {
  value = aws_cloudwatch_log_group.sweeper.name
}

output "sweeper_ecr_repository_url" {
  value = aws_ecr_repository.sweeper.repository_url
}
