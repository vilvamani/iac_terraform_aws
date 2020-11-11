variable "region" {
  type        = string
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

variable "database_subnets" {
  type        = list
}

variable "bastion_traffic_cidr" {
  type        = list  
}

variable "k8s_traffic_cidr" {
  type        = list  
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
  type        = list  
}
