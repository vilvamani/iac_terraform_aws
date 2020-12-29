This repository script helps to provision self-managed Kubernetes (K8s) Cluster on AWS EC2 CentOS Operating System. This terraform script helps us to lunch Kubernetes either on New AWS VPC or Existing AWS VPC.

# Infrastructure as Code (IaC)

Infrastructure as code is the process of managing and provisioning computer data centers through machine-readable definition files, rather than physical hardware configuration or interactive configuration tools.

# Terraform

Terraform is an open-source infrastructure as code software tool created by HashiCorp. Users define and provision data center infrastructure using a declarative configuration language known as HashiCorp Configuration Language, or optionally JSON.

# Kubernetes

Kubernetes is an open-source container-orchestration system for automating computer application deployment, scaling, and management. It was originally designed by Google and is now maintained by the Cloud Native Computing Foundation.

## Kubeadm

Kubeadm is a tool built to provide kubeadm init and kubeadm join as best-practice "fast paths" for creating Kubernetes clusters. kubeadm performs the actions necessary to get a minimum viable cluster up and running. By design, it cares only about bootstrapping, not about provisioning machines. Likewise, installing various nice-to-have addons, like the Kubernetes Dashboard, monitoring solutions, and cloud-specific addons, is not in scope.

### Create AWS Infrastructure using terraform

![Kubernetes Cluster IaC](docs/img/architecture.jpg?raw=true "Kubernetes Cluster IaC")

## Terraform Installation on Linux

1. Download Terraform

```
curl -O https://releases.hashicorp.com/terraform/0.14.3/terraform_0.14.3_linux_amd64.zip
```

2. unzip terraofrm executables into `/usr/sbin/`
3. Provide necessary permission

```
chmod -R 777 /usr/sbin/terraform
```

4. Verify Installation by executing below commands

```
terraform -v
```

## Provision self managed Kubernetes cluster on AWS

1. Clone the git repository into bastion machine.

```
git clone https://github.com/vilvamani/iac_terraform_aws.git && cd iac_terraform_aws
```

2. Validate/Update the configuration in the input.tfars file

3. Initialize Terraform configuration files.

```
terraform init
```

4. Run terraform plan to verify the infrastructure

```
terraform plan -var-file=../input.tfvars
```

5. Provision AWS infrastucture and Kubernetes cluster command by exuting terraform apply command.

```
terraform apply -var-file=../input.tfvars
```

6. Destroy the Infrastructure managed by Terraform.

```
terraform destroy -var-file=../input.tfvars
```
