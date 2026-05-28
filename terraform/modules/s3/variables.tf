variable "bucket_suffix" {
  type        = string
  description = "Random suffix appended to bucket name for global uniqueness"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags applied to all resources"
  default     = {}
}
