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
    allow_origins     = ["*"]
    allow_methods     = ["POST"]
    allow_headers     = ["content-type", "authorization"]
    expose_headers    = ["date", "x-amzn-requestid"]
    allow_credentials = false
    max_age           = 86400
  }

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

# ──────────────────────────────────────────────────────────────────────────────
# SQS Trigger: Lambda reads messages from SQS queue
# ──────────────────────────────────────────────────────────────────────────────
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.this.function_name
  batch_size       = 1
  enabled          = true

  tags = var.common_tags
}

# Permission 2: Allow public invocation of the underlying function via the URL

resource "aws_lambda_permission" "func_invoke_via_url" {
  statement_id  = "AllowInvokeViaFunctionURL"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "*"
}

# Lambda SQS trigger
