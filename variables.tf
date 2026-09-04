# The account subdomain -- "acme" for acme.twingate.com. Distinct from the
# remote network name below.
variable "twingate_network" {
  type        = string
  description = "Twingate account subdomain, without .twingate.com (e.g. \"acme\")"
}

variable "remote_network_name" {
  type        = string
  description = "Name of the Twingate remote network the connectors attach to. Created when create_twingate_remote_network is true, otherwise looked up by this name."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every resource this module creates."
}

variable "env" {
  type        = string
  description = "Environment name. Disambiguates the cluster and log group so the module can be used more than once per account and region."
}

variable "twingate_image" {
  type        = string
  description = "Connector container image."
  default     = "twingate/connector:1.83"
}

variable "ecs_cluster_arn" {
  type        = string
  description = "ARN of an existing ECS cluster to run the connectors in. Leave empty to have this module create one."
  default     = ""
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Subnets the connector tasks run in. Must have egress to the internet, since connectors are outbound-only."
}

variable "vpc_id" {
  type        = string
  description = "VPC the connectors run in."
}

variable "create_twingate_remote_network" {
  type        = bool
  description = "Create the remote network. Set false to attach to one that already exists, looked up by remote_network_name."
  default     = true
}

variable "connector_count" {
  type        = number
  description = "Number of connectors to run. Twingate recommends at least two per remote network so one can be replaced without dropping the tunnel."
  default     = 2
}
