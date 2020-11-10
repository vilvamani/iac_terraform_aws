variable "region" {
  type        = string
  default     = us-east-1
}

variable "vpc_cidr_range" {
  type        = string
  default     = 10.0.0.0/16
}

variable "private_subnets" {
  type        = list
}

variable "public_subnets" {
  type        = list
}
