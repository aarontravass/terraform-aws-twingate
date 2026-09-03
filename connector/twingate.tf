# The remote network is identified either by id or by name. A caller that
# creates the network in the same apply passes the id, which gives Terraform a
# real dependency edge; a caller attaching to a pre-existing network passes the
# name and the module looks it up.
data "twingate_remote_network" "this" {
  count = var.twingate_remote_network_id == "" ? 1 : 0
  name  = var.twingate_remote_network_name
}

locals {
  remote_network_id = var.twingate_remote_network_id != "" ? var.twingate_remote_network_id : data.twingate_remote_network.this[0].id
}

resource "twingate_connector" "this" {
  remote_network_id = local.remote_network_id
}

resource "twingate_connector_tokens" "this" {
  connector_id = twingate_connector.this.id
}
