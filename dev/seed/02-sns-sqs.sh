#!/bin/bash
# Mirrors modules/automation/sns.tf and sqs.tf in LocalStack.
set -euo pipefail

echo "Creating SNS topics..."
awslocal sns create-topic --name detent-ops-events
awslocal sns create-topic --name detent-ops-alerts
awslocal sns create-topic --name detent-watcher-trigger

echo "Creating SQS queues..."
awslocal sqs create-queue --queue-name detent-watcher-trigger-dlq

DLQ_ARN=$(awslocal sqs get-queue-attributes \
  --queue-url "http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/detent-watcher-trigger-dlq" \
  --attribute-names QueueArn \
  --query 'Attributes.QueueArn' --output text)

awslocal sqs create-queue \
  --queue-name detent-watcher-trigger \
  --attributes "{\"RedrivePolicy\":\"{\\\"deadLetterTargetArn\\\":\\\"${DLQ_ARN}\\\",\\\"maxReceiveCount\\\":\\\"3\\\"}\"}"

echo "Subscribing watcher-trigger queue to SNS topic..."
QUEUE_ARN=$(awslocal sqs get-queue-attributes \
  --queue-url "http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/detent-watcher-trigger" \
  --attribute-names QueueArn \
  --query 'Attributes.QueueArn' --output text)

TOPIC_ARN=$(awslocal sns list-topics --query "Topics[?ends_with(TopicArn, ':detent-watcher-trigger')].TopicArn" --output text)

awslocal sns subscribe \
  --topic-arn "$TOPIC_ARN" \
  --protocol sqs \
  --notification-endpoint "$QUEUE_ARN"

echo "SNS/SQS resources created."
