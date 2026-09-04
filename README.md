# terraform-aws-twingate

Runs [Twingate](https://www.twingate.com) connectors on AWS ECS Fargate.

[![Terraform Registry](https://img.shields.io/badge/terraform-registry-7B42BC?logo=terraform)](https://registry.terraform.io/modules/aarontravass/twingate/aws/latest)

Each connector is a single Fargate task that dials out to Twingate — no inbound
ports, no load balancer, no public IP. Connector tokens are issued through the
Twingate provider, written to Secrets Manager, and injected into the task at
runtime, so they never appear in the task definition or in plan output.

## Layout

The repository ships two things that can be used separately:

| Path | What it is |
|---|---|
| **root** | A complete stack: log group, ECS cluster, a Twingate remote network, and `connector_count` connectors. |
| **`modules/connector/`** | One connector. Takes an existing VPC, subnets and cluster and creates everything else per connector. |

Use the root module to stand the whole thing up in an account that has none of
it. Use `modules/connector/` on its own when you already own a cluster and want
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
  source  = "aarontravass/twingate/aws"
  version = "0.2.0"

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
  source  = "aarontravass/twingate/aws//modules/connector"
  version = "0.2.0"

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

In `modules/connector/`, set exactly one of `twingate_remote_network_id` or
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
| connector | ./modules/connector | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_cluster_capacity_providers.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster_capacity_providers) | resource |
| [twingate_remote_network.this](https://registry.terraform.io/providers/Twingate/twingate/3.6.0/docs/resources/remote_network) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| env | Environment name. Disambiguates the cluster and log group so the module can be used more than once per account and region. | `string` | n/a | yes |
| private\_subnet\_ids | Subnets the connector tasks run in. Must have egress to the internet, since connectors are outbound-only. | `list(string)` | n/a | yes |
| remote\_network\_name | Name of the Twingate remote network the connectors attach to. Created when create\_twingate\_remote\_network is true, otherwise looked up by this name. | `string` | n/a | yes |
| tags | Tags applied to every resource this module creates. | `map(string)` | n/a | yes |
| twingate\_network | Twingate account subdomain, without .twingate.com (e.g. "acme") | `string` | n/a | yes |
| vpc\_id | VPC the connectors run in. | `string` | n/a | yes |
| connector\_count | Number of connectors to run. Twingate recommends at least two per remote network so one can be replaced without dropping the tunnel. | `number` | `2` | no |
| create\_twingate\_remote\_network | Create the remote network. Set false to attach to one that already exists, looked up by remote\_network\_name. | `bool` | `true` | no |
| ecs\_cluster\_arn | ARN of an existing ECS cluster to run the connectors in. Leave empty to have this module create one. | `string` | `""` | no |
| twingate\_image | Connector container image. | `string` | `"twingate/connector:1.83"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| connector\_names | Twingate-generated name of each connector. |
| ecs\_service\_names | ECS service name of each connector. |
| remote\_network\_id | Id of the remote network the connectors attach to; empty when this stack did not create one. |
<!-- END_TF_DOCS -->

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
`modules/connector/` separately — and, if all pass, tags the commit and cuts a release.
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
