# iac_terraform_aws
Create AWS Infrastructure using terraform

![Kubernetes Cluster IaC](docs/img/architecture.jpg?raw=true "Kubernetes Cluster IaC")

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
