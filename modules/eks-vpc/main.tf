# Internet VPC
resource "aws_vpc" "main" {
  cidr_block           = "${var.VPC_CIDR_BLOCK}"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"

  tags = "${
    map(
     "Name", "${var.CLUSTER_NAME}",
     "kubernetes.io/cluster/${var.CLUSTER_NAME}", "shared",
    )
  }"
}

# Subnets
resource "aws_subnet" "main-public" {
  count                   = "${length(var.PUBLIC_SUBNET)}"
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${element(var.PUBLIC_SUBNET, count.index)}"
  map_public_ip_on_launch = "true"
  availability_zone       = "${element(var.AWS_AZ, count.index)}"

  tags = "${
    map(
     "Name", "${var.CLUSTER_NAME}",
     "kubernetes.io/cluster/${var.CLUSTER_NAME}", "shared",
    )
  }"
}

#note on the tags (if private vpc - this tag should be used "kubernetes.io/role/internal-elb", "1")

resource "aws_subnet" "main-private" {
  count                   = "${length(var.PRIVATE_SUBNET)}"
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${element(var.PRIVATE_SUBNET, count.index)}"
  map_public_ip_on_launch = "false"
  availability_zone       = "${element(var.AWS_AZ, count.index)}"

  tags = "${
    map(
     "Name", "${var.CLUSTER_NAME}",
     "kubernetes.io/role/internal-elb", "1",
    )
  }"
}

# Internet GW
resource "aws_internet_gateway" "main-gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "${var.CLUSTER_NAME}"
  }
}

# route tables
resource "aws_route_table" "main-public" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main-gw.id}"
  }
}

resource "aws_route_table_association" "main-public" {
  count          = "${length(var.PUBLIC_SUBNET)}"
  subnet_id      = "${element(aws_subnet.main-public.*.id, count.index)}"
  route_table_id = "${aws_route_table.main-public.id}"
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
  count = "${length(var.PUBLIC_SUBNET)}"
  vpc   = true
}

resource "aws_nat_gateway" "private-nat-gw" {
  count         = "${length(var.PUBLIC_SUBNET)}"
  allocation_id = "${element(aws_eip.nat-ips.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.main-public.*.id, count.index)}"
}

resource "aws_route_table" "main-private-route" {
  count  = "${length(var.PRIVATE_SUBNET)}"
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.private-nat-gw.*.id, count.index)}"
  }
}

resource "aws_route_table_association" "main-private" {
  count          = "${length(var.PRIVATE_SUBNET)}"
  subnet_id      = "${element(aws_subnet.main-private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.main-private-route.*.id, count.index)}"
}
