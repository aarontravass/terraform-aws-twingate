module "connector" {
  count              = var.connector_count
  source             = "./connector"
  vpc_id             = var.vpc_id
  ecs_cluster_arn    = var.ecs_cluster_arn != "" ? var.ecs_cluster_arn : aws_ecs_cluster.this.arn
  log_group_name     = aws_cloudwatch_log_group.this.name
  private_subnet_ids = var.private_subnet_ids
  twingate_network   = var.twingate_network
  tags               = var.tags
  env                = var.env
  twingate_image     = var.twingate_image
}
