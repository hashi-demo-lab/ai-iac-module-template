variable "block_public_access" {
  description = "Block all public access to the bucket. Set to false to enable direct public website hosting. WARNING: Setting this to false allows public access to bucket contents when combined with enable_website. S3 website endpoints serve content over HTTP only, which transmits data unencrypted. Use CloudFront with HTTPS for production workloads requiring encryption in transit. Ensure you understand the security implications before disabling this setting."
  type        = bool
  default     = true
}

variable "bucket_name" {
  description = "Name of the S3 bucket. Must comply with AWS S3 bucket naming rules (lowercase, 3-63 chars, no reserved prefixes/suffixes)."
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 3 and 63 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must start and end with a lowercase letter or number, and contain only lowercase letters, numbers, hyphens, and periods."
  }

  validation {
    condition     = !can(regex("\\.\\.", var.bucket_name))
    error_message = "Bucket name must not contain two consecutive periods."
  }

  validation {
    condition     = !can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", var.bucket_name))
    error_message = "Bucket name must not be formatted as an IP address."
  }

  validation {
    condition     = !can(regex("^(xn--|sthree-|sthree-configurator|amzn-s3-demo-)", var.bucket_name))
    error_message = "Bucket name must not start with reserved prefixes."
  }

  validation {
    condition     = !can(regex("(-s3alias|--ol-s3|\\.mrap|--x-s3|--table-s3)$", var.bucket_name))
    error_message = "Bucket name must not end with reserved suffixes."
  }
}

variable "cors_allowed_origins" {
  description = "List of allowed origins for CORS configuration. Empty list disables CORS."
  type        = list(string)
  default     = []
}

variable "cost_center" {
  description = "Cost center code for billing attribution. Used as mandatory tag."
  type        = string

  validation {
    condition     = length(var.cost_center) > 0
    error_message = "Cost center must not be empty."
  }
}

variable "enable_website" {
  description = "Enable static website hosting configuration on the bucket. WARNING: S3 website endpoints serve content over HTTP only, which means data is transmitted unencrypted. For production workloads, use CloudFront with HTTPS to provide encryption in transit. Direct S3 website hosting should only be used for non-sensitive content or development environments."
  type        = bool
  default     = false
}

variable "environment" {
  description = "Target deployment environment. Must be one of: dev, staging, prod."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "error_document" {
  description = "Name of the error document for website hosting. Only used when enable_website is true."
  type        = string
  default     = "error.html"
}

variable "force_destroy" {
  description = "Allow destruction of non-empty bucket. Set to true only for testing."
  type        = bool
  default     = false
}

variable "index_document" {
  description = "Name of the index document for website hosting. Only used when enable_website is true."
  type        = string
  default     = "index.html"
}

variable "lifecycle_glacier_days" {
  description = "Number of days after which objects transition to GLACIER storage class. Set to 0 to disable lifecycle management."
  type        = number
  default     = 90

  validation {
    condition     = var.lifecycle_glacier_days >= 0
    error_message = "lifecycle_glacier_days must be a non-negative integer."
  }
}

variable "logging_target_bucket" {
  description = "Target S3 bucket name for server access logging. When null, access logging is disabled."
  type        = string
  default     = null
}

variable "logging_target_prefix" {
  description = "Prefix for access log object keys in the target bucket."
  type        = string
  default     = ""
}

variable "owner" {
  description = "Team or individual responsible for this bucket. Used as mandatory tag."
  type        = string

  validation {
    condition     = length(var.owner) > 0
    error_message = "Owner must not be empty."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources. Mandatory tags (Environment, Owner, CostCenter, ManagedBy) take precedence over consumer-provided tags with conflicting keys."
  type        = map(string)
  default     = {}
}

variable "versioning_enabled" {
  description = "Enable object versioning on the bucket. When false, versioning status is set to Suspended."
  type        = bool
  default     = true
}
