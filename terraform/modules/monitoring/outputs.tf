output "sns_topic_arn" {
  description = "The ARN of the SNS topic for alarm notifications"
  value       = aws_sns_topic.alerts.arn
}
