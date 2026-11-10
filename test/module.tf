# Module calls used by the tests. The plan and guardrail tests substitute a
# mock provider, so the subnet and security group ids here are placeholders.
# The apply tests need real ones; see test/README.md.

provider "aws" {
  region = "us-east-1"
}

locals {
  subnet_ids         = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
  security_group_ids = ["sg-0123456789abcdef0"]
}

# Non-clustered Redis, the common case.
module "redis" {
  source = "../"

  app         = "photos"
  environment = "dev"
  managed_by  = "platform"

  node_type            = "cache.t4g.micro"
  engine               = "redis"
  engine_version       = "6.x"
  parameter_group_name = "default.redis6.x"

  subnet_ids         = local.subnet_ids
  security_group_ids = local.security_group_ids
}

# Same shape, different engine.
module "valkey" {
  source = "../"

  app         = "sessions"
  environment = "dev"
  managed_by  = "platform"

  node_type            = "cache.t4g.micro"
  engine               = "valkey"
  engine_version       = "7.2"
  parameter_group_name = "default.valkey7"

  subnet_ids         = local.subnet_ids
  security_group_ids = local.security_group_ids
}

# Cluster mode, two shards with two replicas each.
module "redis_cluster" {
  source = "../"

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

  subnet_ids         = local.subnet_ids
  security_group_ids = local.security_group_ids
}

# Encryption in transit plus an auth token.
module "encrypted" {
  source = "../"

  app         = "billing"
  environment = "prod"
  managed_by  = "platform"

  node_type            = "cache.t4g.small"
  engine               = "redis"
  engine_version       = "7.1"
  parameter_group_name = "default.redis7"

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = "correct-horse-battery-staple"
  auth_token_update_strategy = "SET"

  subnet_ids         = local.subnet_ids
  security_group_ids = local.security_group_ids
}

# App name needing normalisation, and a long one to exercise truncation.
module "normalised" {
  source = "../"

  app         = "Photos API"
  environment = "Stage"
  managed_by  = "platform"

  node_type            = "cache.t4g.micro"
  engine               = "redis"
  engine_version       = "6.x"
  parameter_group_name = "default.redis6.x"

  subnet_ids         = local.subnet_ids
  security_group_ids = local.security_group_ids
}

module "long_name" {
  source = "../"

  app         = "extremely-long-application-name-that-will-not-fit-in-forty-characters"
  environment = "prod"
  managed_by  = "platform"

  node_type            = "cache.t4g.micro"
  engine               = "redis"
  engine_version       = "6.x"
  parameter_group_name = "default.redis6.x"

  subnet_ids         = local.subnet_ids
  security_group_ids = local.security_group_ids
}
