variable "twingate_network" {
  description = "Twingate network"
  default     = ""
}

variable "tags" { type = map(string) }
variable "env" { type = string }

variable "enable_dd" {
  type    = bool
  default = false
}

variable "datadog_api_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "twingate_image" {
  type    = string
  default = "twingate/connector:1.83"
}

variable "ecs_cluster_arn" {
  type    = string
  default = ""
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "datadog_container_image" {
  type    = string
  default = "datadog/agent:latest"
}

variable "fluentbit_container_image" {
  type    = string
  default = "amazon/aws-for-fluent-bit:stable"
}

variable "create_twingate_remote_network" {
  type    = bool
  default = true
}

variable "connector_count" {
  default = 2
  type    = number
}
