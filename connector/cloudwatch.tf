resource "aws_cloudwatch_log_group" "this" {
  name = "ecs-twingate-${local.aws.region}"
}

resource "aws_cloudwatch_log_stream" "this" {
  name           = "/ecs/twingate/${twingate_connector.this.name}"
  log_group_name = aws_cloudwatch_log_group.this.name
}
