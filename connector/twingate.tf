# The remote network is identified either by id or by name. A caller that
# creates the network in the same apply passes the id, which gives Terraform a
# real dependency edge; a caller attaching to a pre-existing network passes the
# name and the module looks it up.
#
# count keys off the name, never the id: an id produced in the same apply is
# unknown at plan time, and an unknown value in count fails the plan outright.
# The name is always a literal input, so the branch is decidable at plan time,
# and the unknown id is harmless as a plain argument.
data "twingate_remote_network" "this" {
  count = var.twingate_remote_network_name != "" ? 1 : 0
  name  = var.twingate_remote_network_name
}

locals {
  remote_network_id = var.twingate_remote_network_name != "" ? data.twingate_remote_network.this[0].id : var.twingate_remote_network_id
}

resource "twingate_connector" "this" {
  remote_network_id = local.remote_network_id
}

resource "twingate_connector_tokens" "this" {
  connector_id = twingate_connector.this.id
}
