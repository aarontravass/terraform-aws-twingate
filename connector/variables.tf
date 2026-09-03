# The account subdomain -- "acme" for acme.twingate.com. This is what the
# connector container's TWINGATE_NETWORK expects, and it is a different thing
# from the remote network the connector attaches to.
variable "twingate_network" {
  type        = string
  description = "Twingate account subdomain, without .twingate.com (e.g. \"acme\")"
}

variable "twingate_remote_network_id" {
  type        = string
  description = "Id of the Twingate remote network to attach the connector to. Set exactly one of this or twingate_remote_network_name."
  default     = ""
}

variable "twingate_remote_network_name" {
  type        = string
  description = "Name of an existing Twingate remote network to attach the connector to. Set exactly one of this or twingate_remote_network_id."
  default     = ""

  validation {
    condition     = (var.twingate_remote_network_id != "") != (var.twingate_remote_network_name != "")
    error_message = "Set exactly one of twingate_remote_network_id or twingate_remote_network_name."
  }
}

variable "tags" { type = map(string) }

variable "twingate_image" {
  type    = string
  default = "twingate/connector:1.83"
}

variable "ecs_cluster_arn" {
  type        = string
  description = "ARN of the ECS cluster the connector service runs in"
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "log_group_name" {
  type        = string
  description = "Name of an existing CloudWatch log group to write connector task logs to. Leave empty to have the module create one per connector."
  default     = ""
}

variable "log_retention_in_days" {
  type        = number
  description = "Retention for the log group created when log_group_name is empty. Ignored otherwise."
  default     = 30
}
