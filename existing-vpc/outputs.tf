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
