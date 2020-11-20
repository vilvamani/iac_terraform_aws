# iac_terraform_aws
Create AWS Infrastructure using terraform

![Kubernetes Cluster IaC](docs/img/architecture.jpg?raw=true "Kubernetes Cluster IaC")

```
git clone https://github.com/vilvamani/iac_terraform_aws.git && cd iac_terraform_aws
```

```
terraform init
```

```
terraform plan -var-file=../input.tfvars
```

```
terraform apply -var-file=../input.tfvars
```

```
terraform destroy -var-file=../input.tfvars
```

## Terraform Installation

```
curl -O https://releases.hashicorp.com/terraform/0.13.5/terraform_0.13.5_linux_amd64.zip
```

```
unzip terraform_0.13.5_linux_amd64.zip
```

```
sudo mv terraform /usr/sbin/
```
