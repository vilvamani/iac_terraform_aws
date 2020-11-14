output "k8s_cluster_name" {
  value = "${var.cluster_name}"
}

output "kubeadm_token" {
  value       = module.k8s_cluster.kubeadm_token
}

output "k8s_master_public_ip" {
  value       = module.k8s_cluster.k8s_master_public_ip
}
