resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_range
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags       = "${merge(var.tags, map("Name", "kubernetes-vpc", "Environment", "${var.environment}"))}"
}

resource "aws_subnet" "public_subnet_one" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.subnet_cidr[0]
  availability_zone = var.subnet_az[0]
  tags       = "${merge(var.tags, map("Name", "public-${var.subnet_az[0]}", "Environment", "${var.environment}"))}"
}

resource "aws_subnet" "private_subnet_one" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.subnet_cidr[1]
  availability_zone = var.subnet_az[0]
  tags       = "${merge(var.tags, map("Name", "public-${var.subnet_az[0]}", "Environment", "${var.environment}"))}"
}

resource "aws_subnet" "public_subnet_two" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.subnet_cidr[2]
  availability_zone = var.subnet_az[1]
  tags       = "${merge(var.tags, map("Name", "public-${var.subnet_az[1]}", "Environment", "${var.environment}"))}"
}

resource "aws_subnet" "private_subnet_two" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.subnet_cidr[3]
  availability_zone = var.subnet_az[1]
  tags       = "${merge(var.tags, map("Name", "public-${var.subnet_az[1]}", "Environment", "${var.environment}"))}"
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}