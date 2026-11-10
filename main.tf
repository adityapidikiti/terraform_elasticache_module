locals {
  # Replication group ids allow lower case alphanumerics and hyphens only, and
  # cap at 40 characters. Environment goes first so truncation keeps it.
  # Terraform treats a substring wrapped in slashes as a regular expression.
  raw_name = lower(format("%s-%s", var.environment, var.app))
  slug     = replace(local.raw_name, "/[^a-z0-9]+/", "-")
  name     = replace(substr(local.slug, 0, min(40, length(local.slug))), "/-+$/", "")

  cluster_mode_settings = var.cluster_mode_enabled ? var.cluster_mode_settings : {}

  tags = merge(
    {
      Name        = local.name
      App         = var.app
      ManagedBy   = var.managed_by
      Environment = var.environment
      Provisioner = "Terraform"
    },
    var.custom_tags
  )
}

resource "aws_elasticache_subnet_group" "cache" {
  name       = "${local.name}-cache-subnet"
  subnet_ids = var.subnet_ids

  tags = local.tags
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = local.name
  description          = "Redis for ${var.app} in ${var.environment}"

  engine         = var.engine
  engine_version = var.engine_version
  node_type      = var.node_type
  port           = var.port

  parameter_group_name = var.parameter_group_name

  subnet_group_name  = aws_elasticache_subnet_group.cache.name
  security_group_ids = var.security_group_ids

  apply_immediately = var.apply_immediately

  # Non-clustered uses num_cache_clusters; clustered uses node groups instead.
  num_cache_clusters      = var.cluster_mode_enabled ? null : var.cluster_size
  num_node_groups         = var.cluster_mode_enabled ? local.cluster_mode_settings["num_node_groups"] : null
  replicas_per_node_group = var.cluster_mode_enabled ? local.cluster_mode_settings["replicas_per_node_group"] : null

  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled

  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = var.transit_encryption_enabled
  auth_token                 = var.auth_token
  auth_token_update_strategy = var.auth_token_update_strategy

  maintenance_window       = var.maintenance_window
  snapshot_window          = var.snapshot_window
  snapshot_retention_limit = var.snapshot_retention_limit

  tags = local.tags

  lifecycle {
    # The id cannot be changed in place, and AWS raised the length limit after
    # this module shipped. Ignoring it avoids destroying a cache because a name
    # grew past the old limit.
    ignore_changes = [replication_group_id]

    precondition {
      condition     = !var.cluster_mode_enabled || (contains(keys(local.cluster_mode_settings), "num_node_groups") && contains(keys(local.cluster_mode_settings), "replicas_per_node_group"))
      error_message = "cluster_mode_enabled requires cluster_mode_settings with num_node_groups and replicas_per_node_group."
    }

    precondition {
      condition     = var.cluster_mode_enabled || tonumber(var.cluster_size) >= 1
      error_message = "cluster_size must be at least 1."
    }

    precondition {
      condition     = !var.automatic_failover_enabled || var.cluster_mode_enabled || tonumber(var.cluster_size) > 1
      error_message = "automatic_failover_enabled needs cluster mode or a cluster_size greater than 1."
    }

    precondition {
      condition     = !var.multi_az_enabled || var.automatic_failover_enabled
      error_message = "multi_az_enabled requires automatic_failover_enabled."
    }
  }
}
