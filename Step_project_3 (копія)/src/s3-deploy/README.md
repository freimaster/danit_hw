# S3 Deploy

Terraform-конфігурація для створення S3 bucket, який використовується як remote backend для state основної AWS-інфраструктури.

State самого `s3-deploy` зберігається локально.

## Запуск

    terraform init
    terraform plan
    terraform apply

## Видалення

Після видалення основної інфраструктури:

    terraform destroy
