# EventBridge Rules for different event patterns

# Order Events Rule
resource "aws_cloudwatch_event_rule" "order_events" {
  count = contains(var.event_patterns, "order") ? 1 : 0

  name           = "${var.project_name}-order-events"
  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    source      = ["order.service"]
    detail-type = ["OrderCreated", "OrderUpdated", "OrderCompleted", "OrderCancelled"]
  })

  tags = var.tags
}

# Payment Events Rule
resource "aws_cloudwatch_event_rule" "payment_events" {
  count = contains(var.event_patterns, "payment") ? 1 : 0

  name           = "${var.project_name}-payment-events"
  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    source      = ["payment.service"]
    detail-type = ["PaymentProcessed", "PaymentFailed", "RefundIssued"]
  })

  tags = var.tags
}

# Inventory Events Rule
resource "aws_cloudwatch_event_rule" "inventory_events" {
  count = contains(var.event_patterns, "inventory") ? 1 : 0

  name           = "${var.project_name}-inventory-events"
  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    source      = ["inventory.service"]
    detail-type = ["StockUpdated", "LowStockAlert", "OutOfStock"]
  })

  tags = var.tags
}

# Catch-all Analytics Rule
resource "aws_cloudwatch_event_rule" "analytics" {
  count = var.enable_analytics ? 1 : 0

  name           = "${var.project_name}-analytics-all-events"
  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    source = [{ prefix = "" }] # Match all sources
  })

  tags = merge(
    var.tags,
    {
      Purpose = "Analytics"
    }
  )
}
