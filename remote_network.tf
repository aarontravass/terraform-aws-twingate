resource "twingate_remote_network" "this" {
  count    = var.create_twingate_remote_network ? 1 : 0
  name     = var.remote_network_name
  location = var.remote_network_location
}
