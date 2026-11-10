output "id" {
  description = "Replication group id."
  value       = aws_elasticache_replication_group.redis.replication_group_id
}

output "arn" {
  description = "ARN of the replication group."
  value       = aws_elasticache_replication_group.redis.arn
}

output "hostname" {
  description = "Primary endpoint. Clustered deployments have no primary endpoint, so this is null in cluster mode."
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "reader_endpoint" {
  description = "Reader endpoint for spreading reads across replicas. Non-clustered mode only."
  value       = aws_elasticache_replication_group.redis.reader_endpoint_address
}

output "configuration_endpoint" {
  description = "Configuration endpoint. Cluster mode only, null otherwise."
  value       = aws_elasticache_replication_group.redis.configuration_endpoint_address
}

output "port" {
  description = "Port the cache listens on."
  value       = aws_elasticache_replication_group.redis.port
}

output "subnet_group_name" {
  description = "Name of the ElastiCache subnet group."
  value       = aws_elasticache_subnet_group.cache.name
}

output "maintenance_window" {
  description = "Maintenance window in effect."
  value       = aws_elasticache_replication_group.redis.maintenance_window
}
