data "twingate_remote_network" "this" {
  name = var.twingate_network
}


resource "twingate_connector" "this" {
  remote_network_id = data.twingate_remote_network.this.id
}

resource "twingate_connector_tokens" "this" {
  connector_id = twingate_connector.this.id
}

