output "event_bus_name" {
  description = "Name of the EventBridge event bus"
  value       = aws_cloudwatch_event_bus.main.name
}

output "event_bus_arn" {
  description = "ARN of the EventBridge event bus"
  value       = aws_cloudwatch_event_bus.main.arn
}

output "dlq_url" {
  description = "URL of the dead letter queue"
  value       = aws_sqs_queue.dlq.url
}

output "dlq_arn" {
  description = "ARN of the dead letter queue"
  value       = aws_sqs_queue.dlq.arn
}

output "event_archive_bucket" {
  description = "Name of the S3 bucket for event archives"
  value       = aws_s3_bucket.event_archive.bucket
}

output "order_rule_arn" {
  description = "ARN of the order events rule"
  value       = try(aws_cloudwatch_event_rule.order_events[0].arn, null)
}

output "payment_rule_arn" {
  description = "ARN of the payment events rule"
  value       = try(aws_cloudwatch_event_rule.payment_events[0].arn, null)
}

output "inventory_rule_arn" {
  description = "ARN of the inventory events rule"
  value       = try(aws_cloudwatch_event_rule.inventory_events[0].arn, null)
}
