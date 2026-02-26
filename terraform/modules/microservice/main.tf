# Reusable Microservice Module
# Creates Lambda, API Gateway, DynamoDB, and IAM resources for a microservice

locals {
  function_name = "${var.project_name}-${var.service_name}-${var.environment}"
}

# Lambda Function
resource "aws_lambda_function" "service" {
  filename         = var.lambda_config.filename
  function_name    = local.function_name
  role            = aws_iam_role.lambda.arn
  handler         = var.lambda_config.handler
  runtime         = var.lambda_config.runtime
  memory_size     = var.lambda_config.memory_size
  timeout         = var.lambda_config.timeout
  source_code_hash = filebase64sha256(var.lambda_config.filename)

  environment {
    variables = merge(
      {
        SERVICE_NAME = var.service_name
        ENVIRONMENT  = var.environment
        TABLE_NAME   = aws_dynamodb_table.service.name
      },
      var.environment_variables
    )
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = merge(
    var.tags,
    {
      Service = var.service_name
    }
  )
}

# Lambda Function URL (if enabled)
resource "aws_lambda_function_url" "service" {
  count = var.enable_function_url ? 1 : 0

  function_name      = aws_lambda_function.service.function_name
  authorization_type = var.function_url_auth_type

  cors {
    allow_credentials = true
    allow_origins     = var.cors_allowed_origins
    allow_methods     = ["*"]
    allow_headers     = ["*"]
    max_age           = 86400
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "service" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}
