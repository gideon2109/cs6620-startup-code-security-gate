resource "aws_sqs_queue" "scan_dlq" {
  name                      = "sast-scan-dlq"
  message_retention_seconds = 1209600
  tags                      = var.common_tags
}

resource "aws_sqs_queue" "scan_queue" {
  name                      = "sast-scan-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 0

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.scan_dlq.arn
    maxReceiveCount     = 3
  })

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "dlq_alarm" {
  alarm_name          = "sast-dlq-messages-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0

  dimensions = {
    QueueName = aws_sqs_queue.scan_dlq.name
  }

  alarm_actions = [var.sns_topic_arn]
  tags          = var.common_tags
}
