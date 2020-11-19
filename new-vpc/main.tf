provider "aws" {
  region      = var.region
  version     = "~> 3.0"
}

data "aws_availability_zones" "zones" {}

###########################
##### AWS VPC Network #####
###########################

module "aws_network" {
  source                = "terraform-aws-modules/vpc/aws"

  name                  = "${var.cluster_name}-vpc"
  cidr                  =  var.vpc_cidr_range

  enable_dns_hostnames  = true
  enable_dns_support    = true

  azs                   = data.aws_availability_zones.zones.names
  private_subnets       = var.private_subnets
  public_subnets        = var.public_subnets

  enable_nat_gateway    = false
  single_nat_gateway    = false
  enable_vpn_gateway    = false

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

############################################
##### Kubernetes Cluster using kubeadm #####
############################################

module "k8s_cluster" {
  source                = "../modules"
  
  region                = var.region
  cluster_name          = var.cluster_name
  master_subnet_id      = module.aws_network.public_subnets[0]
  worker_subnet_ids     = module.aws_network.public_subnets
  k8s_traffic_cidr      = var.k8s_traffic_cidr
  key_name              = var.key_name
  k8s_ami_id            = var.centos_ami_id
  min_worker_count      = var.min_worker_count
  max_worker_count      = var.max_worker_count
  master_instance_type  = var.master_instance_type
  worker_instance_type  = var.worker_instance_type
  hosted_zone           = var.hosted_zone
  hosted_zone_private   = var.hosted_zone_private
  addons                = var.addons
  k8s_master_tags       = var.k8s_master_tags
  k8s_node_tags         = var.k8s_node_tags
}
