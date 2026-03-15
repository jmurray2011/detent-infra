#!/bin/bash
# Mirrors modules/automation/dynamodb.tf in LocalStack.
set -euo pipefail

ENDPOINT="http://localhost:4566"

echo "Creating detent-operations table..."
awslocal dynamodb create-table \
  --table-name detent-operations \
  --attribute-definitions \
    AttributeName=operationId,AttributeType=S \
    AttributeName=status,AttributeType=S \
    AttributeName=updatedAt,AttributeType=S \
  --key-schema AttributeName=operationId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --global-secondary-indexes '[
    {
      "IndexName": "status-updatedAt-index",
      "KeySchema": [
        {"AttributeName": "status", "KeyType": "HASH"},
        {"AttributeName": "updatedAt", "KeyType": "RANGE"}
      ],
      "Projection": {"ProjectionType": "ALL"}
    }
  ]'

echo "Creating detent-audit table..."
awslocal dynamodb create-table \
  --table-name detent-audit \
  --attribute-definitions \
    AttributeName=operationId,AttributeType=S \
    AttributeName=timestamp,AttributeType=S \
  --key-schema \
    AttributeName=operationId,KeyType=HASH \
    AttributeName=timestamp,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST

echo "Creating detent-locks table..."
awslocal dynamodb create-table \
  --table-name detent-locks \
  --attribute-definitions \
    AttributeName=lock_key,AttributeType=S \
  --key-schema AttributeName=lock_key,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

echo "DynamoDB tables created."
