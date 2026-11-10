# Guardrails: invalid combinations must be rejected at plan time. Without
# these, a refactor could drop the validation and the plan tests would still
# pass.
#
# The tested config is the module itself, so expect_failures can name its
# resources.

mock_provider "aws" {}

run "accepts_valid_non_clustered" {
  command = plan

  module {
    source = "../"
  }

  variables {
    app                  = "ok"
    environment          = "dev"
    managed_by           = "platform"
    node_type            = "cache.t4g.micro"
    engine_version       = "6.x"
    parameter_group_name = "default.redis6.x"
    subnet_ids           = ["subnet-0123456789abcdef0"]
    security_group_ids   = ["sg-0123456789abcdef0"]
  }
}

run "rejects_unsupported_node_type" {
  command = plan

  module {
    source = "../"
  }

  variables {
    app                  = "bad-node"
    environment          = "dev"
    managed_by           = "platform"
    node_type            = "cache.r3.large"
    engine_version       = "6.x"
    parameter_group_name = "default.redis6.x"
    subnet_ids           = ["subnet-0123456789abcdef0"]
    security_group_ids   = ["sg-0123456789abcdef0"]
  }

  expect_failures = [var.node_type]
}

run "rejects_unknown_engine" {
  command = plan

  module {
    source = "../"
  }

  variables {
    app                  = "bad-engine"
    environment          = "dev"
    managed_by           = "platform"
    node_type            = "cache.t4g.micro"
    engine               = "memcached"
    engine_version       = "1.6"
    parameter_group_name = "default.memcached1.6"
    subnet_ids           = ["subnet-0123456789abcdef0"]
    security_group_ids   = ["sg-0123456789abcdef0"]
  }

  expect_failures = [var.engine]
}

run "rejects_cluster_mode_without_settings" {
  command = plan

  module {
    source = "../"
  }

  variables {
    app                  = "bad-cluster"
    environment          = "dev"
    managed_by           = "platform"
    node_type            = "cache.t4g.micro"
    engine_version       = "6.x"
    parameter_group_name = "default.redis6.x.cluster.on"
    cluster_mode_enabled = true
    subnet_ids           = ["subnet-0123456789abcdef0"]
    security_group_ids   = ["sg-0123456789abcdef0"]
  }

  expect_failures = [aws_elasticache_replication_group.redis]
}

run "rejects_failover_with_single_node" {
  command = plan

  module {
    source = "../"
  }

  variables {
    app                  = "bad-failover"
    environment          = "dev"
    managed_by           = "platform"
    node_type            = "cache.t4g.micro"
    engine_version       = "6.x"
    parameter_group_name = "default.redis6.x"
    cluster_size         = "1"
    subnet_ids           = ["subnet-0123456789abcdef0"]
    security_group_ids   = ["sg-0123456789abcdef0"]
  }

  expect_failures = [aws_elasticache_replication_group.redis]
}

run "rejects_auth_token_without_transit_encryption" {
  command = plan

  module {
    source = "../"
  }

  variables {
    app                  = "bad-auth"
    environment          = "dev"
    managed_by           = "platform"
    node_type            = "cache.t4g.micro"
    engine_version       = "6.x"
    parameter_group_name = "default.redis6.x"
    auth_token           = "some-password"
    subnet_ids           = ["subnet-0123456789abcdef0"]
    security_group_ids   = ["sg-0123456789abcdef0"]
  }

  expect_failures = [var.auth_token]
}
