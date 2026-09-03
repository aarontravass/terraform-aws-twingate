module "this" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 6.0"

  vpc_id          = var.vpc_id
  name            = "twingate-${twingate_connector.this.name}-sg"
  use_name_prefix = false
  description     = "Egress rules for the twingate-${twingate_connector.this.name} connector"

  egress_rules = {
    all_tcp = {
      cidr_ipv4   = "0.0.0.0/0"
      ip_protocol = "tcp"
      from_port   = 0
      to_port     = 65535
      description = "All TCP egress"
    }
    all_udp = {
      cidr_ipv4   = "0.0.0.0/0"
      ip_protocol = "udp"
      from_port   = 0
      to_port     = 65535
      description = "All UDP egress"
    }
    all_icmp = {
      cidr_ipv4   = "0.0.0.0/0"
      ip_protocol = "icmp"
      from_port   = -1
      to_port     = -1
      description = "All ICMP egress"
    }
  }

  tags = merge(var.tags, {
    service = "twingate"
  })
}
