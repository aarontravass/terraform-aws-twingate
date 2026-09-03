# A caller that already owns a log group (e.g. the root module, which shares one
# group across every connector) passes its name in. When the module is used on
# its own, log_group_name is left empty and it creates a group per connector.
resource "aws_cloudwatch_log_group" "this" {
  count             = var.log_group_name == "" ? 1 : 0
  name              = "/ecs/twingate/${twingate_connector.this.name}"
  retention_in_days = var.log_retention_in_days
  tags = merge(var.tags, {
    service = "twingate"
  })
}

resource "aws_cloudwatch_log_stream" "this" {
  name           = "/ecs/twingate/${twingate_connector.this.name}"
  log_group_name = local.log_group_name
}

locals {
  log_group_name = var.log_group_name != "" ? var.log_group_name : aws_cloudwatch_log_group.this[0].name
}
