resource "aws_ecs_service" "this" {
  name                  = "twingate-${twingate_connector.this.name}"
  cluster               = var.ecs_cluster_arn
  task_definition       = aws_ecs_task_definition.this.arn
  desired_count         = 1
  force_new_deployment  = true
  wait_for_steady_state = true
  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [module.this.id]
  }
  tags = merge(var.tags, {
    name = "twingate-${twingate_connector.this.name}"
  })
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
  timeouts {
    create = "10m"
    update = "10m"
  }
}
