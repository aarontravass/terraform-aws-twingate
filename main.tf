module "connector" {
  count  = var.connector_count
  source = "./connector"

  vpc_id             = var.vpc_id
  ecs_cluster_arn    = var.ecs_cluster_arn != "" ? var.ecs_cluster_arn : aws_ecs_cluster.this[0].arn
  log_group_name     = aws_cloudwatch_log_group.this.name
  private_subnet_ids = var.private_subnet_ids
  twingate_network   = var.twingate_network
  twingate_image     = var.twingate_image

  # Pass the id when this stack creates the network, so Terraform has a real
  # dependency edge; otherwise pass the name and let the module look it up.
  twingate_remote_network_id   = var.create_twingate_remote_network ? twingate_remote_network.this[0].id : ""
  twingate_remote_network_name = var.create_twingate_remote_network ? "" : var.remote_network_name

  tags = var.tags

  # The service declares a FARGATE capacity_provider_strategy, which AWS rejects
  # until the provider is associated with the cluster.
  depends_on = [aws_ecs_cluster_capacity_providers.this]
}
