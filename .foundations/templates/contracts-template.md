<!-- Placeholder convention: [BRACKETS] = human-authored content (instructions, descriptions).
     {{DOUBLE_BRACES}} = machine-filled values (timestamps, scores, IDs). -->

# Module Interface Specification

**Feature**: [FEATURE NAME]
**Date**: [DATE]
**Source**: Derived from plan.md resource inventory and spec.md requirements

## Module: {module_name}
**Registry Path:** `terraform-{provider}-{name}`
**Version:** `{version}`

### Inputs (Variables)
| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| name | string | yes | - | Name prefix for all resources |
| vpc_cidr | string | yes | - | CIDR block for the VPC |
| environment | string | yes | - | Environment name (e.g., dev, staging, prod) |
| tags | map(string) | no | {} | Additional tags to apply to all resources |
| enable_nat_gateway | bool | no | false | Whether to create NAT Gateway for private subnets |

### Outputs
| Output | Type | Sensitive | Description |
|--------|------|-----------|-------------|
| vpc_id | string | no | ID of the created VPC |
| public_subnet_ids | list(string) | no | IDs of created public subnets |
| private_subnet_ids | list(string) | no | IDs of created private subnets |

### Variable Validation Rules
| Variable | Validation | Error Message |
|----------|-----------|---------------|
| vpc_cidr | `can(cidrhost(var.vpc_cidr, 0))` | "Must be a valid CIDR block" |
| environment | `contains(["dev", "staging", "prod"], var.environment)` | "Must be dev, staging, or prod" |

## Resource Dependencies
<!-- Internal resource dependency flow: which resources depend on which within the module -->
| Resource | Depends On | Relationship |
|----------|-----------|--------------|
| aws_subnet.public | aws_vpc.this | Subnets created within VPC |
| aws_internet_gateway.this | aws_vpc.this | IGW attached to VPC |
| aws_route_table.public | aws_vpc.this, aws_internet_gateway.this | Routes traffic via IGW |
| aws_nat_gateway.this | aws_subnet.public, aws_eip.nat | NAT placed in public subnet |
| aws_route_table.private | aws_vpc.this, aws_nat_gateway.this | Routes traffic via NAT |

## Resource-to-Output Mapping
<!-- Shows which resources feed which outputs -->
| Resource | Attribute | Output |
|----------|-----------|--------|
| aws_vpc.this | id | vpc_id |
| aws_subnet.public | id | public_subnet_ids |
| aws_subnet.private | id | private_subnet_ids |
