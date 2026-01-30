output "api_endpoint" {
  description = "The public HTTP URL of the API Gateway"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}

output "lambda_arn" {
  description = "The ARN of the backend Lambda function"
  value       = aws_lambda_function.api_handler.arn
}