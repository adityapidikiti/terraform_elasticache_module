output "redis" {
  value = {
    id                     = module.redis.id
    hostname               = module.redis.hostname
    port                   = module.redis.port
    subnet_group_name      = module.redis.subnet_group_name
    configuration_endpoint = module.redis.configuration_endpoint
  }
}

output "valkey" {
  value = {
    id = module.valkey.id
  }
}

output "redis_cluster" {
  value = {
    id                     = module.redis_cluster.id
    hostname               = module.redis_cluster.hostname
    configuration_endpoint = module.redis_cluster.configuration_endpoint
  }
}

output "encrypted" {
  value = {
    id = module.encrypted.id
  }
}

output "normalised" {
  value = {
    id   = module.normalised.id
    port = module.normalised.port
  }
}

output "long_name" {
  value = {
    id = module.long_name.id
  }
}
