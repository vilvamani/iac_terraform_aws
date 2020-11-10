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

##############################
##### AWS Security Group #####
##############################

module "aws_bastion_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "bastion-sg"
  description = "bastion-sg"
  vpc_id      = module.aws_network.vpc_id

  ingress_cidr_blocks      = var.bastion_traffic_cidr
  ingress_rules            = ["ssh-tcp"]
}

module "aws_k8s_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "k8s-sg"
  description = "k8s-sg"
  vpc_id      = module.aws_network.vpc_id

  ingress_cidr_blocks      = var.k8s_traffic_cidr
  ingress_rules            = ["https-443-tcp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 30000
      to_port     = 32000
      protocol    = "tcp"
      description = "K8s-service ports"
      cidr_blocks = "10.10.0.0/16"
    }
  ]
}

###################################
##### Generates kubeadm token #####
###################################

resource "random_shuffle" "token1" {
  input        = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "a", "b", "c", "d", "e", "f", "g", "h", "i", "t", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
  result_count = 6
}

resource "random_shuffle" "token2" {
  input        = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "a", "b", "c", "d", "e", "f", "g", "h", "i", "t", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
  result_count = 16
}

data "template_file" "kubeadm_token" {
  template = file("${path.module}/templates/kubeadm_token.tpl")

  vars = {
    token1 = join("", random_shuffle.token1.result)
    token2 = join("", random_shuffle.token2.result)
  }

  depends_on = [
    random_shuffle.token1,
    random_shuffle.token1,
  ]
}

#########################
##### AWS IAM roles #####
#########################

##### K8S Master IAM roles #####

data "template_file" "master_policy_json" {
  template = file("${path.module}/template/master-policy.json.tpl")

  vars = {}
}

resource "aws_iam_policy" "master_policy" {
  name        = "${var.cluster_name}-master"
  path        = "/"
  description = "Policy for role ${var.cluster_name}-master"
  policy      = data.template_file.master_policy_json.rendered
}

resource "aws_iam_role" "master_role" {
  name = "${var.cluster_name}-master"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_policy_attachment" "master-attach" {
  name = "master-attachment"
  roles = [aws_iam_role.master_role.name]
  policy_arn = aws_iam_policy.master_policy.arn
}

resource "aws_iam_instance_profile" "master_profile" {
  name = "${var.cluster_name}-master"
  role = aws_iam_role.master_role.name
}

##### K8S Node IAM roles #####

data "template_file" "node_policy_json" {
  template = file("${path.module}/template/node-policy.json.tpl")

  vars = {}
}

resource "aws_iam_policy" "node_policy" {
  name = "${var.cluster_name}-node"
  path = "/"
  description = "Policy for role ${var.cluster_name}-node"
  policy = data.template_file.node_policy_json.rendered
}

resource "aws_iam_role" "node_role" {
  name = "${var.cluster_name}-node"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_policy_attachment" "node-attach" {
  name       = "node-attachment"
  roles      = [aws_iam_role.node_role.name]
  policy_arn = aws_iam_policy.node_policy.arn
}

resource "aws_iam_instance_profile" "node_profile" {
  name = "${var.cluster_name}-node"
  role = aws_iam_role.node_role.name
}