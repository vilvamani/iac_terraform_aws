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

variable "ssh_traffic_cidr" {
  type        = list  
}

variable "k8s_traffic_cidr" {
  type        = list  
}
