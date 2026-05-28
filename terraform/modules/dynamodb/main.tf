# DynamoDB Table for scan metadata (scanId, timestamps, severity counts)
resource "aws_dynamodb_table" "this" {
  name         = "sast-scan-metadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "scanId"

  attribute {
    name = "scanId"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = var.common_tags
}
