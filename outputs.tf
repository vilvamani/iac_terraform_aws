output "vpc_id" {
  value = module.aws_network.vpc_id
}

output "subnetone_cidr" {
  value = cidrsubnets("10.1.0.0/16", 4, 4, 8, 4)
}