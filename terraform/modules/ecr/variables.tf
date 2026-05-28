variable "project_name" {
  type        = string
  description = "Project name used to name the ECR repository"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags applied to all resources"
  default     = {}
}
