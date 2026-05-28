# ==============================================================================
# Data Sources
# ==============================================================================
data "aws_caller_identity" "current" {}

# Random suffix for globally unique S3 bucket name
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# ==============================================================================
# Module 1: ECR - Container Registry for the SAST Scanner Docker image
# ==============================================================================
module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
  common_tags  = var.common_tags
}

# ==============================================================================
# Module 2: S3 - Stores full JSON vulnerability reports
# ==============================================================================
module "s3" {
  source        = "./modules/s3"
  bucket_suffix = random_string.suffix.result
  common_tags   = var.common_tags
}

# ==============================================================================
# Module 3: DynamoDB - Stores scan metadata (scanId, counts, timestamps)
# ==============================================================================
module "dynamodb" {
  source      = "./modules/dynamodb"
  common_tags = var.common_tags
}

# ==============================================================================
# Module 4: Lambda - Runs the SAST scanner inside a Docker container
# ==============================================================================
module "lambda" {
  source              = "./modules/lambda"
  aws_account_id      = data.aws_caller_identity.current.account_id
  ecr_repository_url  = module.ecr.repository_url
  s3_bucket_name      = module.s3.bucket_name
  dynamodb_table_name = module.dynamodb.table_name
  common_tags         = var.common_tags

  depends_on = [module.ecr]
}

# ==============================================================================
# Module 5: API Gateway - Public HTTP endpoint for triggering scans
# ==============================================================================
module "api_gateway" {
  source               = "./modules/api_gateway"
  lambda_invoke_arn    = module.lambda.invoke_arn
  lambda_function_name = module.lambda.function_name
  common_tags          = var.common_tags

  depends_on = [module.lambda]
}
