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

variable "tags" { type = map(string) }
variable "env" { type = string }

variable "twingate_image" {
  type    = string
  default = "twingate/connector:1.83"
}

variable "ecs_cluster_arn" {
  type        = string
  description = "ARN of an existing ECS cluster to run the connectors in. Leave empty to have this module create one."
  default     = ""
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "create_twingate_remote_network" {
  type    = bool
  default = true
}

variable "connector_count" {
  default = 2
  type    = number
}
