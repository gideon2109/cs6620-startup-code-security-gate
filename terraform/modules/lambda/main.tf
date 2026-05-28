# Lambda Function running the SAST scanner from an ECR Docker image
resource "aws_lambda_function" "this" {
  function_name = "sast-scanner-lambda"
  role          = "arn:aws:iam::${var.aws_account_id}:role/LabRole"
  package_type  = "Image"
  image_uri     = "${var.ecr_repository_url}:latest"
  timeout       = 30
  memory_size   = 512

  environment {
    variables = {
      S3_BUCKET_NAME      = var.s3_bucket_name
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
    }
  }

  tags = var.common_tags
}
