module "this" {
  source             = "terraform-aws-modules/security-group/aws"
  vpc_id             = var.vpc_id
  name               = "twingate-${twingate_connector.this.name}-sg"
  use_name_prefix    = false
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-tcp", "all-udp", "all-icmp"]
  tags = merge(var.tags, {
    service = "twingate"
  })
}
