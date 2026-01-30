variable "table_name" {
  description = "The name of the DynamoDB table"
  type        = string
}

variable "environment" {
  description = "Environment tag (e.g., dev, prod)"
  type        = string
  default     = "dev"
}