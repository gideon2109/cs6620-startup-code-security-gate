variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "lambda_function_name" {
  type        = string
  description = "Name of the target Lambda function to monitor"
}

variable "alert_email" {
  type        = string
  description = "Email address to receive SNS alert notifications"
  default     = "gideon.gyakari@example.com"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags applied to monitoring resources"
  default     = {}
}
