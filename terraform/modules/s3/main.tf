# S3 Bucket for storing full JSON vulnerability reports
resource "aws_s3_bucket" "this" {
  bucket        = "sast-reports-${var.bucket_suffix}"
  force_destroy = true

  tags = var.common_tags
}

# Lifecycle rule: auto-delete reports after 30 days to save costs
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "reports-retention"
    status = "Enabled"

    filter {}

    expiration {
      days = 30
    }
  }
}
