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

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.10 |
| hashicorp/aws | >= 6.0 |
| Twingate/twingate | 3.6.0 |
| terraform-aws-modules/security-group/aws | ~> 6.0 |

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `twingate_network` | `string` | — | Account subdomain, without `.twingate.com`. |
| `twingate_remote_network_id` | `string` | `""` | Remote network to attach to, by id. |
| `twingate_remote_network_name` | `string` | `""` | Remote network to attach to, by name. |
| `ecs_cluster_arn` | `string` | — | Cluster to run in. Must have `FARGATE` associated. |
| `vpc_id` | `string` | — | VPC for the connector's security group. |
| `private_subnet_ids` | `list(string)` | — | Subnets for the task. Must have egress to the internet. |
| `log_group_name` | `string` | `""` | Existing log group. Empty creates one per connector. |
| `log_retention_in_days` | `number` | `30` | Retention for a created log group. Ignored otherwise. |
| `twingate_image` | `string` | `"twingate/connector:1.83"` | Connector image. |
| `tags` | `map(string)` | — | Tags applied to every resource. |

## Outputs

| Name | Description |
|---|---|
| `connector_name` | Twingate-generated connector name. |
| `ecs_service_name` | ECS service name. |
| `security_group_id` | Security group created for the task. |
| `log_group_name` | Log group in use, created or supplied. |
| `task_definition_arn` | ARN of the current task definition revision. |

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
