# twingate-connector

One [Twingate](https://www.twingate.com) connector as an ECS Fargate service.

A single task that dials out to Twingate — no inbound ports, no load balancer,
no public IP. Connector tokens are issued through the Twingate provider, written
to Secrets Manager, and injected at runtime, so they never appear in the task
definition or in plan output.

Use this module directly when you already own a VPC and an ECS cluster and want
to add connectors to them. To stand up the shared infrastructure as well, use
the [parent module](../../README.md) instead, which wraps this one.

## Usage

```hcl
module "connector" {
  source  = "aarontravass/twingate/aws//modules/connector"
  version = "0.2.0"

  twingate_network             = "acme" # acme.twingate.com
  twingate_remote_network_name = "acme-aws-us-east-2"

  ecs_cluster_arn    = aws_ecs_cluster.shared.arn
  vpc_id             = "vpc-0123456789abcdef0"
  private_subnet_ids = ["subnet-0a1b2c3d"]

  tags = { owner = "platform" }
}
```

Run two or more per remote network so a connector can be replaced without
dropping the tunnel.

## Identifying the remote network

`twingate_network` is your account subdomain — `acme` for `acme.twingate.com`.
It is what the container's `TWINGATE_NETWORK` expects, and it is **not** the
remote network name.

The remote network itself is given one of two ways, and exactly one must be set:

- `twingate_remote_network_id` — preferred when the network is created in the
  same apply, because it gives Terraform a real dependency edge.
- `twingate_remote_network_name` — for a network that already exists.

Setting both, or neither, is a variable validation error.

## Prerequisites

**Outbound internet from the subnets.** Connectors are outbound-only and must
reach Twingate's relays. Tasks run with `assign_public_ip = false`, so the
subnets need a NAT gateway or equivalent. A subnet with no route out produces a
service that never reaches steady state, and because the service sets
`wait_for_steady_state`, the apply hangs for the full 10-minute create timeout
before failing.

**FARGATE on the cluster.** This module does not touch the cluster's capacity
providers — `ecs_cluster_arn` must point at a cluster that already has `FARGATE`
associated, or ECS rejects the service.

**Twingate credentials.** The provider needs `api_token` and `network`,
configured by the caller or via `TWINGATE_API_TOKEN` / `TWINGATE_NETWORK`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.10 |
| aws | >= 6.0 |
| twingate | 3.6.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| this | terraform-aws-modules/security-group/aws | ~> 6.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_policy.read_secrets_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.ecs_task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ecs_task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ecs_task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ecs_task_execution_role_read_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ecs_task_role_read_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_secretsmanager_secret.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [twingate_connector.this](https://registry.terraform.io/providers/Twingate/twingate/3.6.0/docs/resources/connector) | resource |
| [twingate_connector_tokens.this](https://registry.terraform.io/providers/Twingate/twingate/3.6.0/docs/resources/connector_tokens) | resource |
| [aws_iam_policy_document.ecs_assume_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.read_secrets_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [twingate_remote_network.this](https://registry.terraform.io/providers/Twingate/twingate/3.6.0/docs/data-sources/remote_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| ecs\_cluster\_arn | ARN of the ECS cluster the connector service runs in. Must already have the FARGATE capacity provider associated. | `string` | n/a | yes |
| private\_subnet\_ids | Subnets the connector task runs in. Must have egress to the internet, since connectors are outbound-only. | `list(string)` | n/a | yes |
| tags | Tags applied to every resource this module creates. | `map(string)` | n/a | yes |
| twingate\_network | Twingate account subdomain, without .twingate.com (e.g. "acme") | `string` | n/a | yes |
| vpc\_id | VPC the connector's security group is created in. | `string` | n/a | yes |
| log\_group\_name | Name of an existing CloudWatch log group to write connector task logs to. Leave empty to have the module create one per connector. | `string` | `""` | no |
| log\_retention\_in\_days | Retention for the log group created when log\_group\_name is empty. Ignored otherwise. | `number` | `30` | no |
| twingate\_image | Connector container image. | `string` | `"twingate/connector:1.83"` | no |
| twingate\_remote\_network\_id | Id of the Twingate remote network to attach the connector to. Set exactly one of this or twingate\_remote\_network\_name. | `string` | `""` | no |
| twingate\_remote\_network\_name | Name of an existing Twingate remote network to attach the connector to. Set exactly one of this or twingate\_remote\_network\_id. | `string` | `""` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| connector\_name | Twingate-generated connector name. Every AWS resource this module creates is named from it. |
| ecs\_service\_name | ECS service name. |
| log\_group\_name | Log group the task writes to, whether created here or supplied. |
| security\_group\_id | Id of the egress-only security group created for the task. |
| task\_definition\_arn | ARN of the current task definition revision. |
<!-- END_TF_DOCS -->

## What it creates

A Twingate connector and its token pair; a Secrets Manager secret at
`/twingate/<connector>/keys` holding both tokens; an execution role and a task
role, each attached to a policy granting `secretsmanager:GetSecretValue` on that
one secret; a security group with egress only; a Fargate task definition; and an
ECS service with `desired_count = 1`.

Every resource name keys off the Twingate-generated connector name, so several
connectors coexist in one account and region without collision.

## License

MIT. See [LICENSE](../../LICENSE).
