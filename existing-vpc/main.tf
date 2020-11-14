provider "aws" {
  region      = var.region
  version     = "~> 3.0"
}

############################################
##### Kubernetes Cluster using kubeadm #####
############################################

module "k8s_cluster" {
  source                = "../modules"
  
  region                = var.region
  cluster_name          = var.cluster_name
  master_subnet_id      = var.master_subnet_id
  worker_subnet_ids     = var.worker_subnet_ids
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
