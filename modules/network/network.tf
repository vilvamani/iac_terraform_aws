resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_range
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags       = "${merge(var.tags, map("Name", "kubernetes-vpc", "Environment", "${var.environment}"))}"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags       = "${merge(var.tags, map("Name", "kubernetes-vpc-igw", "Environment", "${var.environment}"))}"
}

resource "aws_subnet" "public_subnet_one" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.subnet_cidr[0]
  availability_zone = var.subnet_az[0]
  map_public_ip_on_launch = true
  tags       = "${merge(var.tags, map("Name", "public-${var.subnet_az[0]}", "Environment", "${var.environment}"))}"
}

resource "aws_subnet" "private_subnet_one" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.subnet_cidr[1]
  availability_zone = var.subnet_az[0]
  tags       = "${merge(var.tags, map("Name", "private-${var.subnet_az[0]}", "Environment", "${var.environment}"))}"
}

resource "aws_subnet" "public_subnet_two" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.subnet_cidr[2]
  availability_zone = var.subnet_az[1]
  map_public_ip_on_launch = true
  tags       = "${merge(var.tags, map("Name", "private-${var.subnet_az[1]}", "Environment", "${var.environment}"))}"
}

resource "aws_subnet" "private_subnet_two" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.subnet_cidr[3]
  availability_zone = var.subnet_az[1]
  tags       = "${merge(var.tags, map("Name", "public-${var.subnet_az[1]}", "Environment", "${var.environment}"))}"
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags       = "${merge(var.tags, map("Name", "public-rt", "Environment", "${var.environment}"))}"
}

resource "aws_route_table_association" "public_rt_ass1" {
  subnet_id      = aws_subnet.public_subnet_one.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_ass2" {
  subnet_id      = aws_subnet.public_subnet_two.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

  tags       = "${merge(var.tags, map("Name", "private-rt", "Environment", "${var.environment}"))}"
}

resource "aws_route_table_association" "private_rt_ass1" {
  subnet_id      = aws_subnet.private_subnet_one.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "public_rt_ass2" {
  subnet_id      = aws_subnet.private_subnet_two.id
  route_table_id = aws_route_table.private_rt.id
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnet_one_id" {
  value = aws_subnet.public_subnet_one.id
}

output "public_subnet_two_id" {
  value = aws_subnet.public_subnet_two.id
}

output "private_subnet_one_id" {
  value = aws_subnet.private_subnet_one.id
}

output "private_subnet_two_id" {
  value = aws_subnet.private_subnet_two.id
}
