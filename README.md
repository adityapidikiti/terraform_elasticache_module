# terraform_elasticache_module

Terraform module for an ElastiCache replication group, Redis or Valkey, in
either primary/replica or cluster mode.

## Primary/replica (default)

One primary with automatic failover, plus an optional reader endpoint for
spreading reads. This is what most workloads want.

```hcl
module "redis" {
  source = "git@github.com:adityapidikiti/terraform_elasticache_module.git"

  app         = "sessions"
  environment = "dev"
  managed_by  = "platform"

  node_type            = "cache.t4g.micro"
  engine               = "redis"
  engine_version       = "6.x"
  parameter_group_name = "default.redis6.x"

  subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids = [aws_security_group.cache.id]
}
```

The replication group id is derived as `<environment>-<app>`, lowercased, with
runs of non-alphanumeric characters collapsed to a single hyphen. So
`environment = "Stage"` and `app = "Photos API"` give `stage-photos-api`. Ids
are capped at 40 characters and never end with a hyphen.

## Cluster mode

Shards data across multiple primaries. Requires a client that supports cluster
mode, and the parameter group must be the `.cluster.on` variant.

```hcl
module "redis_cluster" {
  source = "git@github.com:adityapidikiti/terraform_elasticache_module.git"

  app         = "feed"
  environment = "prod"
  managed_by  = "platform"

  node_type            = "cache.m6g.large"
  engine               = "redis"
  engine_version       = "6.x"
  parameter_group_name = "default.redis6.x.cluster.on"

  cluster_mode_enabled = true
  cluster_mode_settings = {
    num_node_groups         = 2
    replicas_per_node_group = 2
  }

  subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids = [aws_security_group.cache.id]
}
```

`cluster_size` is ignored in cluster mode. In primary/replica mode the
`cluster_mode_settings` value is ignored instead.

## Valkey

Set `engine = "valkey"` and use a Valkey parameter group:

```hcl
  engine               = "valkey"
  engine_version       = "7.2"
  parameter_group_name = "default.valkey7"
```

## Encryption

```hcl
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.redis_password
  auth_token_update_strategy = "SET"
```

`auth_token` is marked sensitive and requires `transit_encryption_enabled`. It
is rejected at plan time otherwise.

Encryption cannot be turned on for an existing replication group: both settings
force replacement. Enabling them on a live cache means downtime, so plan the
migration rather than applying it blind.

## Snapshots

Automated backups are off by default (`snapshot_retention_limit = 0`). Set a
non-zero retention to enable them:

```hcl
  snapshot_retention_limit = 7
  snapshot_window          = "05:00-07:00"
```

## Outputs

`hostname` is the primary endpoint and is null in cluster mode, where there is
no single primary. `configuration_endpoint` is the reverse: populated only in
cluster mode. `reader_endpoint` is for read replicas in primary/replica mode.

## Testing

See [test/README.md](test/README.md).

```bash
cd test && terraform init
terraform test -filter=plan.tftest.hcl
terraform test -filter=validation.tftest.hcl
terraform test -filter=apply.tftest.hcl   # needs AWS credentials
```

## Approved node types

`node_type` is validated against this list. Anything else fails at plan time.

| Node type | vCPU | Memory (GiB) | Baseline Gbps | Burst Gbps |
|-----------|------|--------------|---------------|------------|
| cache.t4g.micro | 2 | 0.50 | 0.064 | 5.0 |
| cache.t4g.small | 2 | 1.37 | 0.128 | 5.0 |
| cache.t4g.medium | 2 | 3.09 | 0.256 | 5.0 |
| cache.m6g.large | 2 | 6.38 | 0.75 | 10.0 |
| cache.m6g.xlarge | 4 | 12.93 | 1.25 | 10.0 |
| cache.m6g.2xlarge | 8 | 26.04 | 2.5 | 10.0 |
| cache.m6g.4xlarge | 16 | 52.26 | 5.0 | 10.0 |
| cache.m6g.8xlarge | 32 | 103.68 | 12 | n/a |
| cache.m6g.16xlarge | 64 | 209.55 | 25 | n/a |
| cache.m5.4xlarge | 16 | 52.26 | 5.0 | 10.0 |
| cache.m7g.large | 2 | 8 | 0.937 | 12.5 |
| cache.r6g.2xlarge | 8 | 52.82 | 2.5 | 10.0 |
| cache.r6g.4xlarge | 16 | 105.81 | 5.0 | 10.0 |
| cache.r7g.large | 2 | 16.38 | 0.937 | 12.5 |
| cache.r7g.4xlarge | 16 | 128 | 7.5 | 15 |
| cache.c7gn.large | 2 | 3.09 | 6.25 | 30 |
| cache.c7gn.xlarge | 4 | 6.38 | 12.5 | 40 |
| cache.c7gn.2xlarge | 8 | 12.94 | 25 | 50 |
| cache.c7gn.4xlarge | 16 | 26.05 | 50 | n/a |

## Requirements

| Name | Version |
|------|---------|
| [terraform](https://developer.hashicorp.com/terraform) | >= 1.0 |

## Providers

| Name | Version |
|------|---------|
| [aws](https://registry.terraform.io/providers/hashicorp/aws/latest) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_elasticache_replication_group.redis](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_replication_group) | resource |
| [aws_elasticache_subnet_group.cache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_subnet_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| app | Application this cache supports, used for the App tag and the replication group id. | `string` | n/a | yes |
| engine_version | Engine version, for example 6.x or 7.2. | `string` | n/a | yes |
| environment | Deployment environment, used for the Environment tag and the replication group id. | `string` | n/a | yes |
| managed_by | Team responsible for the cache, used for the ManagedBy tag. | `string` | n/a | yes |
| node_type | ElastiCache node type. | `string` | n/a | yes |
| parameter_group_name | Parameter group to attach. Use the .cluster.on variant for cluster mode. | `string` | n/a | yes |
| security_group_ids | Security groups applied to the cache. | `list(string)` | n/a | yes |
| subnet_ids | Subnets the cache lives in. | `list(string)` | n/a | yes |
| apply_immediately | Apply changes immediately instead of during the maintenance window. | `string` | `"false"` | no |
| at_rest_encryption_enabled | Encrypt data at rest. | `bool` | `false` | no |
| auth_token | Password for the cache. Requires transit encryption. | `string` | `null` | no |
| auth_token_update_strategy | How to apply auth_token changes: SET, ROTATE or DELETE. | `string` | `null` | no |
| automatic_failover_enabled | Promote a replica automatically when the primary fails. | `bool` | `true` | no |
| cluster_mode_enabled | Enable cluster mode with multiple primaries. | `bool` | `false` | no |
| cluster_mode_settings | Cluster mode only. Expects num_node_groups and replicas_per_node_group. | `map(string)` | `{}` | no |
| cluster_size | Primary/replica mode only. Total nodes in the group. | `string` | `"2"` | no |
| custom_tags | Additional tags merged over the standard set. | `map(string)` | `{}` | no |
| engine | Cache engine, redis or valkey. | `string` | `"redis"` | no |
| maintenance_window | Preferred maintenance window. | `string` | `"sun:07:01-sun:11:00"` | no |
| multi_az_enabled | Spread nodes across availability zones. | `bool` | `true` | no |
| port | Port the cache listens on. | `number` | `6379` | no |
| snapshot_retention_limit | Days to keep automatic snapshots. Zero disables backups. | `number` | `0` | no |
| snapshot_window | Daily snapshot window in UTC. | `string` | `"05:00-07:00"` | no |
| transit_encryption_enabled | Encrypt data in transit. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| arn | ARN of the replication group. |
| configuration_endpoint | Configuration endpoint. Cluster mode only. |
| hostname | Primary endpoint. Null in cluster mode. |
| id | Replication group id. |
| maintenance_window | Maintenance window in effect. |
| port | Port the cache listens on. |
| reader_endpoint | Reader endpoint. Primary/replica mode only. |
| subnet_group_name | Name of the ElastiCache subnet group. |
