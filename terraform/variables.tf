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

variable "alert_email" {
  type        = string
  description = "Email address to receive SNS alert notifications for Lambda failures/alarms"
  default     = "ntimgyakari.g@northeastern.edu"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags applied to all resources for tracking"
  default = {
    Project     = "startup-code-security-gate"
    Environment = "dev"
    ManagedBy   = "Terraform"
    Course      = "CS6620-CloudComputing"
    Group       = "Group-9"
  }
}
