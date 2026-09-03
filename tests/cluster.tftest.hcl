# Plan-only tests for the shared stack. Providers are mocked, so these need no
# AWS or Twingate credentials and are safe to run on every push.

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

run "creates_cluster_when_no_arn_supplied" {
  command = plan

  assert {
    condition     = length(aws_ecs_cluster.this) == 1
    error_message = "a cluster must be created when ecs_cluster_arn is empty"
  }

  assert {
    condition     = length(aws_ecs_cluster_capacity_providers.this) == 1
    error_message = "FARGATE must be associated with a cluster this module owns"
  }
}

# Supplying a cluster used to leave an empty twingate-cluster provisioned
# alongside it, because only the consumer side of the conditional was wired.
run "uses_supplied_cluster_and_creates_none" {
  command = plan

  variables {
    ecs_cluster_arn = "arn:aws:ecs:us-east-2:111122223333:cluster/existing"
  }

  assert {
    condition     = length(aws_ecs_cluster.this) == 0
    error_message = "supplying ecs_cluster_arn must not provision an orphan cluster"
  }

  assert {
    condition     = length(aws_ecs_cluster_capacity_providers.this) == 0
    error_message = "capacity providers on a caller-owned cluster are not ours to change"
  }
}

# Both names were fixed strings, so a second instantiation in one account and
# region collided on create.
run "env_disambiguates_global_names" {
  command = plan

  assert {
    condition     = aws_cloudwatch_log_group.this.name == "ecs-twingate-test"
    error_message = "log group name must carry env"
  }

  assert {
    condition     = aws_ecs_cluster.this[0].name == "twingate-cluster-test"
    error_message = "cluster name must carry env"
  }
}
