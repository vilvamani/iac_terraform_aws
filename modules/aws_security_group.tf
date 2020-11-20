##############################
##### AWS Security Group #####
##############################
data "aws_subnet" "cluster_subnet" {
  id = var.master_subnet_id
}

resource "aws_security_group" "kubernetes" {
  vpc_id = data.aws_subnet.cluster_subnet.vpc_id
  name   = var.cluster_name

  tags = merge(
    {
      "Name"                                               = var.cluster_name
      format("kubernetes.io/cluster/%v", var.cluster_name) = "owned"
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

  cidr_blocks       = var.k8s_traffic_cidr
  security_group_id = aws_security_group.kubernetes.id
}

# Allow SSH connections only from specific CIDR (TODO)
resource "aws_security_group_rule" "allow_nodeport_from_cidr" {
  type      = "ingress"
  from_port = 30000
  to_port   = 32000
  protocol  = "tcp"

  cidr_blocks       = var.k8s_traffic_cidr
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

# Allow the CIDR Range to talk with K8s Cluster
resource "aws_security_group_rule" "allow_cluster_outsidetalk" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = var.k8s_traffic_cidr
  security_group_id        = aws_security_group.kubernetes.id
}

# Allow API connections only from specific CIDR (TODO)
resource "aws_security_group_rule" "allow_api_from_cidr" {
  type      = "ingress"
  from_port = 6443
  to_port   = 6443
  protocol  = "tcp"

  cidr_blocks       = var.k8s_traffic_cidr
  security_group_id = aws_security_group.kubernetes.id
}
