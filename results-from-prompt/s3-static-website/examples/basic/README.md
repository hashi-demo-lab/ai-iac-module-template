# Basic Example

This example demonstrates the minimum viable usage of the module with default settings.

## Usage

```hcl
module "this" {
  source = "../.."

  # Required inputs here
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
| <a name="input_cost_center"></a> [cost\_center](#input\_cost\_center) | Cost center code for billing attribution | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Target deployment environment (dev, staging, prod) | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Team or individual responsible for this bucket | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the S3 bucket |
| <a name="output_bucket_domain_name"></a> [bucket\_domain\_name](#output\_bucket\_domain\_name) | Bucket domain name |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | Name/ID of the S3 bucket |
| <a name="output_bucket_regional_domain_name"></a> [bucket\_regional\_domain\_name](#output\_bucket\_regional\_domain\_name) | Regional bucket domain name |
| <a name="output_website_domain"></a> [website\_domain](#output\_website\_domain) | S3 website endpoint domain |
| <a name="output_website_endpoint"></a> [website\_endpoint](#output\_website\_endpoint) | S3 static website hosting endpoint |
<!-- END_TF_DOCS -->
