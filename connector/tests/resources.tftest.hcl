# The connector is usable on its own, so it is tested on its own rather than
# only through the root stack.

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
  twingate_network           = "acme"
  twingate_remote_network_id = "rn-0123456789"
  tags                       = { owner = "platform" }
  ecs_cluster_arn            = "arn:aws:ecs:us-east-2:111122223333:cluster/existing"
  vpc_id                     = "vpc-0123456789abcdef0"
  private_subnet_ids         = ["subnet-0a1b2c3d"]
}

run "creates_own_log_group_when_none_supplied" {
  command = plan

  assert {
    condition     = length(aws_cloudwatch_log_group.this) == 1
    error_message = "a standalone connector must create its own log group"
  }

  assert {
    condition     = aws_cloudwatch_log_group.this[0].retention_in_days == 30
    error_message = "log_retention_in_days must apply to the created group"
  }
}

run "honours_log_retention_override" {
  command = plan

  variables {
    log_retention_in_days = 7
  }

  assert {
    condition     = aws_cloudwatch_log_group.this[0].retention_in_days == 7
    error_message = "log_retention_in_days must be configurable"
  }
}

run "uses_supplied_log_group" {
  command = plan

  variables {
    log_group_name = "ecs-twingate-prod"
  }

  assert {
    condition     = length(aws_cloudwatch_log_group.this) == 0
    error_message = "a supplied log group must not be duplicated"
  }
}

run "skips_network_lookup_when_id_supplied" {
  command = plan

  assert {
    condition     = length(data.twingate_remote_network.this) == 0
    error_message = "no lookup should happen when the id is given directly"
  }
}

run "service_runs_on_the_supplied_cluster" {
  command = plan

  assert {
    condition     = aws_ecs_service.this.cluster == "arn:aws:ecs:us-east-2:111122223333:cluster/existing"
    error_message = "the service must run on the cluster it was given"
  }

  assert {
    condition     = aws_ecs_service.this.network_configuration[0].subnets == toset(["subnet-0a1b2c3d"])
    error_message = "the task must run in the supplied subnets"
  }
}
