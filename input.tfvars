region = "us-east-1"
vpc_cidr_range = "101.0.0.0/16"
private_subnets = ["101.0.1.0/24", "101.0.2.0/24", "101.0.3.0/24"]
public_subnets  = ["101.0.101.0/24", "101.0.102.0/24", "101.0.103.0/24"]
database_subnets = ["101.0.201.0/24", "101.0.202.0/24", "101.0.203.0/24"]
bastion_traffic_cidr = ["101.0.0.0/16"]
k8s_traffic_cidr = ["101.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
key_name = "doit"
k8s_ami_id = "ami-0947d2ba12ee1ff75"
min_worker_count = 2
max_worker_count = 3
master_instance_type = "t2.medium"
worker_instance_type = "t2.medium"
hosted_zone = "vilvamani.xyz"
hosted_zone_private = false

addons = [
    "https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/storage-class.yaml",
    "https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/heapster.yaml",
    "https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/dashboard.yaml",
    "https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/external-dns.yaml",
    "https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/autoscaler.yaml"
]

tags = {
    Application = "AWS-Kubernetes"
}

tags2 = [
    {
      key                 = "Application"
      value               = "AWS-Kubernetes"
      propagate_at_launch = true
    }
]