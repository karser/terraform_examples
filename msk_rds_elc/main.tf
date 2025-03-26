provider "aws" {
  region = var.region
}

data "aws_vpc" "santa_vpc" {
}

data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.santa_vpc.id]
  }
  filter {
    name   = "subnet-id"
    values = ["subnet-0808ce23f1b2d3cca", "subnet-0b9900cc0934fc67e"]
  }
}

locals {
  vpc_cidr = data.aws_vpc.santa_vpc.cidr_block
}
