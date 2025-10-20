data "aws_ssm_parameter" "amzn2" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

data "aws_availability_zones" "available" {
  state = "available"
}
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

locals {
  azs_effective = length(var.azs) > 0 ? var.azs : slice(data.aws_availability_zones.available.names, 0, length(var.public_subnets))

  public_map  = zipmap(local.azs_effective, var.public_subnets)
  private_map = zipmap(local.azs_effective, var.private_subnets)

  common_tags = merge(var.tags, {
    Environment = lookup(var.tags, "Environment", "")
    Project     = lookup(var.tags, "Project", "movie-analyst")
  })
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${var.name}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-igw"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-public-rt"
  })
}

resource "aws_route" "public_default_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_subnet" "public" {
  for_each                = local.public_map
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(local.common_tags, {
    Name = "${var.name}-public-${each.key}"
  })

}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "private" {
  for_each          = local.private_map
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = merge(local.common_tags, {
    Name = "${var.name}-private-${each.key}"
  })
}

resource "aws_eip" "nat" {
  count = var.enable_nat ? 1 : 0
  tags  = merge(local.common_tags, { Name = "${var.name}-nat-eip" })
}

resource "aws_instance" "nat" {
  count = var.enable_nat ? 1 : 0

  ami                         = data.aws_ssm_parameter.amzn2.value
  instance_type               = "t3.micro"
  subnet_id                   = element(values(aws_subnet.public), 0).id
  associate_public_ip_address = true

  source_dest_check = false

  user_data = <<-EOF
    #!/bin/bash
    systemctl -w net.ipv4.ip_forward=1
    yum install -y iptables-services
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    service iptables save
    EOF

  tags = merge(local.common_tags, {
    Name = "${var.name}-nat"
  })
}

resource "aws_route" "private_to_nat" {
  count                  = var.enable_nat ? 1 : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nat[0].primary_network_interface_id
}

resource "aws_eip_association" "nat_assoc" {
  count         = var.enable_nat ? 1 : 0
  allocation_id = aws_eip.nat[0].allocation_id
  instance_id   = aws_instance.nat[0].id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-private-rt"
  })
}

resource "aws_route_table_association" "private_assoc" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
