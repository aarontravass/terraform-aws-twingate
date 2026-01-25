output "connector_name" {
  value = twingate_connector.this.name
}

output "ecs_service_name" {
  value = aws_ecs_service.this.name
}
