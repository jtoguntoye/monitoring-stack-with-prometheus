

locals {
  azs = data.aws_availability_zones.aws_azs.names
}

data "aws_availability_zones" "aws_azs" {}

resource "random_id" "random" {
  byte_length = 2
}
resource "aws_vpc" "monitoring_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    "Name" = "monitoring_vpc-${random_id.random.dec}"
  }

  lifecycle {
    create_before_destroy =  true
  }

}

resource "aws_internet_gateway" "monitoring_internet_gateway" {
  vpc_id = aws_vpc.monitoring_vpc.id
  
  tags = {
    "Name" = "monitoring_igw-${random_id.random.dec}"
  }
}

resource "aws_route_table" "monitoring_public_rtb" {
    vpc_id = aws_vpc.monitoring_vpc.id

    tags = {
      "Name" = "monitoring_public_rtb"
    }
}

resource "aws_route" "default_route" {
  route_table_id = aws_route_table.monitoring_public_rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.monitoring_internet_gateway.id
}

resource "aws_default_route_table" "monitoring_private_rtb" {
    default_route_table_id = aws_vpc.monitoring_vpc.default_route_table_id

    tags = {
      "Name" = "monitoring_private"
    }
}

resource "aws_subnet" "mtg_public_subnet" {
  count = length(local.azs)
  vpc_id = aws_vpc.monitoring_vpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone = local.azs[count.index]

  tags = {
    "Name" = "mtg_public_subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "mtg_private_subnet" {
  count = length(local.azs)
  vpc_id = aws_vpc.monitoring_vpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, 3 + count.index)
  availability_zone = local.azs[count.index]

  tags = {
    "Name" = "mtg_private_subnet-${count.index + 1}"
  }
}

resource "aws_route_table_association" "mtg_public_assoc" {
    count = length(local.azs)
    route_table_id = aws_route_table.monitoring_public_rtb.id
    subnet_id = aws_subnet.mtg_public_subnet[count.index].id
}

resource "aws_security_group" "public_sg" {
  name        = "public_sg"
  description = "Security group for public instances"
  vpc_id      = aws_vpc.monitoring_vpc.id
}

resource "aws_security_group_rule" "ingress_all" {
  type = "ingress"
  from_port = 0
  to_port = 65535
  protocol = "-1"
  cidr_blocks = var.access_ip
  security_group_id = aws_security_group.public_sg.id
}

resource "aws_security_group_rule" "egress_all" {
  type = "egress"
  from_port = 0
  to_port = 65535
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public_sg.id
}