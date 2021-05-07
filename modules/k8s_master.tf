####################################
##### EC2 Bootstraping scripts #####
####################################

data "template_file" "init_master" {
  template = file("${path.module}/scripts/init-aws-kubernetes-master.sh")

  vars = {
    kubeadm_token = data.template_file.kubeadm_token.rendered
    dns_name      = "${var.cluster_name}.${var.hosted_zone}"
    ip_address    = aws_eip.k8s_master_eip.public_ip
    cluster_name  = var.cluster_name
    addons        = join(" ", var.addons)
    aws_region    = var.region
    asg_name      = "${var.cluster_name}-nodes"
    asg_min_nodes = var.min_worker_count
    asg_max_nodes = var.max_worker_count
    aws_subnets   = join(" ", concat(var.worker_subnet_ids, [var.master_subnet_id]))
    efs_dns_name  = module.efs.dns_name
    efs_id        = module.efs.id
  }
}

data "template_file" "cloud_init_config" {
  template = file("${path.module}/scripts/cloud-init-config.yaml")

  vars = {
    calico_yaml = base64gzip(file("${path.module}/scripts/calico.yaml"))
  }
}

data "template_cloudinit_config" "master_cloud_init" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "cloud-init-config.yaml"
    content_type = "text/cloud-config"
    content      = data.template_file.cloud_init_config.rendered
  }

  part {
    filename     = "init-aws-kubernete-master.sh"
    content_type = "text/x-shellscript"
    content      = data.template_file.init_master.rendered
  }
}

#########################################
##### K8s Master - AWS EC2 instance #####
#########################################

resource "aws_eip" "k8s_master_eip" {
  vpc = true
}

resource "aws_instance" "k8s_master" {
  instance_type = var.master_instance_type

  ami = var.k8s_ami_id

  key_name = var.key_name

  subnet_id = var.master_subnet_id

  associate_public_ip_address = false

  vpc_security_group_ids = [
    aws_security_group.kubernetes.id,
  ]

  iam_instance_profile = aws_iam_instance_profile.master_profile.name

  user_data = data.template_cloudinit_config.master_cloud_init.rendered

  tags = merge(
    {
      "Name"                                               = join("-", [var.cluster_name, "master"])
      format("kubernetes.io/cluster/%v", var.cluster_name) = "owned"
    },
    var.k8s_master_tags,
  )

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "50"
    delete_on_termination = true
  }

  lifecycle {
    ignore_changes = [
      ami,
      user_data,
      associate_public_ip_address,
    ]
  }
}

resource "aws_eip_association" "master_assoc" {
  instance_id   = aws_instance.k8s_master.id
  allocation_id = aws_eip.k8s_master_eip.id
}

output "k8s_master_public_ip" {
  value = aws_eip.k8s_master_eip.public_ip
}
