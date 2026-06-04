variable "lambda_invoke_arn" {
  type        = string
  description = "The invoke ARN of the Lambda function to integrate with"
}

variable "lambda_function_name" {
  type        = string
  description = "The name of the Lambda function for permission grants"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags applied to all resources"
  default     = {}
}
