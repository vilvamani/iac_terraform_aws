region = "us-east-1"
cluster_name  = "training-k8s"

vpc_cidr_range = "10.100.0.0/16"

worker_subnet_ids = ["subnet-63c52e07", "subnet-037b1b2f", "subnet-7d411b35"]
master_subnet_id  = "subnet-63c52e07"

k8s_traffic_cidr = ["10.0.0.0/8"]

key_name = "magellan"
k8s_ami_id = "ami-0affd4508a5d2481b"
min_worker_count = 3
max_worker_count = 6
master_instance_type = "t2.medium"
worker_instance_type = "t2.medium"
hosted_zone = ""
hosted_zone_private = true

addons = [
    "https://raw.githubusercontent.com/vilvamani/ias_terraform_aws/main/k8s-addions/k8s-dashboard.yaml",
    "https://raw.githubusercontent.com/vilvamani/ias_terraform_aws/main/k8s-addions/k8s-heapster.yaml",
    "https://raw.githubusercontent.com/vilvamani/ias_terraform_aws/main/k8s-addions/k8s-autoscaler.yaml"
]

k8s_master_tags = {
    Application = "AWS-Kubernetes"
}

# Tags in a different format for Auto Scaling Group
k8s_node_tags = [
    {
        key                 = "Application"
        value               = "AWS-Kubernetes"
        propagate_at_launch = true
    }
]
