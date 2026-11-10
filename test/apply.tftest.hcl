# Runs against a real AWS account and deletes the cache afterwards.
# Credentials and permissions are covered in test/README.md.
#   terraform test -filter=apply.tftest.hcl
#
# Replace the subnet and security group ids in module.tf with ones from the
# target account first. Node types are kept small on purpose: ElastiCache bills
# per hour while the run is live.

run "create_non_clustered" {
  command = apply

  assert {
    condition     = output.redis.id == "dev-photos"
    error_message = "Unexpected replication group id: ${output.redis.id}."
  }

  assert {
    condition     = output.redis.hostname != null
    error_message = "A non-clustered replication group should expose a primary endpoint."
  }

  assert {
    condition     = output.redis.port == 6379
    error_message = "Expected port 6379."
  }

  assert {
    condition     = output.redis.configuration_endpoint == null
    error_message = "There should be no configuration endpoint outside cluster mode."
  }

  assert {
    condition     = output.valkey.id == "dev-sessions"
    error_message = "Valkey deployment did not create the expected group."
  }
}
