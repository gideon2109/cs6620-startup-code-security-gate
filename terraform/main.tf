# ==============================================================================
# Data Sources
# ==============================================================================
data "aws_caller_identity" "current" {}

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# Random suffix for globally unique S3 bucket name
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# ==============================================================================
# Locals & Shared Tags
# ==============================================================================
locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Course      = "CS6620-CloudComputing"
    Group       = "Group-9"
  }
}

# ==============================================================================
# Module 1: ECR
# ==============================================================================
module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
  common_tags  = local.common_tags
}

# ==============================================================================
# Module 2: S3 Reports
# ==============================================================================
module "s3" {
  source        = "./modules/s3"
  bucket_suffix = random_string.suffix.result
  common_tags   = local.common_tags
}

# ==============================================================================
# Module 3: DynamoDB
# ==============================================================================
module "dynamodb" {
  source      = "./modules/dynamodb"
  common_tags = local.common_tags
}

# ==============================================================================
# Module 4: VPC
# ==============================================================================
module "vpc" {
  source      = "./modules/vpc"
  common_tags = local.common_tags
}

# ==============================================================================
# Module 5: SQS
# ==============================================================================
module "sqs" {
  source        = "./modules/sqs"
  common_tags   = local.common_tags
  sns_topic_arn = module.monitoring.sns_topic_arn
}

# ==============================================================================
# Module 6: Lambda
# ==============================================================================
module "lambda" {
  source              = "./modules/lambda"
  aws_account_id      = local.aws_account_id
  ecr_repository_url  = module.ecr.repository_url
  s3_bucket_name      = module.s3.bucket_name
  dynamodb_table_name = module.dynamodb.table_name
  sns_topic_arn       = module.monitoring.sns_topic_arn
  sqs_queue_arn       = module.sqs.scan_queue_arn
  private_subnet_id   = module.vpc.private_subnet_id
  security_group_id   = module.vpc.security_group_id
  common_tags         = local.common_tags

  depends_on = [module.ecr]
}

# ==============================================================================
# Module 7: API Gateway
# ==============================================================================
module "api_gateway" {
  source               = "./modules/api_gateway"
  lambda_invoke_arn    = module.lambda.invoke_arn
  lambda_function_name = module.lambda.function_name
  sqs_queue_url        = module.sqs.scan_queue_url
  iam_role_arn         = data.aws_iam_role.lab_role.arn
  common_tags          = local.common_tags
}

# ==============================================================================
# Module 8: Monitoring (CloudWatch + SNS)
# ==============================================================================
module "monitoring" {
  source               = "./modules/monitoring"
  project_name         = var.project_name
  lambda_function_name = module.lambda.function_name
  alert_email          = var.alert_email
  common_tags          = local.common_tags
}

# ==============================================================================
# Module 9: Frontend S3 bucket
# ==============================================================================
module "frontend" {
  source      = "./modules/frontend"
  bucket_name = "group9-sast-frontend"
  common_tags = local.common_tags
}
