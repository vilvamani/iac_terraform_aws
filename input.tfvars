region = "us-east-1"
vpc_cidr_range = "10.0.0.0/16"
private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
database_subnets = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]
bastion_traffic_cidr = ["0.0.0.0/0"]
k8s_traffic_cidr = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
key_name = doit
min_worker_count = 1
max_worker_count = 1
master_instance_type = "t2.micro"
worker_instance_type = "t2.micro"
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