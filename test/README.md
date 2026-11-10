# Tests

Terraform test configuration for this module. Terraform 1.7 or newer is
required, because the plan tests use `mock_provider`.

`module.tf` calls the module six ways: Redis and Valkey in primary/replica
mode, cluster mode with two shards, encryption in transit with an auth token,
an app name needing normalisation, and an app name long enough to be truncated.
`outputs.tf` exposes their results.

The subnet and security group ids there are placeholders. The plan and guardrail
tests mock the provider, so they are never resolved.

## Plan tests

`plan.tftest.hcl` mocks the AWS provider. No credentials, nothing created.

```bash
cd test
terraform init
terraform test -filter=plan.tftest.hcl
```

## Guardrail tests

`validation.tftest.hcl` checks that invalid input is rejected at plan time: an
unsupported node type, an unknown engine, cluster mode without its settings,
failover on a single node, and an auth token without transit encryption.

```bash
terraform test -filter=validation.tftest.hcl
```

## Apply tests

`apply.tftest.hcl` creates real replication groups and deletes them afterwards.
Before running it, replace the subnet and security group ids in `module.tf`
with ones from the target account.

```bash
terraform test -filter=apply.tftest.hcl
```

ElastiCache is billed hourly while the run is live, so this uses
`cache.t4g.micro` and tears down at the end. Do not point it at an account
where the cache must stay up.

### Credentials

Credentials come from the standard provider chain. An IAM role is better than
static keys:

- Assume-role profile in `~/.aws/config`, then `export AWS_PROFILE=elasticache-test`:

  ```ini
  [profile elasticache-test]
  role_arn       = arn:aws:iam::123456789012:role/terraform-elasticache-test
  source_profile = default
  region         = us-east-1
  ```

- `assume_role` block in the provider in `module.tf`.
- Instance or task role attached on EC2, ECS or EKS, with nothing exported.
- Temporary credentials exported from an existing session. Include
  `AWS_SESSION_TOKEN` when they came from `sts:AssumeRole`; without it the
  provider returns `InvalidClientTokenId`.

The region is fixed at `us-east-1` in `module.tf`.

### Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticache:CreateReplicationGroup",
        "elasticache:DescribeReplicationGroups",
        "elasticache:ModifyReplicationGroup",
        "elasticache:DeleteReplicationGroup",
        "elasticache:CreateCacheSubnetGroup",
        "elasticache:DescribeCacheSubnetGroups",
        "elasticache:DeleteCacheSubnetGroup",
        "elasticache:ListTagsForResource",
        "elasticache:AddTagsToResource"
      ],
      "Resource": "*"
    }
  ]
}
```

In a shared account, scope `Resource` to the relevant cache and subnet group
ARNs. The tests create groups named `dev-photos`, `dev-sessions`, `prod-feed`,
`stage-photos-api`, and a truncated `prod-extremely-long-application-name...`.

## CI

`.github/workflows/terraform-test.yml` runs fmt, validate, the plan tests and
the guardrail tests on every push and pull request. The apply tests only run on
manual dispatch, with `run_apply_tests` ticked. That job uses OIDC when the
`AWS_ROLE_ARN` repository variable is set and falls back to the access key
secrets otherwise.
