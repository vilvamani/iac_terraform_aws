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

output "k8s_cluster_name" {
  value = var.cluster_name
}

output "kubeadm_token" {
  value       = module.k8s_cluster.kubeadm_token
}

output "k8s_master_public_ip" {
  value       = module.k8s_cluster.k8s_master_public_ip
}

output "efs_id" {
  value = module.k8s_cluster.efs_id
}

output "mount_target_ids" {
  value = module.k8s_cluster.mount_target_ids
}

output "dns_name" {
  value = module.k8s_cluster.dns_name
}