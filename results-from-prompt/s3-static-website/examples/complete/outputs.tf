output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.this.bucket_arn
}

output "bucket_domain_name" {
  description = "Bucket domain name"
  value       = module.this.bucket_domain_name
}

output "bucket_id" {
  description = "Name/ID of the S3 bucket"
  value       = module.this.bucket_id
}

output "bucket_regional_domain_name" {
  description = "Regional bucket domain name"
  value       = module.this.bucket_regional_domain_name
}

output "website_domain" {
  description = "S3 website endpoint domain (for Route 53 alias records)"
  value       = module.this.website_domain
}

output "website_endpoint" {
  description = "S3 static website hosting endpoint (HTTP only)"
  value       = module.this.website_endpoint
}
