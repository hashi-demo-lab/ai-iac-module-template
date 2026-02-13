## Research: What are the Terraform configurations for aws_s3_bucket_public_access_block and aws_s3_bucket_cors_configuration, including public access block interactions with bucket policies and CORS rule attributes for static website hosting?

### Decision
Use `aws_s3_bucket_public_access_block` with all four settings defaulting to `true` (secure-by-default), and provide an optional `aws_s3_bucket_cors_configuration` with configurable CORS rules -- the module should support both direct public hosting (requiring relaxed public access block) and CloudFront OAC patterns (keeping all four blocks enabled).

### Resources Identified
- **Primary Resource**: `aws_s3_bucket_public_access_block` -- controls all four public access block settings at the bucket level
- **Supporting Resources**:
  - `aws_s3_bucket_cors_configuration` -- defines CORS rules for cross-origin browser requests
  - `aws_s3_bucket_policy` -- grants public read (`s3:GetObject`) or CloudFront OAC access
- **Key Arguments (public_access_block)**:
  - `bucket` (required) -- S3 bucket ID
  - `block_public_acls` (optional, default `false` in provider, should default `true` in module) -- rejects PUT calls with public ACLs
  - `block_public_policy` (optional, default `false` in provider, should default `true` in module) -- rejects PutBucketPolicy if policy allows public access
  - `ignore_public_acls` (optional, default `false` in provider, should default `true` in module) -- ignores existing public ACLs on bucket/objects
  - `restrict_public_buckets` (optional, default `false` in provider, should default `true` in module) -- limits access to AWS service principals and authorized users only
- **Key Arguments (cors_configuration)**:
  - `bucket` (required, forces new resource) -- bucket name
  - `cors_rule` (required) -- one or more rule blocks, up to 100 rules:
    - `allowed_methods` (required) -- set of HTTP methods: GET, PUT, HEAD, POST, DELETE
    - `allowed_origins` (required) -- set of origin URLs, supports `*` wildcard
    - `allowed_headers` (optional) -- set of headers allowed in preflight requests, supports `*` wildcard
    - `expose_headers` (optional) -- set of response headers accessible to client applications
    - `max_age_seconds` (optional) -- browser preflight cache duration in seconds
    - `id` (optional) -- unique rule identifier, max 255 chars
- **Key Outputs**: `id` (`string`) for both resources (bucket name)
- **Security Considerations**: See detailed section below

### Four Public Access Block Settings and Bucket Policy Interaction

| Setting | Effect | Interaction with Bucket Policies |
|---------|--------|--------------------------------|
| `BlockPublicAcls` | Rejects PUT Bucket/Object ACL calls that specify public ACLs; rejects PutObject with public ACLs | Does not affect bucket policies. Only governs ACL-based public access. |
| `IgnorePublicAcls` | Causes S3 to ignore all public ACLs on bucket and objects | Does not affect bucket policies. Existing public ACLs are retained but not enforced. |
| `BlockPublicPolicy` | Rejects PutBucketPolicy if the policy grants public access | **Directly blocks** attaching public bucket policies. Must be set to `false` to attach a public-read bucket policy for direct website hosting. |
| `RestrictPublicBuckets` | Restricts access to AWS service principals and bucket-owner account users only, even if a public policy exists | **Overrides public bucket policies** at enforcement time. Even with a public policy attached, cross-account and anonymous access is blocked. Must be `false` for direct public website hosting. |

**Critical interaction for website hosting:**
- **Direct public hosting** (S3 website endpoint): Requires `block_public_policy = false` (to allow attaching the public-read policy) AND `restrict_public_buckets = false` (to allow anonymous access). AWS docs explicitly state you must clear "Block all public access" for static website hosting.
- **CloudFront OAC pattern** (recommended): All four settings can remain `true`. The bucket policy grants access to the CloudFront service principal (`cloudfront.amazonaws.com`), which S3 does not consider "public" because it is scoped to a specific service principal with a condition key.
- **Hierarchy enforcement**: S3 applies the most restrictive combination of organization, account, and bucket-level settings. Even if bucket-level allows public access, account-level blocks will override it.

### CORS Rules for Static Website Hosting

For a typical static website, CORS is needed when:
1. The site loads fonts, scripts, or API responses from the S3 origin via a different domain
2. JavaScript makes XMLHttpRequest/fetch calls to the bucket from another origin

**Recommended default CORS configuration for static websites:**
```hcl
cors_rule {
  allowed_headers = ["*"]
  allowed_methods = ["GET", "HEAD"]
  allowed_origins = ["*"]  # or restrict to specific domain
  expose_headers  = ["ETag"]
  max_age_seconds = 3600
}
```

- `allowed_methods`: GET and HEAD are sufficient for static content serving; PUT/POST/DELETE should only be added if uploads are needed
- `allowed_origins`: Use `*` for public websites or restrict to specific domains for security
- `allowed_headers`: `*` is common for simplicity; can be restricted to specific headers
- `expose_headers`: ETag is useful for cache validation; Content-Length and Content-Type are commonly exposed
- `max_age_seconds`: 3600 (1 hour) is a reasonable default to reduce preflight requests
- Up to 100 CORS rules per bucket; S3 uses the first matching rule

### Rationale
AWS documentation explicitly states that for direct S3 website hosting, all Block Public Access settings must be cleared and a public-read bucket policy must be attached. However, AWS best practice recommends using CloudFront with OAC instead, which allows keeping all four public access block settings enabled. The module should default to the secure CloudFront OAC pattern (all blocks `true`) and only relax settings when explicitly opted in for direct public hosting. CORS configuration is orthogonal to public access block settings -- CORS headers are evaluated after access is granted. Provider docs confirm `aws_s3_bucket_cors_configuration` is the current standalone resource (replacing the deprecated inline `cors_rule` on `aws_s3_bucket`). Only one CORS configuration resource should be declared per bucket to avoid perpetual diffs.

### Alternatives Considered
| Alternative | Why Not |
|-------------|---------|
| Inline `cors_rule` on `aws_s3_bucket` | Deprecated in favor of standalone `aws_s3_bucket_cors_configuration` resource |
| All public access block settings `false` by default | Violates security-first principle; module should default to most restrictive and require explicit opt-in for public access |
| Omitting CORS entirely | Static websites often need CORS for font loading, API calls, or cross-origin asset requests; should be optional but available |
| Using ACLs for public access | S3 Object Ownership with "BucketOwnerEnforced" disables ACLs; bucket policies are the recommended approach |

### Sources
- AWS docs: https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html
- AWS docs: https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteAccessPermissionsReqd.html
- AWS docs: https://docs.aws.amazon.com/AmazonS3/latest/userguide/ManageCorsUsing.html
- AWS docs: https://docs.aws.amazon.com/AmazonS3/latest/userguide/cors.html
- Provider docs: hashicorp/aws `aws_s3_bucket_public_access_block` (v6.32.0)
- Provider docs: hashicorp/aws `aws_s3_bucket_cors_configuration` (v6.32.0)
