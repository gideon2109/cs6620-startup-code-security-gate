variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Deployment environment name"
  default     = "dev"
}

variable "project_name" {
  type        = string
  description = "Name of the project"
  default     = "startup-code-security-gate"
}
