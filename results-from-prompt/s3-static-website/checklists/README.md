## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.32.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_cors_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_ownership_controls.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_website_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration) | resource |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_block_public_access"></a> [block\_public\_access](#input\_block\_public\_access) | Block all public access to the bucket. Set to false to enable direct public website hosting. WARNING: Setting this to false allows public access to bucket contents when combined with enable\_website. S3 website endpoints serve content over HTTP only, which transmits data unencrypted. Use CloudFront with HTTPS for production workloads requiring encryption in transit. Ensure you understand the security implications before disabling this setting. | `bool` | `true` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the S3 bucket. Must comply with AWS S3 bucket naming rules (lowercase, 3-63 chars, no reserved prefixes/suffixes). | `string` | n/a | yes |
| <a name="input_cors_allowed_origins"></a> [cors\_allowed\_origins](#input\_cors\_allowed\_origins) | List of allowed origins for CORS configuration. Empty list disables CORS. | `list(string)` | `[]` | no |
| <a name="input_cost_center"></a> [cost\_center](#input\_cost\_center) | Cost center code for billing attribution. Used as mandatory tag. | `string` | n/a | yes |
| <a name="input_enable_website"></a> [enable\_website](#input\_enable\_website) | Enable static website hosting configuration on the bucket. WARNING: S3 website endpoints serve content over HTTP only, which means data is transmitted unencrypted. For production workloads, use CloudFront with HTTPS to provide encryption in transit. Direct S3 website hosting should only be used for non-sensitive content or development environments. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Target deployment environment. Must be one of: dev, staging, prod. | `string` | n/a | yes |
| <a name="input_error_document"></a> [error\_document](#input\_error\_document) | Name of the error document for website hosting. Only used when enable\_website is true. | `string` | `"error.html"` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Allow destruction of non-empty bucket. Set to true only for testing. | `bool` | `false` | no |
| <a name="input_index_document"></a> [index\_document](#input\_index\_document) | Name of the index document for website hosting. Only used when enable\_website is true. | `string` | `"index.html"` | no |
| <a name="input_lifecycle_glacier_days"></a> [lifecycle\_glacier\_days](#input\_lifecycle\_glacier\_days) | Number of days after which objects transition to GLACIER storage class. Set to 0 to disable lifecycle management. | `number` | `90` | no |
| <a name="input_logging_target_bucket"></a> [logging\_target\_bucket](#input\_logging\_target\_bucket) | Target S3 bucket name for server access logging. When null, access logging is disabled. | `string` | `null` | no |
| <a name="input_logging_target_prefix"></a> [logging\_target\_prefix](#input\_logging\_target\_prefix) | Prefix for access log object keys in the target bucket. | `string` | `""` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Team or individual responsible for this bucket. Used as mandatory tag. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to all resources. Mandatory tags (Environment, Owner, CostCenter, ManagedBy) take precedence over consumer-provided tags with conflicting keys. | `map(string)` | `{}` | no |
| <a name="input_versioning_enabled"></a> [versioning\_enabled](#input\_versioning\_enabled) | Enable object versioning on the bucket. When false, versioning status is set to Suspended. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the S3 bucket |
| <a name="output_bucket_domain_name"></a> [bucket\_domain\_name](#output\_bucket\_domain\_name) | Bucket domain name (e.g., bucket.s3.amazonaws.com) |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | Name/ID of the S3 bucket |
| <a name="output_bucket_regional_domain_name"></a> [bucket\_regional\_domain\_name](#output\_bucket\_regional\_domain\_name) | Regional bucket domain name (e.g., bucket.s3.us-east-1.amazonaws.com) |
| <a name="output_website_domain"></a> [website\_domain](#output\_website\_domain) | S3 website endpoint domain (for Route 53 alias records). Null when enable\_website is false. |
| <a name="output_website_endpoint"></a> [website\_endpoint](#output\_website\_endpoint) | S3 static website hosting endpoint. Null when enable\_website is false. HTTP only; use CloudFront for HTTPS. |

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.32.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_cors_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_ownership_controls.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_website_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration) | resource |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_block_public_access"></a> [block\_public\_access](#input\_block\_public\_access) | Block all public access to the bucket. Set to false to enable direct public website hosting. WARNING: Setting this to false allows public access to bucket contents when combined with enable\_website. S3 website endpoints serve content over HTTP only, which transmits data unencrypted. Use CloudFront with HTTPS for production workloads requiring encryption in transit. Ensure you understand the security implications before disabling this setting. | `bool` | `true` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the S3 bucket. Must comply with AWS S3 bucket naming rules (lowercase, 3-63 chars, no reserved prefixes/suffixes). | `string` | n/a | yes |
| <a name="input_cors_allowed_origins"></a> [cors\_allowed\_origins](#input\_cors\_allowed\_origins) | List of allowed origins for CORS configuration. Empty list disables CORS. | `list(string)` | `[]` | no |
| <a name="input_cost_center"></a> [cost\_center](#input\_cost\_center) | Cost center code for billing attribution. Used as mandatory tag. | `string` | n/a | yes |
| <a name="input_enable_website"></a> [enable\_website](#input\_enable\_website) | Enable static website hosting configuration on the bucket. WARNING: S3 website endpoints serve content over HTTP only, which means data is transmitted unencrypted. For production workloads, use CloudFront with HTTPS to provide encryption in transit. Direct S3 website hosting should only be used for non-sensitive content or development environments. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Target deployment environment. Must be one of: dev, staging, prod. | `string` | n/a | yes |
| <a name="input_error_document"></a> [error\_document](#input\_error\_document) | Name of the error document for website hosting. Only used when enable\_website is true. | `string` | `"error.html"` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Allow destruction of non-empty bucket. Set to true only for testing. | `bool` | `false` | no |
| <a name="input_index_document"></a> [index\_document](#input\_index\_document) | Name of the index document for website hosting. Only used when enable\_website is true. | `string` | `"index.html"` | no |
| <a name="input_lifecycle_glacier_days"></a> [lifecycle\_glacier\_days](#input\_lifecycle\_glacier\_days) | Number of days after which objects transition to GLACIER storage class. Set to 0 to disable lifecycle management. | `number` | `90` | no |
| <a name="input_logging_target_bucket"></a> [logging\_target\_bucket](#input\_logging\_target\_bucket) | Target S3 bucket name for server access logging. When null, access logging is disabled. | `string` | `null` | no |
| <a name="input_logging_target_prefix"></a> [logging\_target\_prefix](#input\_logging\_target\_prefix) | Prefix for access log object keys in the target bucket. | `string` | `""` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Team or individual responsible for this bucket. Used as mandatory tag. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to all resources. Mandatory tags (Environment, Owner, CostCenter, ManagedBy) take precedence over consumer-provided tags with conflicting keys. | `map(string)` | `{}` | no |
| <a name="input_versioning_enabled"></a> [versioning\_enabled](#input\_versioning\_enabled) | Enable object versioning on the bucket. When false, versioning status is set to Suspended. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the S3 bucket |
| <a name="output_bucket_domain_name"></a> [bucket\_domain\_name](#output\_bucket\_domain\_name) | Bucket domain name (e.g., bucket.s3.amazonaws.com) |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | Name/ID of the S3 bucket |
| <a name="output_bucket_regional_domain_name"></a> [bucket\_regional\_domain\_name](#output\_bucket\_regional\_domain\_name) | Regional bucket domain name (e.g., bucket.s3.us-east-1.amazonaws.com) |
| <a name="output_website_domain"></a> [website\_domain](#output\_website\_domain) | S3 website endpoint domain (for Route 53 alias records). Null when enable\_website is false. |
| <a name="output_website_endpoint"></a> [website\_endpoint](#output\_website\_endpoint) | S3 static website hosting endpoint. Null when enable\_website is false. HTTP only; use CloudFront for HTTPS. |
<!-- END_TF_DOCS -->
