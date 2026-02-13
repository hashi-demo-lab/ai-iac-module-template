output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "Bucket domain name (e.g., bucket.s3.amazonaws.com)"
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_id" {
  description = "Name/ID of the S3 bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_regional_domain_name" {
  description = "Regional bucket domain name (e.g., bucket.s3.us-east-1.amazonaws.com)"
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "website_domain" {
  description = "S3 website endpoint domain (for Route 53 alias records). Null when enable_website is false."
  value       = try(aws_s3_bucket_website_configuration.this[0].website_domain, null)
}

output "website_endpoint" {
  description = "S3 static website hosting endpoint. Null when enable_website is false. HTTP only; use CloudFront for HTTPS."
  value       = try(aws_s3_bucket_website_configuration.this[0].website_endpoint, null)
}
