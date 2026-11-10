variable "cluster_mode_enabled" {
  type        = bool
  description = "Enable cluster mode, giving multiple shards each with their own primary. Requires client support for cluster mode."
  default     = false
}

variable "cluster_mode_settings" {
  type        = map(string)
  description = "Cluster mode only. Expects num_node_groups and replicas_per_node_group."
  default     = {}
}

variable "cluster_size" {
  type        = string
  description = "Non-clustered mode only. Total nodes in the replication group: one primary, the rest replicas."
  default     = "2"
}

variable "node_type" {
  type        = string
  description = "ElastiCache node type, for example cache.t4g.micro."

  validation {
    condition = contains([
      "cache.t4g.micro",
      "cache.t4g.small",
      "cache.t4g.medium",
      "cache.m6g.large",
      "cache.m6g.xlarge",
      "cache.m6g.2xlarge",
      "cache.m6g.4xlarge",
      "cache.m6g.8xlarge",
      "cache.m6g.16xlarge",
      "cache.m5.4xlarge",
      "cache.m7g.large",
      "cache.r6g.2xlarge",
      "cache.r6g.4xlarge",
      "cache.r7g.large",
      "cache.r7g.4xlarge",
      "cache.c7gn.large",
      "cache.c7gn.xlarge",
      "cache.c7gn.2xlarge",
      "cache.c7gn.4xlarge",
    ], var.node_type)
    error_message = "Unsupported node_type. See the approved node types table in README.md."
  }
}

variable "engine" {
  type        = string
  description = "Cache engine, redis or valkey."
  default     = "redis"

  validation {
    condition     = contains(["redis", "valkey"], var.engine)
    error_message = "engine must be either redis or valkey."
  }
}

variable "engine_version" {
  type        = string
  description = "Engine version, for example 6.x or 7.2."
}

variable "parameter_group_name" {
  type        = string
  description = "Parameter group to attach, for example default.redis6.x or default.valkey7. Use the .cluster.on variant for cluster mode."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets the cache lives in."
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security groups applied to the cache."
}

variable "port" {
  type        = number
  description = "Port the cache listens on."
  default     = 6379
}

variable "apply_immediately" {
  type        = string
  description = "Apply changes immediately instead of during the maintenance window."
  default     = "false"
}

variable "maintenance_window" {
  type        = string
  description = "Preferred maintenance window, for example sun:07:01-sun:11:00."
  default     = "sun:07:01-sun:11:00"
}

variable "snapshot_window" {
  type        = string
  description = "Daily snapshot window in UTC. Minimum 60 minutes."
  default     = "05:00-07:00"
}

variable "snapshot_retention_limit" {
  type        = number
  description = "Days to keep automatic snapshots. Zero disables backups."
  default     = 0
}

variable "at_rest_encryption_enabled" {
  type        = bool
  description = "Encrypt data at rest."
  default     = false
}

variable "transit_encryption_enabled" {
  type        = bool
  description = "Encrypt data in transit."
  default     = false
}

variable "auth_token" {
  type        = string
  description = "Password for the cache. Only valid when transit_encryption_enabled is true."
  default     = null
  sensitive   = true

  validation {
    condition     = var.auth_token == null || var.transit_encryption_enabled
    error_message = "auth_token requires transit_encryption_enabled = true."
  }
}

variable "auth_token_update_strategy" {
  type        = string
  description = "How to apply auth_token changes: SET, ROTATE or DELETE."
  default     = null

  validation {
    condition     = var.auth_token_update_strategy == null || contains(["SET", "ROTATE", "DELETE"], var.auth_token_update_strategy)
    error_message = "auth_token_update_strategy must be SET, ROTATE or DELETE."
  }
}

variable "multi_az_enabled" {
  type        = bool
  description = "Spread nodes across availability zones."
  default     = true
}

variable "automatic_failover_enabled" {
  type        = bool
  description = "Promote a replica automatically when the primary fails."
  default     = true
}

variable "app" {
  type        = string
  description = "Application this cache supports, used for the App tag and the replication group id."
}

variable "environment" {
  type        = string
  description = "Deployment environment, used for the Environment tag and the replication group id."
}

variable "managed_by" {
  type        = string
  description = "Team responsible for the cache, used for the ManagedBy tag."
}

variable "custom_tags" {
  type        = map(string)
  description = "Additional tags merged over the standard set."
  default     = {}
}
