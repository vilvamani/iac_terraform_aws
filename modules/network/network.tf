resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_range
  tags       = "${merge(var.tags, map("Name", "${var.environment}-vpc", "Environment", "${var.environment}"))}"
}