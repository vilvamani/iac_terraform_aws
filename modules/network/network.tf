resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_range
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags       = "${merge(var.tags, map("Name", "${var.environment}-vpc", "Environment", "${var.environment}"))}"
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}