# ==============================================================================
# Output values for interacting with the deployed system
# ==============================================================================

output "ecr_repository_url" {
  description = "ECR repository URL - use this to push Docker images"
  value       = module.ecr.repository_url
}

output "lambda_function_url" {
  description = "Public HTTPS Lambda Function URL to trigger code scans via POST"
  value       = module.lambda.function_url
}

output "s3_bucket_name" {
  description = "S3 bucket name storing the full JSON vulnerability reports"
  value       = module.s3.bucket_name
}

output "dynamodb_table_name" {
  description = "DynamoDB table name storing scan metadata summaries"
  value       = module.dynamodb.table_name
}

output "lambda_function_arn" {
  description = "ARN of the deployed SAST scanner Lambda function"
  value       = module.lambda.function_arn
}

output "sns_alerts_topic_arn" {
  description = "ARN of the SNS topic for alarm notifications"
  value       = module.monitoring.sns_topic_arn
}

output "vpc_id" {
  description = "ID of the SAST VPC (Milestone 2 network isolation)"
  value       = module.vpc.vpc_id
}

output "private_subnet_id" {
  description = "Private subnet where Lambda runs (no direct internet)"
  value       = module.vpc.private_subnet_id
}

output "security_group_id" {
  description = "Security group attached to Lambda for outbound access"
  value       = module.vpc.security_group_id
}

