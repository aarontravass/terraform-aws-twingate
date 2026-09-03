resource "aws_cloudwatch_log_group" "this" {
  name              = "ecs-twingate-${var.env}"
  skip_destroy      = true
  retention_in_days = 5
  tags = merge(var.tags, {
    service = "twingate"
  })
}

resource "aws_ecs_cluster" "this" {
  count = var.ecs_cluster_arn == "" ? 1 : 0
  name  = "twingate-cluster-${var.env}"
  configuration {
    execute_command_configuration {
      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.this.name
      }
      logging = "OVERRIDE"
    }
  }
  tags = merge(var.tags, {
    name = "twingate-cluster-${var.env}"
  })
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  count              = var.ecs_cluster_arn == "" ? 1 : 0
  cluster_name       = aws_ecs_cluster.this[0].name
  capacity_providers = ["FARGATE"]
  default_capacity_provider_strategy {
    base              = 0
    weight            = 1
    capacity_provider = "FARGATE"
  }
}
