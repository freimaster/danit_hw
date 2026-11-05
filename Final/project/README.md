# Python → Docker Hub → Argo CD → EKS

Навчальний проєкт для `github.com/freimaster/test` та домену `systemd.pp.ua`.
Python backend повертає HTTP **200** і JSON на `GET /`; інші шляхи повертають 404.
У JSON є `version` — явна версія з `APP_VERSION` у `app/server.py` (наприклад, `v3`),
та `revision` — SHA коміту, з якого зібрано образ.

Перевірено живе розгортання в AWS, HTTP/HTTPS, автоматичне GitOps-оновлення й повний Terraform destroy.
Після тестів 2026-11-05 AWS-стенд **видалено для економії кредитів**;
адреси застосунку працюватимуть після нового apply та делегування його DNS-зони.
Результати: [docs/TESTING.md](docs/TESTING.md).

## Схема

```text
git push main → GitHub Actions → Docker Hub:2222222200022/test:<SHA>
                           └─→ commit нового image tag у k8s/kustomization.yaml
                                                   ↓
                                        Argo CD auto-sync
                                                   ↓
Internet → AWS Classic ELB → nginx ingress → Service → Python Pod:8000
```

- EKS `freimaster`, регіон `eu-central-1`, Kubernetes 1.35.
- Одна managed node group, `min = desired = max = 1`, On-Demand `c7i-flex.large` (4 GiB RAM).
- Дві публічні підмережі у різних AZ; вузол працює в одній із них. NAT Gateway відсутній.
- nginx ingress та Argo CD встановлює Terraform через Helm.
- `http://app.systemd.pp.ua` — backend; `https://argocd.systemd.pp.ua` — Argo CD.
- Route 53: два CNAME на один балансувальник. Існуючі NS у реєстратора треба один раз замінити.
- Для приватного Git-репозиторію Terraform створює repository Secret для Argo CD.

## Файли

| Шлях | Призначення |
| --- | --- |
| `app/server.py` | HTTP backend без сторонніх залежностей |
| `Dockerfile` | Непривілейований контейнер Python |
| `.github/workflows/ci.yml` | Тести, Terraform validate, build/push, оновлення image tag |
| `terraform/dns/` | Hosted zone та NS для делегування домену до запуску EKS |
| `terraform/cluster/` | VPC, підмережі, IAM, EKS та один worker |
| `terraform/platform/` | nginx, Argo CD, Application, Git Secret і DNS |
| `terraform/argocd-password/` | Локальний модуль bcrypt-хешу та тести встановлення/зміни пароля |
| `argocd/templates/application.yaml` | Argo CD Application, упакований у маленький Helm chart |
| `k8s/` | Namespace, Deployment, Service, Ingress та Kustomize image tag |
| `scripts/project.ps1` | Запуск, перевірка і видалення у правильному порядку |
| `scripts/project.sh` | Ті самі операції у WSL / Linux |
| `docs/TESTING.md` | Результати фактично виконаних перевірок |

Terraform має три послідовні кроки: DNS-зона, кластер і встановлення компонентів.
Так можна отримати NS до запуску EKS; Kubernetes API вже існує під час планування встановлення.
Під час видалення спочатку прибираються ресурси кластера й ELB, потім EKS і DNS-зона.
`kubectl apply/delete` для розгортання не потрібен.

## 1. Підготовка

### WSL / Linux

Terraform у вашому WSL уже встановлений. AWS CLI, kubectl і Helm для поточного середовища
встановлено в `~/.local/bin`; додайте цю папку в `PATH`, якщо термінал її ще не бачить:

```bash
export PATH="$HOME/.local/bin:$PATH"
cd /mnt/c/Users/g_fre/Documents/danit_hw/Step_final/project
terraform version
aws --version
```

Після заповнення `.env` і `terraform.tfvars` та успішної публікації образу:

```bash
bash scripts/project.sh validate
bash scripts/project.sh dns  # NS можна делегувати до створення платного EKS
bash scripts/project.sh apply
bash scripts/project.sh verify
# Після завершення роботи:
bash scripts/project.sh destroy
```
```bash
Зміни застосунку — із запуском CI/CD:
git add app/server.py
git commit -m "Update app version"
git pull --rebase --autostash origin main
git push origin main
Зміни скейлінгу — без збірки образу:
git add k8s/deployment.yaml
git commit -m "Update replicas [skip ci]"
git pull --rebase --autostash origin main
git push origin main
```

Скрипт завантажує `.env` самостійно й передає Git-токен та пароль через sensitive Terraform variables.
Значення читаються як дані: спеціальні символи пароля, наприклад `$`, `#` або `&`, зберігаються буквально.
Для запуску користуйтеся `scripts/project.sh` або `scripts/project.ps1`.
`admin_cidrs` можна визначити через `curl -fsS https://checkip.amazonaws.com`.
Виконуйте apply/destroy з однієї робочої копії: її локальні state-файли спільні для Windows і WSL.

### Windows PowerShell

Встановіть Git, Python 3.14, Terraform 1.13.5+, AWS CLI, kubectl та Helm 3.
Docker локально потрібен лише для локальної перевірки контейнера: CI сам збирає образ.
Додайте інструменти в `PATH`.

Якщо Windows блокує локальні PowerShell-скрипти, дозвольте їх лише для поточної сесії:
`Set-ExecutionPolicy -Scope Process Bypass`.

```powershell
git clone https://github.com/freimaster/test.git project
cd project
Copy-Item .env.example .env
```

Заповніть локальний `.env` (без лапок):

```dotenv
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_DEFAULT_REGION=eu-central-1
DOCKERHUB_USERNAME=2222222200022
DOCKERHUB_TOKEN=your-docker-hub-pat
GITHUB_TOKEN=your-github-read-token
ARGOCD_ADMIN_PASSWORD=choose-a-unique-password
```

`GITHUB_TOKEN` потрібен для приватного репозиторію; для публічного видаліть цей рядок.
Для Argo CD достатньо fine-grained PAT із `Contents: Read` тільки для цього репозиторію.
Скрипт читає `.env` у змінні поточного процесу. Ключів у `.tf`/manifests немає.
`.env`, `.tfvars`, Terraform state та плани виключені з Git; Docker context містить лише backend.
State містить чутливі дані, зокрема Git-токен і пароль ArgoCD: зберігайте всі три state-файли локально
до завершення `destroy`, не завантажуйте їх у репозиторій.

AWS-користувачеві потрібні права керувати EKS, EC2/VPC, IAM і Route 53.
Публічний доступ до EKS API обмежується вашою адресою `/32`; SSH до вузла не налаштовується.

## 2. GitHub Actions і Docker Hub

У Docker Hub створіть **public** repository `2222222200022/test` і PAT із Read/Write.
У GitHub → Settings → Secrets and variables → Actions → Secrets додайте:

| Secret | Значення |
| --- | --- |
| `DOCKERHUB_USERNAME` | `2222222200022` |
| `DOCKERHUB_TOKEN` | Docker Hub Personal Access Token |

За потреби змініть repository variable `DOCKERHUB_REPOSITORY` (типово `test`).
GitHub Actions має мати можливість записувати коміти до `main` (`contents: write`).
Якщо branch protection забороняє коміти бота, дозвольте їх або використовуйте окремий GitOps PR-процес.
AWS-ключі GitHub Actions не потрібні: інфраструктура запускається локально через Terraform.

Після push у `main` дочекайтеся успішного workflow **Test, build and publish**.
Workflow запускає контейнер, перевіряє HTTP 200, версію та SHA ревізії, після чого записує новий тег у Git.
Argo CD перевіряє Git кожні 60 секунд і застосовує зміни автоматично (`prune`, `selfHeal`).
Коміт бота не запускає нескінченний цикл CI.

```powershell
git pull --ff-only
Get-Content k8s/kustomization.yaml
```

Перед Terraform apply тег `bootstrap` має бути замінено на SHA реального опублікованого образу.

## 3. Terraform apply

```powershell
Copy-Item terraform/cluster/terraform.tfvars.example terraform/cluster/terraform.tfvars
Copy-Item terraform/dns/terraform.tfvars.example terraform/dns/terraform.tfvars
Copy-Item terraform/platform/terraform.tfvars.example terraform/platform/terraform.tfvars
(Invoke-RestMethod https://checkip.amazonaws.com).Trim()
```

У `terraform/cluster/terraform.tfvars` встановіть `admin_cidrs = ["ВАША_IP/32"]`.
При зміні вашої зовнішньої IP оновіть цю змінну та повторіть apply кластера.
У DNS tfvars можна змінити домен або вказати `existing_zone_id` вже делегованої
**публічної** Route 53 зони. Без `existing_zone_id` Terraform створить нову зону.
У platform tfvars задається URL Git-репозиторію.

```powershell
./scripts/project.ps1 validate
./scripts/project.ps1 dns
./scripts/project.ps1 apply
```

Скрипт виконує `terraform init/apply` для `dns`, `cluster`, потім `platform`.
План підтверджується стандартним `yes`; для автоматичного запуску є `-AutoApprove`.
Використовуйте ту саму AWS-ідентичність, яка створила кластер: вона отримує admin access entry.
Для збереження сесії AWS CLI токен EKS отримується через `aws eks get-token` на вимогу.

Створення EKS зазвичай займає декілька десятків хвилин. За замовчуванням використано
дозволений для цього Free Tier акаунта x86-тип із 4 GiB RAM. Типи можна змінити через
`instance_types`, а `capacity_type = "SPOT"` використати в акаунтах, які це дозволяють.
Належність типу до Free Tier eligible не означає відсутність списання кредитів.
Перевірити дозволені типи: `aws ec2 describe-instance-types --filters Name=free-tier-eligible,Values=true`.
Один вузол допускає простої під час його заміни.

### DNS

Після кроку `dns` скопіюйте чотири NS із output `name_servers` у налаштування домену `systemd.pp.ua`
замість `parked1.uadns.com` / `parked2.uadns.com`.
Якщо домен має інші записи, перенесіть їх перед зміною NS. Це налаштування делегування у реєстратора;
усі записи цього проєкту створює і видаляє Terraform.

```powershell
terraform -chdir=terraform/dns output name_servers
Resolve-DnsName systemd.pp.ua -Type NS
Resolve-DnsName app.systemd.pp.ua
```

Дочекайтеся поширення DNS. Створена Route 53 зона без зміни NS не зробить адреси доступними.
Якщо ваш DNS ще кешує старі NS, у WSL можна перевірити через інший публічний резолвер,
не змінюючи налаштувань системи:
`DNS_DOH_URL=https://dns.quad9.net/dns-query bash scripts/project.sh verify`.

## 4. Перевірка і вхід в Argo CD

```powershell
./scripts/project.ps1 verify
kubectl get nodes
kubectl -n backend get deploy,pods,svc,ingress
kubectl -n argocd get applications
Invoke-RestMethod http://app.systemd.pp.ua/
```

Очікується один `Ready` node, Application `Synced/Healthy`, один backend pod і HTTP 200.
Відкрийте `https://argocd.systemd.pp.ua`, користувач **`admin`**, пароль — значення
**`ARGOCD_ADMIN_PASSWORD`** із локального `.env`.
Пароль задається під час встановлення через Terraform; вручну генерувати чи діставати початковий пароль не потрібно.
Використовуйте 12–72 друковані ASCII-символи без пробілів, записуйте значення без обгортальних лапок.
Скрипт перевіряє пароль перед створенням платних ресурсів і передає його в Terraform як sensitive variable.
Helm отримує bcrypt-хеш у `argocd-secret`; повторний apply з тим самим паролем зберігає той самий хеш.
Щоб змінити пароль, оновіть `.env` і повторіть `apply`. Зміна `.env` сама по собі пароль у кластері не змінює.
Не редагуйте пароль лише через UI ArgoCD: його бажаним значенням керує Terraform.
Пароль та state/backups залишаються локальними й виключені з Git; state/backups також містять секретні дані.
Документація chart: [configs.secret](https://github.com/argoproj/argo-helm/tree/argo-cd-10.13.1/charts/argo-cd).
Навчальний стенд використовує власний сертифікат Argo CD: браузер покаже попередження довіри.
TLS передається через nginx до Argo CD, пароль не передається відкритим HTTP.
Backend використовує HTTP відповідно до мінімальних вимог завдання.

Для перевірки GitOps змініть `APP_VERSION` у `app/server.py`, зробіть commit/push
і дочекайтеся CI та auto-sync. `version` у відповіді має змінитися на задану версію,
а `revision` — на SHA нового коміту.

```bash
sed -i 's/^APP_VERSION = ".*"/APP_VERSION = "v4"/' app/server.py
git add app/server.py
git commit -m "Release v4"
git push origin main
```
Manifests теж доставляються після кожного їхнього коміту без ручного `kubectl apply`.

Локальний запуск без AWS:

```powershell
python -m unittest discover -s tests -v
python app/server.py
# В іншому терміналі:
Invoke-RestMethod http://localhost:8000/
```

Локальна перевірка Docker:

```powershell
docker build --build-arg APP_REVISION=local -t backend:local .
docker run --rm -p 8000:8000 backend:local
```

## 5. Видалення й економія кредитів

```powershell
./scripts/project.ps1 destroy
```

Порядок: Application та його workloads → Git Secret → Argo CD → nginx/ELB та DNS → EKS/worker → VPC/IAM.
Application має Argo finalizer; Terraform чекає видалення перед uninstall Argo CD.
Якщо platform destroy завершився помилкою, скрипт зупиняється і залишає EKS для усунення причини.
Виправте помилку та повторіть destroy; не видаляйте state і не видаляйте кластер вручну.

Видаляється також створена проєктом Route 53 зона. Зона, передана через `existing_zone_id`, зберігається.
Після видалення власної зони поверніть NS у панелі реєстратора. При повторному створенні зони NS можуть змінитися.
GitHub-репозиторій, Docker Hub образи та GitHub Secrets залишаються для наступного запуску;
Terraform керує AWS-ресурсами і встановленням у Kubernetes.

Найбільші статті витрат: EKS control plane, EC2, ELB, public IPv4, диск вузла, Route 53 і трафік.
Без NAT Gateway, додаткових вузлів, ExternalDNS, cert-manager чи окремих баз даних.
EKS control plane оплачується навіть без запущених pod. Для припинення витрат використовуйте destroy.
Фактичні тарифи дивіться в [Amazon EKS pricing](https://aws.amazon.com/eks/pricing/) та AWS Billing.

## Примітки до завдання

- Навчальне GitLab-посилання на EKS вимагає входу, тому його код не копіювався.
  Використано офіційний модуль `terraform-aws-modules/eks/aws` із зафіксованою версією.
- За вимогою завдання встановлено community nginx ingress. Проєкт припинив супровід у березні 2026:
  [офіційна інформація](https://kubernetes.github.io/ingress-nginx/). Для production потрібен підтримуваний контролер.
- Залежності Terraform зафіксовані у `.terraform.lock.hcl`; усі lock-файли зберігаються в Git.
