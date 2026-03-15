resource "aws_sns_topic" "ops_events" {
  name = "detent-ops-events"
  tags = local.tags
}

resource "aws_sns_topic" "ops_alerts" {
  name = "detent-ops-alerts"
  tags = local.tags
}

resource "aws_sns_topic" "watcher_trigger" {
  name = "detent-watcher-trigger"
  tags = local.tags
}
