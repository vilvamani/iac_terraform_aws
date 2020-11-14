output "cluster_name" {
  value = "${var.cluster_name}"
}

output "kubeadm_token" {
  description = "Kubeadm token"
  value       = data.template_file.kubeadm_token.rendered
}

output "k8s_master_public_ip" {
  description = "Cluster IP address"
  value       = aws_eip.master.public_ip
}
