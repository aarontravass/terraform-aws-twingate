resource "aws_secretsmanager_secret" "this" {
  name = "/twingate/${twingate_connector.this.name}/keys"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    TWINGATE_ACCESS_TOKEN  = "${twingate_connector_tokens.this.access_token}"
    TWINGATE_REFRESH_TOKEN = "${twingate_connector_tokens.this.refresh_token}"
  })
  depends_on = [twingate_connector_tokens.this]
}
