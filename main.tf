provider "aws" {
  region      = var.region
  version     = "~> 3.0"
}

data "aws_availability_zones" "zones" {}

##############################
##### AWS Security Group #####
##############################
data "aws_subnet" "cluster_subnet" {
  id = var.master_subnet_id
}

resource "aws_security_group" "kubernetes" {
  vpc_id = data.aws_subnet.cluster_subnet.vpc_id
  name   = "${var.cluster_name}"

  tags = merge(
    {
      "Name"                                               = "${var.cluster_name}"
      format("kubernetes.io/cluster/%v", "${var.cluster_name}") = "owned"
    },
    var.k8s_master_tags,
  )
}

# Allow outgoing connectivity
resource "aws_security_group_rule" "allow_all_outbound_from_kubernetes" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.kubernetes.id
}

# Allow SSH connections only from specific CIDR (TODO)
resource "aws_security_group_rule" "allow_ssh_from_cidr" {
  type      = "ingress"
  from_port = 22
  to_port   = 22
  protocol  = "tcp"

  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = aws_security_group.kubernetes.id
}

# Allow the security group members to talk with each other without restrictions
resource "aws_security_group_rule" "allow_cluster_crosstalk" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.kubernetes.id
  security_group_id        = aws_security_group.kubernetes.id
}

# Allow API connections only from specific CIDR (TODO)
resource "aws_security_group_rule" "allow_api_from_cidr" {
  type      = "ingress"
  from_port = 6443
  to_port   = 6443
  protocol  = "tcp"

  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = aws_security_group.kubernetes.id
}

###################################
##### Generates kubeadm token #####
###################################

resource "random_shuffle" "token1" {
  input        = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "a", "b", "c", "d", "e", "f", "g", "h", "i", "t", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
  result_count = 6
}

resource "random_shuffle" "token2" {
  input        = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "a", "b", "c", "d", "e", "f", "g", "h", "i", "t", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
  result_count = 16
}

data "template_file" "kubeadm_token" {
  template = file("${path.module}/templates/kubeadm_token.tpl")

  vars = {
    token1 = join("", random_shuffle.token1.result)
    token2 = join("", random_shuffle.token2.result)
  }

  depends_on = [
    random_shuffle.token1,
    random_shuffle.token1,
  ]
}

#########################
##### AWS IAM roles #####
#########################

##### K8S Master IAM roles #####

data "template_file" "master_policy_json" {
  template = file("${path.module}/templates/master-policy.json.tpl")

  vars = {}
}

resource "aws_iam_policy" "master_policy" {
  name        = "${var.cluster_name}-master"
  path        = "/"
  description = "Policy for role ${var.cluster_name}-master"
  policy      = data.template_file.master_policy_json.rendered
}

resource "aws_iam_role" "master_role" {
  name = "${var.cluster_name}-master"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_policy_attachment" "master-attach" {
  name = "master-attachment"
  roles = [aws_iam_role.master_role.name]
  policy_arn = aws_iam_policy.master_policy.arn
}

resource "aws_iam_instance_profile" "master_profile" {
  name = "${var.cluster_name}-master"
  role = aws_iam_role.master_role.name
}

##### K8S Node IAM roles #####

data "template_file" "node_policy_json" {
  template = file("${path.module}/templates/node-policy.json.tpl")

  vars = {}
}

resource "aws_iam_policy" "node_policy" {
  name = "${var.cluster_name}-node"
  path = "/"
  description = "Policy for role ${var.cluster_name}-node"
  policy = data.template_file.node_policy_json.rendered
}

resource "aws_iam_role" "node_role" {
  name = "${var.cluster_name}-node"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_policy_attachment" "node-attach" {
  name       = "node-attachment"
  roles      = [aws_iam_role.node_role.name]
  policy_arn = aws_iam_policy.node_policy.arn
}

resource "aws_iam_instance_profile" "node_profile" {
  name = "${var.cluster_name}-node"
  role = aws_iam_role.node_role.name
}

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
##### K8s Master - AWS EC2 instance #####
#########################################

resource "aws_eip" "k8s_master_eip" {
  vpc = true
}

resource "aws_instance" "k8s_master" {
  instance_type = var.master_instance_type

  ami =  var.k8s_ami_id

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
      "Name"                                                 = join("-", [var.cluster_name, "master"])
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

###################################
##### AWS Route53 DNS record ######
###################################


data "aws_route53_zone" "dns_zone" {
  name         = "${var.hosted_zone}."
  private_zone = var.hosted_zone_private
}

resource "aws_route53_record" "k8s_master_dns" {
  zone_id = data.aws_route53_zone.dns_zone.zone_id
  name    = "${var.cluster_name}.${var.hosted_zone}"
  type    = "A"
  records = [aws_eip.k8s_master_eip.public_ip]
  ttl     = 300
}