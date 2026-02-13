variable "aws_region" {
  description = "AWS region for provider configuration"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "cost_center" {
  description = "Cost center code for billing attribution"
  type        = string
}

variable "environment" {
  description = "Target deployment environment (dev, staging, prod)"
  type        = string
}

variable "owner" {
  description = "Team or individual responsible for this bucket"
  type        = string
}
