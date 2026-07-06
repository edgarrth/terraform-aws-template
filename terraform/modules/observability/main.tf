resource "aws_cloudwatch_log_group" "app" {
  count             = var.create_container_log_group ? 1 : 0
  name              = "/apps/${var.name_prefix}/microservices"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.name_prefix}/cluster"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_sns_topic" "alerts" {
  name = "${var.name_prefix}-platform-alerts"
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "high_error_budget_placeholder" {
  alarm_name          = "${var.name_prefix}-placeholder-high-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  tags                = var.tags
}
