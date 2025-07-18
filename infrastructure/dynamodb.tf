resource "aws_dynamodb_table" "account_metadata" {
  name         = "AccountMetadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "requestId"

  attribute {
    name = "requestId"
    type = "S"
  }

  attribute {
    name = "accountId"
    type = "S"
  }

  global_secondary_index {
    name            = "AccountIdIndex"
    hash_key        = "accountId"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "AccountMetadata"
    Environment = "Production"
  }
}
