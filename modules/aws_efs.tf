###################################
##### AWS Elastic File System #####
###################################

data "aws_subnet" "efs_subnet" {
  id = var.worker_subnet_ids[0]
}

module "efs" {
  source     = "git::https://github.com/cloudposse/terraform-aws-efs.git?ref=master"

  name               = "${var.cluster_name}-efs"
  region             = var.region
  vpc_id             = data.aws_subnet.efs_subnet.vpc_id
  subnets            = var.worker_subnet_ids
  security_groups    = [aws_security_group.kubernetes.id]
  encrypted          = true
}
