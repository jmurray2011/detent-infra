#!/bin/bash
# Create a test Lambda function for integration testing.
set -euo pipefail

echo "Creating test Lambda function..."

# Create a minimal zip with a handler
TMPDIR=$(mktemp -d)
cat > "$TMPDIR/handler.py" << 'PYEOF'
def handler(event, context):
    return {"statusCode": 200, "body": "ok"}
PYEOF

cd "$TMPDIR" && zip -q handler.zip handler.py

# Create IAM role
awslocal iam create-role \
  --role-name test-lambda-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
  2>/dev/null || true

# Create function
awslocal lambda create-function \
  --function-name test-function \
  --runtime python3.10 \
  --role arn:aws:iam::000000000000:role/test-lambda-role \
  --handler handler.handler \
  --zip-file "fileb://$TMPDIR/handler.zip" \
  2>/dev/null || true

rm -rf "$TMPDIR"

echo "Lambda test function created."
