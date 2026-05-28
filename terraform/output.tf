# ==============================================================================
# Output values for interacting with the deployed system
# ==============================================================================

output "ecr_repository_url" {
  description = "ECR repository URL - use this to push Docker images"
  value       = module.ecr.repository_url
}

output "api_gateway_url" {
  description = "Public API Gateway URL to trigger code scans via POST"
  value       = module.api_gateway.scan_url
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
