module "connector" {
  count                     = var.connector_count
  source                    = "./connector"
  vpc_id                    = var.vpc_id
  ecs_cluster_arn           = var.ecs_cluster_arn
  private_subnet_ids        = var.private_subnet_ids
  twingate_network          = var.twingate_network
  tags                      = var.tags
  env                       = var.env
  enable_dd                 = var.enable_dd
  datadog_api_key           = var.datadog_api_key
  twingate_image            = var.twingate_image
  datadog_container_image   = var.datadog_container_image
  fluentbit_container_image = var.fluentbit_container_image
}
