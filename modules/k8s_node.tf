####################################
##### EC2 Bootstraping scripts #####
####################################

data "template_file" "init_node" {
  template = file("${path.module}/scripts/init-aws-kubernetes-node.sh")

  vars = {
    kubeadm_token     = data.template_file.kubeadm_token.rendered
    master_ip         = aws_eip.k8s_master_eip.public_ip
    master_private_ip = aws_instance.k8s_master.private_ip
    dns_name          = "${var.cluster_name}.${var.hosted_zone}"
  }
}

data "template_cloudinit_config" "node_cloud_init" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init-aws-kubernetes-node.sh"
    content_type = "text/x-shellscript"
    content      = data.template_file.init_node.rendered
  }
}

#########################################
##### K8s Nodes - AWS EC2 instance ######
#########################################

resource "aws_launch_configuration" "k8s_nodes" {
  name_prefix          = "${var.cluster_name}-nodes-"
  image_id             = var.k8s_ami_id
  instance_type        = var.worker_instance_type
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.node_profile.name

  security_groups = [
    aws_security_group.kubernetes.id,
  ]

  associate_public_ip_address = false

  user_data = data.template_cloudinit_config.node_cloud_init.rendered

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "50"
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [user_data]
  }
}

resource "aws_autoscaling_group" "k8s_nodes_asg" {

  vpc_zone_identifier = var.worker_subnet_ids

  name                 = "${var.cluster_name}-nodes"
  max_size             = var.max_worker_count
  min_size             = var.min_worker_count
  desired_capacity     = var.min_worker_count
  launch_configuration = aws_launch_configuration.k8s_nodes.name

  tags = concat(
    [{
      key                 = "kubernetes.io/cluster/${var.cluster_name}"
      value               = "owned"
      propagate_at_launch = true
    },
    {
      key                 = "Name"
      value               = "${var.cluster_name}-node"
      propagate_at_launch = true
    }],
    var.k8s_node_tags,
  )

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}
