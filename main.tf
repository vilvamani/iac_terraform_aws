provider "aws" {
  region = "us-east-1"
  version = "~> 3.0"
}

module "aws_network" {
  source           = "./modules/network"
}