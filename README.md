# Terraform Module: [module-name]

[Brief description of what this module creates and manages.]

## Features

- Feature 1
- Feature 2
- Secure defaults (encryption enabled, public access disabled)
- Conditional resource creation via `create_*` variables

## Usage

### Basic

```hcl
module "this" {
  source  = "app.terraform.io/<org-name>/<module-name>/<provider>"
  version = "~> 1.0"

  # Required inputs
  name = "my-resource"

  tags = {
    Environment = "dev"
    Application = "my-app"
    ManagedBy   = "terraform"
  }
}
```

### Complete

See [`examples/complete/`](./examples/complete/) for a full-featured example.

## Examples

- [Basic](./examples/basic/) - Minimal configuration with defaults
- [Complete](./examples/complete/) - All features and options demonstrated

## Testing

```bash
# Run unit tests (with mocks)
terraform test

# Run all pre-commit checks
pre-commit run --all-files
```

## Requirements

See [`terraform.tf`](./terraform.tf) for version constraints.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7 |

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->
