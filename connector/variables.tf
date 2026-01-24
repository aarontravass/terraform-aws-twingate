variable "twingate_network" {
  sensitive   = true
  description = "Twingate network"
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
  type = string
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
