mock_provider "aws" {
  # aws_iam_policy_document is computed by the provider; a bare mock returns a
  # string that is not valid JSON, which aws_iam_role then rejects.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}
mock_provider "twingate" {}

variables {
  twingate_network    = "acme"
  remote_network_name = "acme-aws-us-east-2"
  env                 = "test"
  tags                = { env = "test" }
  vpc_id              = "vpc-0123456789abcdef0"
  private_subnet_ids  = ["subnet-0a1b2c3d", "subnet-4e5f6a7b"]
}

run "defaults_to_two_connectors" {
  command = plan

  assert {
    condition     = length(module.connector) == 2
    error_message = "Twingate recommends at least two connectors per remote network"
  }
}

run "scales_with_connector_count" {
  command = plan

  variables {
    connector_count = 3
  }

  assert {
    condition     = length(module.connector) == 3
    error_message = "connector_count must drive the number of connectors"
  }
}

run "creates_remote_network_by_default" {
  command = plan

  assert {
    condition     = length(twingate_remote_network.this) == 1
    error_message = "the remote network must be created by default"
  }

  assert {
    condition     = twingate_remote_network.this[0].name == "acme-aws-us-east-2"
    error_message = "the remote network takes remote_network_name, not the account subdomain"
  }
}

# The id is unknown until apply on a green-field run. Passing it into a child
# module is fine; using it in count is not, and doing so failed the plan with
# "Invalid count argument". This asserts the plan builds at all.
run "unknown_remote_network_id_does_not_break_the_plan" {
  command = plan

  assert {
    condition     = length(twingate_remote_network.this) == 1
    error_message = "expected the create path, where the id is unknown at plan time"
  }
}

# create_twingate_remote_network = false is not covered here. That path sends
# the connector down the by-name lookup, and a mocked data source yields a null
# id, which the provider rejects as a missing required attribute before any mock
# value is substituted. See connector/tests/validation.tftest.hcl.
