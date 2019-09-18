# Internet VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"

  tags = {
    "Name"                                      = var.cluster_name
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# Subnets
resource "aws_subnet" "main-public" {
  count                   = length(var.public_subnet)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.public_subnet, count.index)
  map_public_ip_on_launch = "true"
  availability_zone       = element(var.aws_az, count.index)

  tags = {
    "Name"                                      = var.cluster_name
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

#note on the tags (if private vpc - this tag should be used "kubernetes.io/role/internal-elb", "1")

resource "aws_subnet" "main-private" {
  count                   = length(var.private_subnet)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.private_subnet, count.index)
  map_public_ip_on_launch = "false"
  availability_zone       = element(var.aws_az, count.index)

  tags = {
    "Name"                            = var.cluster_name
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# Internet GW
resource "aws_internet_gateway" "main-gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.cluster_name
  }
}

# route tables
resource "aws_route_table" "main-public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-gw.id
  }
}

resource "aws_route_table_association" "main-public" {
  count          = length(var.public_subnet)
  subnet_id      = element(aws_subnet.main-public.*.id, count.index)
  route_table_id = aws_route_table.main-public.id
}

# Private Subnet Route table 
# Dealing with private subnets is different than the public subner
# we neede to create a nat gateway and attach it to public subnet

#resource "aws_network_interface" "net-interface" {
#  count = "${length(var.PUBLIC_SUBNET)}"
#  subnet_id = "${element(var.PUBLIC_SUBNET, count.index)}"
#  private_ips = ["", "", ""]
#}

resource "aws_eip" "nat-ips" {
  count = length(var.public_subnet)
  vpc   = true
}

resource "aws_nat_gateway" "private-nat-gw" {
  count         = length(var.public_subnet)
  allocation_id = element(aws_eip.nat-ips.*.id, count.index)
  subnet_id     = element(aws_subnet.main-public.*.id, count.index)
}

resource "aws_route_table" "main-private-route" {
  count  = length(var.private_subnet)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.private-nat-gw.*.id, count.index)
  }
}

# TODO: This needs to verify if we can associate subnets to multiple route tables
resource "aws_route_table_association" "main-private1" {
  count          = length(var.private_subnet)
  subnet_id      = element(aws_subnet.main-private.*.id, count.index)
  route_table_id = element(aws_route_table.main-private-route.*.id, count.index)
  #route_table_id = aws_route_table.main-private-route.id[0]
}

#resource "aws_route_table_association" "main-private2" {
#  count          = length(var.private_subnet)
#  subnet_id      = element(aws_subnet.main-private.*.id, count.index)
#  route_table_id = aws_route_table.main-private-route.id[1]
#}
#
#resource "aws_route_table_association" "main-private3" {
#  count          = length(var.private_subnet)
#  subnet_id      = element(aws_subnet.main-private.*.id, count.index)
#  route_table_id = aws_route_table.main-private-route.id[2]
#}