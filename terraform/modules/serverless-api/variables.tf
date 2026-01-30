variable "project_name" {
  description = "Project identifier for naming resources"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table to inject as Environment Variable"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for IAM permissions (Least Privilege)"
  type        = string
}