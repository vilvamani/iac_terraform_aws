output "cluster_name" {
  value = "${var.cluster_name}"
}

output "kubeadm_token" {
  value       = data.template_file.kubeadm_token.rendered
}

output "k8s_master_public_ip" {
  value       = aws_eip.k8s_master_eip.public_ip
}

output "efs_id" {
  value = module.efs.id
}

output "mount_target_ids" {
  value = module.efs.mount_target_ids
}

output "dns_name" {
  value = module.efs.dns_name
}