# SNS Topic for forwarding CloudWatch Alarm notifications
resource "aws_sns_topic" "alerts" {
  name         = "${var.project_name}-alerts"

  tags = var.common_tags
}

# Email subscription to the SNS Topic
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# 1. CloudWatch Metric Alarm for Lambda Errors
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.lambda_function_name}-errors-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60 # 1 minute
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "This alarm triggers if the SAST scanner Lambda experiences any execution errors."
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  tags = var.common_tags
}

# 2. CloudWatch Metric Alarm for Lambda Throttles
resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "${var.lambda_function_name}-throttles-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 60 # 1 minute
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "This alarm triggers if the SAST scanner Lambda is throttled due to concurrency limits."
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  tags = var.common_tags
}

# 3. CloudWatch Metric Alarm for Lambda Execution Duration (Latency / Cold starts)
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "${var.lambda_function_name}-high-duration-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 60 # 1 minute
  statistic           = "Average"
  threshold           = 15000 # 15 seconds (in milliseconds)
  alarm_description   = "This alarm triggers if the average scan duration exceeds 15 seconds."
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  tags = var.common_tags
}
