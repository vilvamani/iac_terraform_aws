provider "aws" {
  region      = var.region
  version     = "~> 3.0"
}

data "aws_availability_zones" "zones" {}

locals {
  cluster_name = "training-k8s-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "aws_network" {
  source          = "terraform-aws-modules/vpc/aws"

  name            = "kubernetes-vpc"
  cidr            =  var.vpc_cidr_range

  enable_dns_hostnames = true
  enable_dns_support   = true

  azs             = data.aws_availability_zones.zones.names
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  database_subnets = var.database_subnets

  enable_nat_gateway = false
  single_nat_gateway = false
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

module "aws_security_group" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "bastion-sg"
  description = "bastion-sg"
  vpc_id      = module.aws_network.vpc_id

  ingress_cidr_blocks      = ["10.10.0.0/16"]
  ingress_rules            = ["ssh-22-tcp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 30000
      to_port     = 32000
      protocol    = "tcp"
      description = "K8s-service ports"
      cidr_blocks = "10.10.0.0/16"
    },
    {
      rule        = "postgresql-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}
