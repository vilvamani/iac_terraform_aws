output "vpc_id" {
  value = module.aws_network.vpc_id
}

output "public_subnet_one_id" {
  value = module.aws_network.public_subnet_one_id
}

output "public_subnet_two_id" {
  value = module.aws_network.public_subnet_two_id
}

output "private_subnet_one_id" {
  value = module.aws_network.private_subnet_one_id
}

output "private_subnet_two_id" {
  value = module.aws_network.private_subnet_two_id
}
