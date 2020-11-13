output "vpc_id" {
  value = module.aws_network.vpc_id
}

output "public_subnets" {
  value = module.aws_network.public_subnets
}

output "private_subnets" {
  value = module.aws_network.private_subnets
}

output "igw_id" {
  value = module.aws_network.igw_id
}

output "public_route_table_ids" {
  value = module.aws_network.public_route_table_ids
}

output "private_route_table_ids" {
  value = module.aws_network.private_route_table_ids
}

output "kubeadm_token" {
  description = "Kubeadm token"
  value       = data.template_file.kubeadm_token.rendered
}

output "k8s_master_public_ip" {
  description = "Cluster IP address"
  value       = aws_eip.master.public_ip
}
