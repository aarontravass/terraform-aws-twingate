data "aws_region" "this" {}

locals {
  aws = {
    region = data.aws_region.this.region
  }
}
