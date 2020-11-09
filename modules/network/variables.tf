variable "region" {
    type        = "string"
    default = "us-east-1"
}

variable "environment" {
  type        = "string"
  default     = "development"
}

variable "vpc_cidr_range" {
    type        = "string"
    default = "10.0.0.0/16"
}

variable "subnet_az" {
}

variable "subnet_cidr" {
}

variable "tags" {
}