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
# Module 0: VPC – Network Isolation (Milestone 2)
# Private subnet for Lambda + NAT Gateway for secure outbound access
# ==============================================================================
module "vpc" {
  source      = "./modules/vpc"
  aws_region  = var.aws_region
  common_tags = local.common_tags
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
# Module 6: Monitoring (CloudWatch + SNS)
# Declared before Lambda so we can pass sns_topic_arn into Lambda env vars
# ==============================================================================
module "monitoring" {
  source               = "./modules/monitoring"
  project_name         = var.project_name
  lambda_function_name = "sast-scanner-lambda"
  alert_email          = var.alert_email
  common_tags          = local.common_tags
}

# ==============================================================================
# Module 4: Lambda
# Runs inside private VPC subnet; SNS ARN injected for vulnerability alerts
# ==============================================================================
module "lambda" {
  source              = "./modules/lambda"
  aws_account_id      = local.aws_account_id
  ecr_repository_url  = module.ecr.repository_url
  s3_bucket_name      = module.s3.bucket_name
  dynamodb_table_name = module.dynamodb.table_name
  private_subnet_id   = module.vpc.private_subnet_id
  security_group_id   = module.vpc.security_group_id
  sns_topic_arn       = module.monitoring.sns_topic_arn
  common_tags         = local.common_tags

  depends_on = [module.ecr, module.vpc]
}

# ==============================================================================
# Module 5: API Gateway
# ==============================================================================
module "api_gateway" {
  source               = "./modules/api_gateway"
  lambda_invoke_arn    = module.lambda.invoke_arn
  lambda_function_name = module.lambda.function_name
  common_tags          = local.common_tags
}

# ==============================================================================
# Module 7: Frontend S3 bucket
# ==============================================================================
module "frontend" {
  source      = "./modules/frontend"
  bucket_name = "group9-sast-frontend"
  common_tags = local.common_tags
}
