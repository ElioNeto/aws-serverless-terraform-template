variable "project_name" {
  description = "Project name"
  type        = string
}

variable "service_name" {
  description = "Microservice name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "lambda_config" {
  description = "Lambda function configuration"
  type = object({
    filename    = string
    handler     = string
    runtime     = string
    memory_size = number
    timeout     = number
  })
}

variable "database_config" {
  description = "DynamoDB configuration"
  type = object({
    billing_mode   = string
    hash_key       = string
    range_key      = optional(string)
    read_capacity  = optional(number)
    write_capacity = optional(number)
    attributes = list(object({
      name = string
      type = string
    }))
    global_secondary_indexes = optional(list(object({
      name            = string
      hash_key        = string
      range_key       = optional(string)
      projection_type = string
      read_capacity   = optional(number)
      write_capacity  = optional(number)
    })), [])
    stream_enabled    = optional(bool, false)
    stream_view_type  = optional(string, "NEW_AND_OLD_IMAGES")
    ttl_enabled       = optional(bool, false)
    ttl_attribute     = optional(string, "expiresAt")
  })
}

variable "environment_variables" {
  description = "Additional environment variables for Lambda"
  type        = map(string)
  default     = {}
}

variable "vpc_config" {
  description = "VPC configuration for Lambda"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "enable_function_url" {
  description = "Enable Lambda Function URL"
  type        = bool
  default     = false
}

variable "function_url_auth_type" {
  description = "Authorization type for Function URL"
  type        = string
  default     = "AWS_IAM"
}

variable "cors_allowed_origins" {
  description = "Allowed origins for CORS"
  type        = list(string)
  default     = ["*"]
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 30
}

variable "enable_pitr" {
  description = "Enable Point-in-Time Recovery for DynamoDB"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
  default     = null
}

variable "enable_stream_processing" {
  description = "Enable DynamoDB stream processing"
  type        = bool
  default     = false
}

variable "stream_dlq_arn" {
  description = "ARN of DLQ for stream processing failures"
  type        = string
  default     = null
}

variable "custom_iam_policies" {
  description = "List of custom IAM policy JSON documents"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
