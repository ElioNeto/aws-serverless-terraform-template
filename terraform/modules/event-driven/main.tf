# Event-Driven Architecture Module
# EventBridge-based event processing with multiple consumers

resource "aws_cloudwatch_event_bus" "main" {
  name = "${var.project_name}-${var.environment}-event-bus"

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-event-bus"
      Pattern = "event-driven"
    }
  )
}

# Event Archive for replay capability
resource "aws_cloudwatch_event_archive" "main" {
  name             = "${var.project_name}-${var.environment}-archive"
  event_source_arn = aws_cloudwatch_event_bus.main.arn
  retention_days   = var.event_archive_retention_days
}

# Dead Letter Queue for failed events
resource "aws_sqs_queue" "dlq" {
  name                       = "${var.project_name}-${var.environment}-event-dlq"
  message_retention_seconds  = 1209600 # 14 days
  visibility_timeout_seconds = 300

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-dlq"
    }
  )
}

# S3 bucket for long-term event storage
resource "aws_s3_bucket" "event_archive" {
  bucket = "${var.project_name}-${var.environment}-event-archive-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-event-archive"
    }
  )
}

resource "aws_s3_bucket_versioning" "event_archive" {
  bucket = aws_s3_bucket.event_archive.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "event_archive" {
  bucket = aws_s3_bucket.event_archive.id

  rule {
    id     = "archive-to-glacier"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    transition {
      days          = 180
      storage_class = "DEEP_ARCHIVE"
    }
  }
}

data "aws_caller_identity" "current" {}
