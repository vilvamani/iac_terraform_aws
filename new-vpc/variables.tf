variable "region" {
  type        = string
}

variable "cluster_name" {
  description = "Name of the AWS Kubernetes cluster - will be used to name all created resources"
}

variable "vpc_cidr_range" {
  type        = string
}

variable "private_subnets" {
  type        = list
}

variable "public_subnets" {
  type        = list
}

variable "k8s_traffic_cidr" {
  type        = list  
}

variable "key_name" {
  type        = string
}

variable "centos_ami_id" {
  type        = string
}

variable "min_worker_count" {
  type        = string
}

variable "max_worker_count" {
  type        = string
}

variable "master_instance_type" {
  type        = string
}

variable "worker_instance_type" {
  type        = string
}

variable "hosted_zone" {
  type        = string
}

variable "hosted_zone_private" {
  type        = string
}

variable "addons" {
  description = "list of YAML files with Kubernetes addons which should be installed"
  type        = list(string)
}

variable "k8s_master_tags" {
  type        = map(string)
}

variable "k8s_node_tags" {
  type        = list(object({key = string, value = string, propagate_at_launch = bool}))
}
