variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project naming convention"
  type        = string
  default     = "modern-serverless-boilerplate"
}