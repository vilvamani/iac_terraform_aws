variable "region" {
  type        = string
  default     = "us-east-1"
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

varaibel "ssh_traffic_cidr" {
  type        = list  
}

varaibel "k8s_traffic_cidr" {
  type        = list  
}
