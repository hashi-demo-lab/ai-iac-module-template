# Complete Example

This example demonstrates all features and optional configurations of the module.

## Usage

```hcl
module "this" {
  source = "../.."

  # All inputs demonstrated here
}
```

## Running This Example

```bash
terraform init
terraform plan
terraform apply
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_this"></a> [this](#module\_this) | ../.. | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region for provider configuration | `string` | `"us-east-1"` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the S3 bucket | `string` | n/a | yes |
| <a name="input_cors_allowed_origins"></a> [cors\_allowed\_origins](#input\_cors\_allowed\_origins) | List of allowed origins for CORS configuration | `list(string)` | <pre>[<br/>  "https://example.com",<br/>  "https://www.example.com"<br/>]</pre> | no |
| <a name="input_cost_center"></a> [cost\_center](#input\_cost\_center) | Cost center code for billing attribution | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Target deployment environment (dev, staging, prod) | `string` | n/a | yes |
| <a name="input_error_document"></a> [error\_document](#input\_error\_document) | Name of the error document for website hosting | `string` | `"404.html"` | no |
| <a name="input_index_document"></a> [index\_document](#input\_index\_document) | Name of the index document for website hosting | `string` | `"index.html"` | no |
| <a name="input_lifecycle_glacier_days"></a> [lifecycle\_glacier\_days](#input\_lifecycle\_glacier\_days) | Number of days after which objects transition to GLACIER storage class | `number` | `30` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Team or individual responsible for this bucket | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to all resources | `map(string)` | <pre>{<br/>  "Project": "website-demo",<br/>  "Team": "platform"<br/>}</pre> | no |
| <a name="input_versioning_enabled"></a> [versioning\_enabled](#input\_versioning\_enabled) | Enable object versioning on the bucket | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the S3 bucket |
| <a name="output_bucket_domain_name"></a> [bucket\_domain\_name](#output\_bucket\_domain\_name) | Bucket domain name |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | Name/ID of the S3 bucket |
| <a name="output_bucket_regional_domain_name"></a> [bucket\_regional\_domain\_name](#output\_bucket\_regional\_domain\_name) | Regional bucket domain name |
| <a name="output_website_domain"></a> [website\_domain](#output\_website\_domain) | S3 website endpoint domain (for Route 53 alias records) |
| <a name="output_website_endpoint"></a> [website\_endpoint](#output\_website\_endpoint) | S3 static website hosting endpoint (HTTP only) |
<!-- END_TF_DOCS -->
