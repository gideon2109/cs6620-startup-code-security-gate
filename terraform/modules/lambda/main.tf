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

# Lambda Function URL (Public HTTPS endpoint for scans, replacing API Gateway)
resource "aws_lambda_function_url" "this" {
  function_name      = aws_lambda_function.this.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["POST", "OPTIONS"]
    allow_headers     = ["content-type"]
    max_age           = 86400
  }
}

# AWS Lambda Permission to allow public unauthenticated invokes on the Function URL
resource "aws_lambda_permission" "func_url" {
  statement_id           = "AllowFunctionURLInvoke"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.this.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}
