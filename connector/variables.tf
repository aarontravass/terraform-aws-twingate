variable "twingate_network" {
  sensitive   = true
  description = "Twingate network"
}

variable "tags" { type = map(string) }
variable "env" { type = string }

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
