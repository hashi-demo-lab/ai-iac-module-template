variable "aws_region" {
  description = "AWS region for provider configuration"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "cors_allowed_origins" {
  description = "List of allowed origins for CORS configuration"
  type        = list(string)
  default     = ["https://example.com", "https://www.example.com"]
}

variable "cost_center" {
  description = "Cost center code for billing attribution"
  type        = string
}

variable "environment" {
  description = "Target deployment environment (dev, staging, prod)"
  type        = string
}

variable "error_document" {
  description = "Name of the error document for website hosting"
  type        = string
  default     = "404.html"
}

variable "index_document" {
  description = "Name of the index document for website hosting"
  type        = string
  default     = "index.html"
}

variable "lifecycle_glacier_days" {
  description = "Number of days after which objects transition to GLACIER storage class"
  type        = number
  default     = 30
}

variable "owner" {
  description = "Team or individual responsible for this bucket"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default = {
    Project = "website-demo"
    Team    = "platform"
  }
}

variable "versioning_enabled" {
  description = "Enable object versioning on the bucket"
  type        = bool
  default     = true
}
