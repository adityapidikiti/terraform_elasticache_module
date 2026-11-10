# Provider is mocked, so this needs no AWS credentials and creates nothing.
#   terraform test -filter=plan.tftest.hcl

mock_provider "aws" {}

run "redis_non_clustered" {
  command = plan

  assert {
    condition     = output.redis.id == "dev-photos"
    error_message = "Replication group id should be the lowercased environment and app."
  }

  assert {
    condition     = output.redis.port == 6379
    error_message = "Default port should be 6379."
  }

  assert {
    condition     = output.redis.subnet_group_name == "dev-photos-cache-subnet"
    error_message = "Subnet group name should follow the replication group id."
  }
}

run "valkey_engine" {
  command = plan

  assert {
    condition     = output.valkey.id == "dev-sessions"
    error_message = "Valkey deployments should name the group the same way as Redis."
  }
}

run "cluster_mode" {
  command = plan

  assert {
    condition     = output.redis_cluster.id == "prod-feed"
    error_message = "Unexpected replication group id."
  }
}

run "name_normalisation" {
  command = plan

  # app = "Photos API", environment = "Stage"
  assert {
    condition     = output.normalised.id == "stage-photos-api"
    error_message = "Spaces and capitals should collapse to a single hyphen in lower case."
  }
}

run "long_name_is_truncated" {
  command = plan

  assert {
    condition     = length(output.long_name.id) <= 40
    error_message = "Replication group ids are capped at 40 characters."
  }

  assert {
    condition     = !endswith(output.long_name.id, "-")
    error_message = "A truncated id must not end with a hyphen."
  }
}
