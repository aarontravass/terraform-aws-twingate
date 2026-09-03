# terraform-aws-twingate

Runs [Twingate](https://www.twingate.com) connectors on AWS ECS Fargate.

Each connector is a single Fargate task that dials out to Twingate — no inbound
ports, no load balancer, no public IP. Connector tokens are issued through the
Twingate provider, written to Secrets Manager, and injected into the task at
runtime, so they never appear in the task definition or in plan output.

## Layout

The repository ships two things that can be used separately:

| | What it is |
|---|---|
| **root** | A complete stack: log group, ECS cluster, a Twingate remote network, and `connector_count` connectors. |
| **`connector/`** | One connector. Takes an existing VPC, subnets and cluster and creates everything else per connector. |

Use the root module to stand the whole thing up in an account that has none of
it. Use `connector/` on its own when you already own a cluster and want to add
connectors to it, or when connectors are managed separately from the shared
infrastructure they run on.

## Usage

### Whole stack

```hcl
provider "twingate" {
  api_token = var.twingate_api_token
  network   = "acme" # acme.twingate.com
}

module "twingate" {
  source = "github.com/aarontravass/terraform-aws-twingate?ref=v0.1.0"

  twingate_network    = "acme"
  remote_network_name = "acme-aws-us-east-2"

  vpc_id             = "vpc-0123456789abcdef0"
  private_subnet_ids = ["subnet-0a1b2c3d", "subnet-4e5f6a7b"]

  connector_count = 2
  env             = "prod"
  tags            = { owner = "platform", env = "prod" }
}
```

### A connector on an existing cluster

```hcl
module "connector" {
  source = "github.com/aarontravass/terraform-aws-twingate//connector?ref=v0.1.0"

  twingate_network             = "acme"
  twingate_remote_network_name = "acme-aws-us-east-2"

  ecs_cluster_arn    = aws_ecs_cluster.shared.arn
  vpc_id             = "vpc-0123456789abcdef0"
  private_subnet_ids = ["subnet-0a1b2c3d"]

  tags = { owner = "platform" }
}
```

## `twingate_network` is not the remote network

These are two different values and the module keeps them apart:

- **`twingate_network`** — your account subdomain, `acme` for `acme.twingate.com`.
  This is what the connector container's `TWINGATE_NETWORK` expects, and what the
  Twingate provider's `network` argument takes.
- **`remote_network_name` / `twingate_remote_network_id`** — the remote network
  the connector attaches to. Named freely (`acme-aws-us-east-2`) and unrelated to
  the subdomain.

In `connector/`, set exactly one of `twingate_remote_network_id` or
`twingate_remote_network_name`; setting both or neither is a validation error.
Prefer the id when the network is created in the same apply — it gives Terraform
a dependency edge that a name lookup cannot.

## Prerequisites

**Outbound internet from the subnets.** Connectors are outbound-only and must
reach Twingate's relays. Tasks run with `assign_public_ip = false`, so the
subnets in `private_subnet_ids` need a NAT gateway or equivalent egress path. A
subnet with no route out produces a service that never reaches steady state, and
because the service sets `wait_for_steady_state`, the apply hangs for the full
10-minute create timeout before failing.

**FARGATE on a supplied cluster.** If you pass `ecs_cluster_arn`, this module
does not touch your cluster's capacity providers — the cluster must already have
`FARGATE` associated, or ECS rejects the service.

**Twingate credentials.** The provider needs `api_token` and `network`,
configured by the caller (or via `TWINGATE_API_TOKEN` / `TWINGATE_NETWORK`). The
API token needs permission to create connectors and read remote networks.

## Requirements

| | Version |
|---|---|
| terraform | >= 1.10 |
| hashicorp/aws | >= 6.0 |
| Twingate/twingate | 3.6.0 |

`connector/` also uses `terraform-aws-modules/security-group/aws ~> 6.0`.

## Root inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `twingate_network` | `string` | — | Account subdomain, without `.twingate.com`. |
| `remote_network_name` | `string` | — | Remote network to create or look up. |
| `remote_network_location` | `string` | `"AWS"` | Location reported for a created remote network. |
| `create_twingate_remote_network` | `bool` | `true` | Create the remote network, or attach to an existing one by name. |
| `connector_count` | `number` | `2` | Connectors to run. Twingate recommends at least two per remote network. |
| `vpc_id` | `string` | — | VPC the connectors run in. |
| `private_subnet_ids` | `list(string)` | — | Subnets for the tasks. Must have egress to the internet. |
| `ecs_cluster_arn` | `string` | `""` | Existing cluster to use. Empty creates one. |
| `twingate_image` | `string` | `"twingate/connector:1.83"` | Connector image. |
| `env` | `string` | — | Environment name; disambiguates the cluster and log group. |
| `tags` | `map(string)` | — | Tags applied to every resource. |

## Root outputs

| Name | Description |
|---|---|
| `connector_names` | Twingate-generated name of each connector. |
| `ecs_service_names` | ECS service name of each connector. |
| `remote_network_id` | Remote network id; empty when the stack did not create one. |

## `connector/` inputs

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

## `connector/` outputs

| Name | Description |
|---|---|
| `connector_name` | Twingate-generated connector name. |
| `ecs_service_name` | ECS service name. |
| `security_group_id` | Security group created for the task. |
| `log_group_name` | Log group in use, created or supplied. |
| `task_definition_arn` | ARN of the current task definition revision. |

## What a connector creates

A Twingate connector and its token pair; a Secrets Manager secret at
`/twingate/<connector>/keys` holding both tokens; an execution role and a task
role, each attached to a policy granting `secretsmanager:GetSecretValue` on that
one secret; a security group with egress only; a Fargate task definition; and an
ECS service with `desired_count = 1`.

Resource names key off the Twingate-generated connector name, so several
connectors coexist in one account and region without collision.

## Releases

Every push to `main` runs fmt, validate and `terraform test` — the root and
`connector/` separately — and, if all pass, tags the commit and cuts a release.
Tagging uses [`anothrNick/github-tag-action`](https://github.com/anothrNick/github-tag-action),
pinned by commit SHA.

The bump is a patch by default. Include one of these in the commit message to
change that:

| Token | Effect |
|---|---|
| `#major` | `1.4.9` → `2.0.0` |
| `#minor` | `1.4.9` → `1.5.0` |
| `#patch` | `1.4.9` → `1.4.10` (the default) |
| `#none` | No tag and no release for that commit |

The first release is `v0.0.1` unless that commit carries `#minor`. Pin to a tag
rather than to `main`.

## License

MIT. See [LICENSE](LICENSE).
