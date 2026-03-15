# State table — single table for all operations across all job types.
resource "aws_dynamodb_table" "operations" {
  name         = "detent-operations"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "operationId"

  attribute {
    name = "operationId"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "updatedAt"
    type = "S"
  }

  global_secondary_index {
    name            = "status-updatedAt-index"
    hash_key        = "status"
    range_key       = "updatedAt"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = local.tags
}

# Audit trail table — immutable append of every state transition.
resource "aws_dynamodb_table" "audit" {
  name         = "detent-audit"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "operationId"
  range_key    = "timestamp"

  attribute {
    name = "operationId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = local.tags
}

# Resource lock table.
resource "aws_dynamodb_table" "locks" {
  name         = "detent-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "lock_key"

  attribute {
    name = "lock_key"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = local.tags
}
