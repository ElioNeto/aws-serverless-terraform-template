output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.service.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.service.function_name
}

output "lambda_function_url" {
  description = "Function URL (if enabled)"
  value       = try(aws_lambda_function_url.service[0].function_url, null)
}

output "table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.service.name
}

output "table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.service.arn
}

output "table_stream_arn" {
  description = "ARN of the DynamoDB Stream"
  value       = try(aws_dynamodb_table.service.stream_arn, null)
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda.arn
}

output "lambda_role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda.name
}
