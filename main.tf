provider "aws" {
  region = var.region
  version = "~> 3.0"
}

data "aws_availability_zones" "zones" {}

module "aws_network" {
  source = "terraform-aws-modules/vpc/aws"

  name = "kubernetes-vpc"
  cidr = "10.0.0.0/16"

  azs             = data.aws_availability_zones.zones.names
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "Environment"                                 = "development"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
    "Environment"                                 = "development"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
    "Environment"                                 = "development"
  }
}