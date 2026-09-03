variable "twingate_network" {
  description = "Twingate network"
  default     = ""
}

variable "tags" { type = map(string) }
variable "env" { type = string }

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

variable "create_twingate_remote_network" {
  type    = bool
  default = true
}

variable "connector_count" {
  default = 2
  type    = number
}
