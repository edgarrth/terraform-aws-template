output "sns_topic_arn" { value = aws_sns_topic.domain_events.arn }
output "sqs_queue_arn" { value = aws_sqs_queue.domain_events.arn }
output "sqs_dlq_arn" { value = aws_sqs_queue.domain_events_dlq.arn }
