variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket for frontend hosting"
  default     = "group9-sast-frontend"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags applied to all resources"
  default = {
    Project   = "startup-code-security-gate"
    Group     = "Group-9"
    Course    = "CS6620-CloudComputing"
    ManagedBy = "Terraform"
  }
}
