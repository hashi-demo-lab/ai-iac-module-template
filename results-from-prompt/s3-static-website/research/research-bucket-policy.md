## Research: What is the correct aws_s3_bucket_policy for public s3:GetObject access for static website hosting, and how should it be conditionally created?

### Decision
Use `aws_s3_bucket_policy` with a `data.aws_iam_policy_document` granting `s3:GetObject` to principal `"*"`, conditionally created with `count = (var.enable_website && !var.block_public_access) ? 1 : 0`. The `aws_s3_bucket_public_access_block` must have `block_public_policy = false` and `restrict_public_buckets = false` for the policy to be accepted by AWS, and the policy resource must use `depends_on` to ensure correct ordering.

### Resources Identified
- **Primary Resource**: `aws_s3_bucket_policy` -- attaches the public read policy to the bucket
- **Supporting Resources**:
  - `data.aws_iam_policy_document` -- generates the IAM policy JSON with proper structure
  - `aws_s3_bucket_public_access_block` -- must be configured to allow public policies before the bucket policy is applied
- **Key Arguments**:
  - `bucket` (required) -- name/ID of the S3 bucket
  - `policy` (required) -- JSON policy document; use `data.aws_iam_policy_document.*.json`
- **Key Outputs**: `aws_s3_bucket_policy` exports no additional attributes beyond its arguments
- **Security Considerations**:
  - The bucket policy grants world-readable access to all objects (`s3:GetObject` with principal `"*"`); this must only be created when the consumer explicitly opts in via both `enable_website = true` and `block_public_access = false`
  - `block_public_policy` must be `false` on the public access block or AWS will reject the `PutBucketPolicy` API call
  - `restrict_public_buckets` must be `false` or AWS will restrict access to only AWS service principals and the bucket owner, negating the public policy

### IAM Policy Document Structure

```hcl
data "aws_iam_policy_document" "public_read" {
  count = (var.enable_website && !var.block_public_access) ? 1 : 0

  statement {
    sid       = "PublicReadGetObject"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "public_read" {
  count  = (var.enable_website && !var.block_public_access) ? 1 : 0
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.public_read[0].json

  depends_on = [aws_s3_bucket_public_access_block.this]
}
```

Key details for the policy document:
- **Principal**: Use `type = "*"` with `identifiers = ["*"]` to render `"Principal": "*"` (anonymous access). Using `type = "AWS"` with `identifiers = ["*"]` renders `"Principal": {"AWS": "*"}` which has subtly different behavior in some contexts.
- **Resource**: Must target `${bucket_arn}/*` (objects), not the bucket ARN itself. `s3:GetObject` operates on objects, not the bucket.
- **SID**: Use `"PublicReadGetObject"` per AWS official documentation examples.

### Conditional Creation Logic

The bucket policy must only be created when **both** conditions are met:
1. `var.enable_website == true` -- website hosting is enabled
2. `var.block_public_access == false` -- public access block is disabled

This maps to spec requirements FR-013a and FR-013b. The `count` meta-argument provides the cleanest conditional:

```hcl
count = (var.enable_website && !var.block_public_access) ? 1 : 0
```

The `depends_on` on the public access block resource is critical: if Terraform attempts to apply the bucket policy before the public access block is configured with `block_public_policy = false`, the AWS API will reject the request with an `AccessDenied` error. The implicit dependency through `bucket = aws_s3_bucket.this.id` does not capture this ordering requirement since the public access block is a separate resource.

### Rationale
AWS documentation explicitly states that to make a static website bucket publicly readable, you must (1) disable Block Public Access settings and (2) add a bucket policy granting `s3:GetObject` to everyone. The `aws_iam_policy_document` data source is the idiomatic Terraform approach over inline JSON strings, providing type safety and interpolation support. The conditional creation pattern using `count` is the standard approach seen across well-regarded public modules.

### Alternatives Considered
| Alternative | Why Not |
|-------------|---------|
| Inline JSON policy string | Less maintainable, no interpolation safety, harder to read; `aws_iam_policy_document` is the Terraform-idiomatic approach |
| `jsonencode()` with HCL map | Viable but loses the declarative structure and validation that `aws_iam_policy_document` provides |
| Bucket ACLs (`public-read`) | Deprecated approach; AWS recommends bucket policies over ACLs; Object Ownership `BucketOwnerEnforced` disables ACLs by default |
| Always create policy with empty statement | Unnecessary complexity; `count` cleanly gates the entire resource |
| CloudFront OAC instead of public bucket | Valid architecture but out of scope per spec; the module supports this via `enable_website = true` with `block_public_access = true` (no bucket policy created) |

### Sources
- AWS docs: https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteAccessPermissionsReqd.html
- AWS docs: https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html
- Provider docs: hashicorp/aws `aws_s3_bucket_policy` (providerDocID 11440697)
- Provider docs: hashicorp/aws `aws_s3_bucket_public_access_block` (providerDocID 11440698)
- Provider docs: hashicorp/aws `data.aws_iam_policy_document` (providerDocID 11439113)
- Registry pattern: cn-terraform/s3-static-website/aws (module_id cn-terraform/s3-static-website/aws/1.0.13)
