output "connector_names" {
  description = "Twingate-generated name of each connector."
  value       = [for c in module.connector : c.connector_name]
}

output "ecs_service_names" {
  description = "ECS service name of each connector."
  value       = [for c in module.connector : c.ecs_service_name]
}

output "remote_network_id" {
  description = "Id of the remote network the connectors attach to; empty when this stack did not create one."
  value       = var.create_twingate_remote_network ? twingate_remote_network.this[0].id : ""
}
