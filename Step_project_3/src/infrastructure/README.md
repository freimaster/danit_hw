# Terraform AWS Infrastructure

Основна AWS-інфраструктура Step Project 3.

## Створювані ресурси

- VPC `10.30.0.0/16`;
- public subnet `10.30.1.0/24`;
- private subnet `10.30.2.0/24`;
- Internet Gateway;
- NAT Gateway + Elastic IP;
- public/private Route Tables;
- Security Groups;
- GitLab EC2 On-Demand у public subnet;
- GitLab Runner EC2 Spot у private subnet.

SSH public key додається на EC2 через Terraform `user_data`.

## Terraform state

State зберігається у S3 remote backend:

    step-project-3/infrastructure/terraform.tfstate

## Запуск

```bash
    terraform fmt
    terraform init -backend-config="bucket=$(terraform -chdir=../s3-deploy output -raw state_bucket_name)"
    terraform validate
    terraform plan
    terraform apply

## Результати

Terraform виводить:

- GitLab public IP;
- GitLab private IP;
- Runner private IP;
- VPC ID;
- Public Subnet ID;
- Private Subnet ID.

## Видалення

    terraform destroy
