# ==============================================================================
# Locals & Shared Tags
# ==============================================================================
locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  
  # Standardized metadata tags for better tracking and cleanup on AWS
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Course      = "CS6620-CloudComputing"
    Group       = "Group-9"
  }

# Fetch AWS account details automatically
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Generate a random suffix for globally unique S3 bucket name
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# ==============================================================================
# 1. AWS ECR Repository
# ==============================================================================
resource "aws_ecr_repository" "sast_scanner" {
  name                 = "${var.project_name}-repo"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # Facilitates easy cleanup of the lab environment

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

# ==============================================================================
# 2. S3 Bucket for JSON Reports
# ==============================================================================
resource "aws_s3_bucket" "reports_bucket" {
  bucket        = "sast-reports-${random_string.suffix.result}"
  force_destroy = true # Automatically empty bucket when deleting stack

  tags = local.common_tags
}

# S3 Lifecycle rule to clean up objects after 30 days (saves costs)
resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
  bucket = aws_s3_bucket.reports_bucket.id

  rule {
    id     = "reports-retention"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

# ==============================================================================
# 3. DynamoDB Table for Scan Metadata
# ==============================================================================
resource "aws_dynamodb_table" "scan_metadata" {
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

  tags = local.common_tags
}

# ==============================================================================
# 4. AWS Lambda Function (Docker Container)
# ==============================================================================
resource "aws_lambda_function" "sast_scanner" {
  function_name = "sast-scanner-lambda"
  role          = "arn:aws:iam::${local.aws_account_id}:role/LabRole"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.sast_scanner.repository_url}:latest"
  timeout       = 30
  memory_size   = 512

  environment {
    variables = {
      S3_BUCKET_NAME      = aws_s3_bucket.reports_bucket.id
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.scan_metadata.name
    }
  }

  # Ensure ECR image exists first before creating the Lambda function
  depends_on = [
    aws_ecr_repository.sast_scanner
  ]

  tags = local.common_tags
}

# ==============================================================================
# 5. API Gateway (HTTP API) Endpoint
# ==============================================================================
resource "aws_apigatewayv2_api" "sast_api" {
  name          = "sast-scanner-api"
  protocol_type = "HTTP"
  
  tags = local.common_tags
}

resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.sast_api.id
  name        = "$default"
  auto_deploy = true
  
  tags = local.common_tags
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.sast_api.id
  integration_type = "AWS_PROXY"

  integration_uri        = aws_lambda_function.sast_scanner.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "scan_route" {
  api_id    = aws_apigatewayv2_api.sast_api.id
  route_key = "POST /scan"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# ==============================================================================
# 6. Permissions (Allow API Gateway -> Lambda)
# ==============================================================================
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sast_scanner.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.sast_api.execution_arn}/*/*"
}
