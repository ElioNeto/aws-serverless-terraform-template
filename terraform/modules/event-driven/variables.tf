variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "event_patterns" {
  description = "List of event patterns to create rules for"
  type        = list(string)
  default     = ["order", "payment", "inventory"]
}

variable "enable_analytics" {
  description = "Enable catch-all analytics rule"
  type        = bool
  default     = true
}

variable "event_archive_retention_days" {
  description = "Number of days to retain events in archive"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
