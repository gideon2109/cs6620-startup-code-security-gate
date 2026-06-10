# Lambda Function
resource "aws_lambda_function" "this" {
  function_name = "sast-scanner-lambda"
  role          = "arn:aws:iam::${var.aws_account_id}:role/LabRole"
  package_type  = "Image"
  image_uri     = "${var.ecr_repository_url}:latest"
  timeout       = 30
  memory_size   = 512

  # Milestone 2: Place Lambda inside the private VPC subnet
  # Outbound traffic routes via NAT Gateway → Internet Gateway
  vpc_config {
    subnet_ids         = [var.private_subnet_id]
    security_group_ids = [var.security_group_id]
  }

  environment {
    variables = {
      S3_BUCKET_NAME      = var.s3_bucket_name
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
      SNS_TOPIC_ARN       = var.sns_topic_arn
    }
  }

  tags = var.common_tags
}

# Lambda Function URL (depends on Lambda function)
resource "aws_lambda_function_url" "this" {
  function_name      = aws_lambda_function.this.function_name
  authorization_type = "NONE"

  cors {
    allow_origins = ["*"]
    allow_methods = ["POST"]
    allow_headers = ["content-type", "application/json"]
    allow_credentials = false
    max_age = 86400
  }

  # This is fixed:Wait for Lambda function to be fully created
  depends_on = [aws_lambda_function.this]
}

# Permission 1: Allow public invocation of the Function URL
resource "aws_lambda_permission" "func_url" {
  statement_id           = "AllowFunctionURLInvoke"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.this.function_name
  principal              = "*"
  function_url_auth_type = "NONE"

  depends_on = [aws_lambda_function_url.this]
}
