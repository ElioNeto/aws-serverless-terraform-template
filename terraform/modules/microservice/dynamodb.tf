# DynamoDB Table for Microservice

resource "aws_dynamodb_table" "service" {
  name           = "${var.project_name}-${var.service_name}-${var.environment}"
  billing_mode   = var.database_config.billing_mode
  hash_key       = var.database_config.hash_key
  range_key      = var.database_config.range_key

  # Read/Write capacity (only for PROVISIONED mode)
  read_capacity  = var.database_config.billing_mode == "PROVISIONED" ? var.database_config.read_capacity : null
  write_capacity = var.database_config.billing_mode == "PROVISIONED" ? var.database_config.write_capacity : null

  # Attributes
  dynamic "attribute" {
    for_each = var.database_config.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  # Global Secondary Indexes
  dynamic "global_secondary_index" {
    for_each = var.database_config.global_secondary_indexes
    content {
      name            = global_secondary_index.value.name
      hash_key        = global_secondary_index.value.hash_key
      range_key       = global_secondary_index.value.range_key
      projection_type = global_secondary_index.value.projection_type
      read_capacity   = var.database_config.billing_mode == "PROVISIONED" ? global_secondary_index.value.read_capacity : null
      write_capacity  = var.database_config.billing_mode == "PROVISIONED" ? global_secondary_index.value.write_capacity : null
    }
  }

  # Enable Streams if configured
  dynamic "stream" {
    for_each = var.database_config.stream_enabled ? [1] : []
    content {
      enabled   = true
      view_type = var.database_config.stream_view_type
    }
  }

  # TTL
  dynamic "ttl" {
    for_each = var.database_config.ttl_enabled ? [1] : []
    content {
      attribute_name = var.database_config.ttl_attribute
      enabled        = true
    }
  }

  # Point-in-time Recovery
  point_in_time_recovery {
    enabled = var.enable_pitr
  }

  # Server-side Encryption
  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  tags = merge(
    var.tags,
    {
      Service = var.service_name
    }
  )
}

# DynamoDB Stream Lambda Trigger (if enabled)
resource "aws_lambda_event_source_mapping" "dynamodb_stream" {
  count = var.database_config.stream_enabled && var.enable_stream_processing ? 1 : 0

  event_source_arn  = aws_dynamodb_table.service.stream_arn
  function_name     = aws_lambda_function.service.arn
  starting_position = "LATEST"

  filter_criteria {
    filter {
      pattern = jsonencode({
        eventName = ["INSERT", "MODIFY"]
      })
    }
  }

  maximum_batching_window_in_seconds = 1
  batch_size                         = 10
  parallelization_factor             = 1

  destination_config {
    on_failure {
      destination_arn = var.stream_dlq_arn
    }
  }
}
