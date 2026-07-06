resource "aws_sns_topic" "domain_events" {
  name              = "${var.name_prefix}-domain-events-sns"
  kms_master_key_id = var.kms_key_arn
  tags              = merge(var.tags, { Name = "${var.name_prefix}-domain-events-sns" })
}

resource "aws_sqs_queue" "domain_events_dlq" {
  name                      = "${var.name_prefix}-domain-events-dlq"
  message_retention_seconds = var.dlq_retention_seconds
  kms_master_key_id         = var.kms_key_arn
  tags                      = merge(var.tags, { Name = "${var.name_prefix}-domain-events-dlq" })
}

resource "aws_sqs_queue" "domain_events" {
  name                       = "${var.name_prefix}-domain-events-sqs"
  message_retention_seconds  = var.queue_retention_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds
  kms_master_key_id          = var.kms_key_arn

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.domain_events_dlq.arn
    maxReceiveCount     = 5
  })

  tags = merge(var.tags, { Name = "${var.name_prefix}-domain-events-sqs" })
}

resource "aws_sns_topic_subscription" "domain_events_queue" {
  topic_arn = aws_sns_topic.domain_events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.domain_events.arn
}

data "aws_iam_policy_document" "allow_sns_to_sqs" {
  statement {
    sid     = "AllowSnsToSendMessages"
    effect  = "Allow"
    actions = ["sqs:SendMessage"]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    resources = [aws_sqs_queue.domain_events.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.domain_events.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "domain_events" {
  queue_url = aws_sqs_queue.domain_events.id
  policy    = data.aws_iam_policy_document.allow_sns_to_sqs.json
}
