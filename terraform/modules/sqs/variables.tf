variable "common_tags" {
  type    = map(string)
  default = {}
}

variable "sns_topic_arn" {
  type        = string
  description = "SNS topic ARN for DLQ alerts"
}
