output "cluster_name" {
  value = "${var.cluster_name}"
}

output "kubeadm_token" {
  value       = data.template_file.kubeadm_token.rendered
}

output "k8s_master_public_ip" {
  value       = aws_eip.k8s_master_eip.public_ip
}
