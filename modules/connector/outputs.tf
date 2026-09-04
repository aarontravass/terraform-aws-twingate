output "connector_name" {
  description = "Twingate-generated connector name. Every AWS resource this module creates is named from it."
  value       = twingate_connector.this.name
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.this.name
}

output "security_group_id" {
  description = "Id of the egress-only security group created for the task."
  value       = module.this.id
}

output "log_group_name" {
  description = "Log group the task writes to, whether created here or supplied."
  value       = local.log_group_name
}

output "task_definition_arn" {
  description = "ARN of the current task definition revision."
  value       = aws_ecs_task_definition.this.arn
}
