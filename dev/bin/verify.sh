#!/bin/bash
# Verify LocalStack resources were seeded correctly.
set -euo pipefail

echo "=== DynamoDB Tables ==="
aws --endpoint-url=http://localhost:4566 dynamodb list-tables --output table

echo ""
echo "=== SNS Topics ==="
aws --endpoint-url=http://localhost:4566 sns list-topics --output table

echo ""
echo "=== SQS Queues ==="
aws --endpoint-url=http://localhost:4566 sqs list-queues --output table

echo ""
echo "=== SNS Subscriptions ==="
aws --endpoint-url=http://localhost:4566 sns list-subscriptions --output table
