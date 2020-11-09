provider "aws" {
  region = var.region
  version = "~> 3.0"
}

module "aws_network" {
  source           = "./modules/network"
  vpc_cidr_range   = var.vpc_cidr_range
  tags             = var.tags
}