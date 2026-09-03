output "connector_name" {
  value = twingate_connector.this.name
}

output "ecs_service_name" {
  value = aws_ecs_service.this.name
}

output "security_group_id" {
  value = module.this.id
}

output "log_group_name" {
  value = local.log_group_name
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.this.arn
}
