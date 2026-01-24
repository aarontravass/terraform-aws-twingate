resource "twingate_remote_network" "this" {
  count    = var.create_twingate_remote_network ? 1 : 0
  name     = var.twingate_network
  location = "AWS"
}
