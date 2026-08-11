# Step Project 3 — Source Code

Проєкт автоматично розгортає AWS-інфраструктуру, GitLab та GitLab Runner за допомогою Terraform і Ansible.

## Структура

- `s3-deploy/` — створення S3 bucket для Terraform remote state.
- `infrastructure/` — AWS VPC, subnet-и, IGW, NAT Gateway, Security Groups, GitLab EC2 та GitLab Runner EC2.
- `ansible/` — автоматичне встановлення GitLab, nginx, Docker, GitLab Runner та реєстрація Runner.
- `gitlab/` — CI/CD pipeline та пов'язані файли.

## Terraform — шпаргалка

- `main.tf` — основні ресурси.
- `providers.tf` — providers та їх версії.
- `variables.tf` — вхідні змінні.
- `terraform.tfvars` — значення змінних.
- `outputs.tf` — результати Terraform.
- `backend.tf` — місце зберігання Terraform state.
- `.terraform.lock.hcl` — зафіксовані версії provider-ів.
- `terraform.tfstate` — стан створеної інфраструктури.
- `.terraform/` — локальні службові файли Terraform.

## Terraform state

State проєкту `s3-deploy` зберігається локально:

    src/s3-deploy/terraform.tfstate

State основної AWS-інфраструктури зберігається у S3:

    s3://<bucket>/step-project-3/infrastructure/terraform.tfstate

## Порядок розгортання

### 1. Створення S3

    cd src/s3-deploy
    terraform fmt
    terraform init
    terraform apply

### 2. Створення AWS-інфраструктури

    cd ../infrastructure
    terraform fmt
    terraform init \
      -backend-config="bucket=$(terraform -chdir=../s3-deploy output -raw state_bucket_name)"
    terraform plan
    terraform apply

Terraform створює:

- VPC;
- public subnet;
- private subnet;
- Internet Gateway;
- NAT Gateway;
- GitLab EC2 On-Demand;
- GitLab Runner EC2 Spot;
- Security Groups.

### 3. Налаштування GitLab та Runner

Після генерації Ansible inventory:

    cd ansible
    ansible-playbook -i inventory.ini site.yml

`site.yml` послідовно запускає:

    gitlab.yml
    runner.yml

`gitlab.yml`:

- встановлює Docker;
- запускає GitLab CE;
- встановлює nginx reverse proxy;
- задає root password;
- створює GitLab API token.

`runner.yml`:

- встановлює Docker;
- встановлює GitLab Runner;
- через GitLab API створює Runner;
- отримує `glrt-` authentication token;
- реєструє Runner;
- вмикає Docker privileged mode.

## GitLab

Користувач:

    root

Пароль:

    your-strong_passwd20260808

## Видалення

Спочатку видаляється основна AWS-інфраструктура:

    cd infrastructure
    terraform destroy

Після цього видаляється S3 bucket:

    cd ../s3-deploy
    terraform destroy
