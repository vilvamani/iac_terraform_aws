provider "aws" {
  region = var.region
  version = "~> 3.0"
}

module "aws_network" {
  source           = "./modules/network"
  vpc_cidr_range   = var.vpc_cidr_range
  subnet_az        = var.subnet_az
  subnet_cidr      = cidrsubnets(var.vpc_cidr_range, 4, 4, 4, 4)
  tags             = var.tags
}