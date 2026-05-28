output "ecr_repository_url" {
  description = "The URL of the ECR repository to push Docker images"
  value       = aws_ecr_repository.sast_scanner.repository_url
}

output "api_gateway_url" {
  description = "The public API Gateway URL to trigger code scans"
  value       = "${aws_apigatewayv2_api.sast_api.api_endpoint}/scan"
}

output "s3_bucket_name" {
  description = "Name of the S3 Bucket storing JSON vulnerability reports"
  value       = aws_s3_bucket.reports_bucket.id
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table storing scan summaries"
  value       = aws_dynamodb_table.scan_metadata.name
}

output "lambda_function_arn" {
  description = "The ARN of the deployed Lambda function"
  value       = aws_lambda_function.sast_scanner.arn
}
