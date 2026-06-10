output "scan_queue_arn" {
  value = aws_sqs_queue.scan_queue.arn
}

output "scan_queue_url" {
  value = aws_sqs_queue.scan_queue.id
}

output "dlq_arn" {
  value = aws_sqs_queue.scan_dlq.arn
}
