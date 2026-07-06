output "alerts_topic_arn" { value = aws_sns_topic.alerts.arn }
output "app_log_group_name" { value = try(aws_cloudwatch_log_group.app[0].name, null) }
