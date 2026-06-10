variable "aws_region" {
  type        = string
  description = "AWS region – used to select AZs (e.g. us-east-1a / us-east-1b)"
  default     = "us-east-1"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags applied to all VPC resources"
  default     = {}
}
