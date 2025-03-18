data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_vpc" "current_vpc" {
  filter {
    name   = "tag:Name"
    values = ["nap-cloud-ilm-dev-vpc"]
  }
}

data "aws_subnet" "private_subnet_a" {
  filter {
    name   = "tag:Name"
    values = ["nap-cloud-ilm-dev-private-${local.region}a"]
  }
}

data "aws_subnet" "private_subnet_b" {
  filter {
    name   = "tag:Name"
    values = ["nap-cloud-ilm-dev-private-${local.region}b"]
  }
}

data "aws_route_table" "private_a" {
  subnet_id = data.aws_subnet.private_subnet_a.id
}

data "aws_route_table" "private_b" {
  subnet_id = data.aws_subnet.private_subnet_b.id
}
