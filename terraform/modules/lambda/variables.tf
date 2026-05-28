variable "aws_account_id" {
  type        = string
  description = "AWS Account ID for constructing the LabRole ARN"
}

variable "ecr_repository_url" {
  type        = string
  description = "ECR repository URL where the Docker image is stored"
}

variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket for storing scan reports"
}

variable "dynamodb_table_name" {
  type        = string
  description = "Name of the DynamoDB table for storing scan metadata"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags applied to all resources"
  default     = {}
}
