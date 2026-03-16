#!/bin/bash
# Deploy the SQS trigger Lambda with empty routes.
# Job repos register their own routes via their dev/seed.sh scripts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HANDLER_DIR="$SCRIPT_DIR/../../modules/automation/lambda/sqs-trigger"

echo "Packaging SQS trigger Lambda..."
TMPDIR=$(mktemp -d)
cp "$HANDLER_DIR/handler.py" "$TMPDIR/"
cd "$TMPDIR" && zip -q handler.zip handler.py

echo "Creating IAM role..."
awslocal iam create-role \
  --role-name detent-sqs-trigger-lambda \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
  2>/dev/null || true

echo "Creating SQS trigger Lambda (empty routes)..."
awslocal lambda create-function \
  --function-name detent-sqs-trigger \
  --runtime python3.10 \
  --role arn:aws:iam::000000000000:role/detent-sqs-trigger-lambda \
  --handler handler.handler \
  --zip-file "fileb://$TMPDIR/handler.zip" \
  --timeout 30 \
  --environment 'Variables={JENKINS_URL=http://jenkins:8080,JENKINS_USER=admin,JENKINS_TOKEN=admin,JOB_ROUTES={}}' \
  2>/dev/null || true

# Wire SQS queue to Lambda
QUEUE_ARN=$(awslocal sqs get-queue-attributes \
  --queue-url http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/detent-watcher-trigger \
  --attribute-names QueueArn \
  --query 'Attributes.QueueArn' \
  --output text 2>/dev/null)

if [ -n "$QUEUE_ARN" ]; then
  echo "Wiring SQS -> Lambda..."
  awslocal lambda create-event-source-mapping \
    --function-name detent-sqs-trigger \
    --event-source-arn "$QUEUE_ARN" \
    --batch-size 1 \
    2>/dev/null || true
fi

rm -rf "$TMPDIR"

echo "SQS trigger Lambda deployed. Job repos will register routes."
