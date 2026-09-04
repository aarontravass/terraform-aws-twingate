# The remote network must be given exactly one way: by id or by name.

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
  twingate_network   = "acme"
  tags               = {}
  ecs_cluster_arn    = "arn:aws:ecs:us-east-2:111122223333:cluster/existing"
  vpc_id             = "vpc-0123456789abcdef0"
  private_subnet_ids = ["subnet-0a1b2c3d"]
}

run "rejects_neither_id_nor_name" {
  command         = plan
  expect_failures = [var.twingate_remote_network_name]
}

run "rejects_both_id_and_name" {
  command = plan

  variables {
    twingate_remote_network_id   = "rn-0123456789"
    twingate_remote_network_name = "acme-aws-us-east-2"
  }

  expect_failures = [var.twingate_remote_network_name]
}

run "accepts_id_only" {
  command = plan

  variables {
    twingate_remote_network_id = "rn-0123456789"
  }

  assert {
    condition     = twingate_connector.this.remote_network_id == "rn-0123456789"
    error_message = "the connector must attach to the id it was given"
  }
}

# The by-name path is not covered here. Mocking it requires the mocked data
# source to yield a non-null id, and the provider marks twingate_connector's
# remote_network_id as required, so a null fails config validation before any
# mock value is substituted. mock_data defaults, file-level override_data and
# override_during = plan were all tried. It needs an apply-mode test against a
# real Twingate tenant.
