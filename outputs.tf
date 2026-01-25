output "connector_names" {
  value = [for c in module.connector : c.connector_name]
}

output "ecs_service_names" {
  value = [for c in module.connector : c.ecs_service_name]
}
