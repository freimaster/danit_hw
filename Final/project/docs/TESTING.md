# Перевірки

Оновлено: 2026-11-05.

Нижче збережено результати початкового живого AWS-розгортання. Перевірки після
перейменування папки та додавання пароля з `.env` наведені в останньому розділі.

**Підсумок: розгортання й автоматичне оновлення перевірено; після тестів AWS-стенд повністю видалено через Terraform.**

| Перевірка | Результат |
| --- | --- |
| Python unittest: HTTP 200, query string, 404, SHA update, invalid tag | 5/5 PASS |
| Terraform cluster init / validate | PASS |
| Terraform platform init / validate | PASS |
| Full Bash validate у WSL | PASS |
| Full PowerShell validate у Windows | PASS |
| Helm lint / template Argo Application | PASS |
| kubectl kustomize k8s | PASS, 4 Kubernetes resources |
| AWS STS та доступ до EKS / Route 53 | PASS |
| Docker Hub authentication / public repository | PASS |
| GitHub Actions Secrets | DOCKERHUB_USERNAME та DOCKERHUB_TOKEN налаштовані |
| Docker build / push / container HTTP 200 + correct SHA | PASS: [фінальний GitHub Actions run 42017976395](https://github.com/freimaster/test/actions/runs/42017976395) |
| Terraform DNS apply / Route 53 zone | PASS; NS надано для делегування |
| Terraform cluster apply | PASS; Kubernetes 1.35, один Ready worker c7i-flex.large |
| Terraform platform apply | PASS; 6 resources: 3 Helm releases, Git Secret, 2 CNAME |
| Argo CD Application backend | PASS: Synced / Healthy |
| Backend rollout | PASS: Deployment 1/1, Pod Running, 0 restarts |
| GET http://app.systemd.pp.ua/ через Quad9 DoH | PASS: HTTP 200, version 79ddcbc1de6a36d60067bf190044e84b71cffa8b |
| GET https://argocd.systemd.pp.ua/ | PASS: HTTPS 200, навчальний self-signed certificate |
| Parent pp.ua та Quad9 NS / app CNAME | PASS: делегування Route 53, CNAME на ELB |
| GitOps після наступного коміту | PASS: автоматична зміна version 79ddcbc… → a458f0e…, новий Pod і Synced/Healthy; [CI цього оновлення](https://github.com/freimaster/test/actions/runs/42015559960) |
| Повторний Terraform plan для dns / cluster / platform | PASS: усі три exit 0, No changes |
| Terraform platform destroy | PASS: Application з finalizer, Git Secret, Argo CD, nginx/ELB і DNS records видалено |
| Terraform cluster / dns destroy | PASS: EKS, worker, VPC, IAM та hosted zone видалено |
| Повторний destroy після очищення | PASS: PowerShell завершується успішно, порожні states пропускаються |
| AWS API: EKS, EC2, EBS, ELB, VPC, ENI, security groups, DNS zone, ASG, launch templates, IAM roles проєкту | PASS: 0 залишків для кожної перевіреної категорії |
| Terraform states: dns / cluster / platform та тимчасове recovery | PASS: 0 managed resources у кожному state |
| Перевірка секретів в історії Git | PASS: значення AWS, Docker Hub і GitHub ключів не знайдено |

Перевірку реального контейнера виконано на GitHub runner. AWS CLI 2, kubectl та Helm встановлено
у WSL; Terraform 1.17.1 у WSL використовується для живого розгортання.
Старі NS uaDNS ще присутні в кеші деяких резолверів, тому живі HTTP-тести виконано
через публічний Quad9 DoH. Авторитетний сервер pp.ua підтвердив нове делегування.

Акаунт відхилив t3a.medium/t3.medium як недозволені у Free Tier; кінцевий
тип c7i-flex.large обрано з результату AWS describe-instance-types free-tier-eligible=true.
Невдала група не запустила EC2-інстансів. Її видалення затрималося на боці AWS;
ресурси відновлено в тимчасові Terraform states і прибрано також через Terraform.
Робочий worker, усі допоміжні ресурси та сама невдала група видалені, що перевірено AWS API.

GitHub-репозиторій, GitHub Secrets та публічні Docker Hub образи збережено для повторного запуску.
Локальні ключі збережено в `.env`; Terraform state/backups можуть містити Git-токен.
Ці файли виключено з Git і Docker context; Docker Hub credentials також збережено у GitHub Secrets.
Після видалення hosted zone поверніть NS у реєстратора на `parked1.uadns.com` / `parked2.uadns.com`
або виконайте новий крок `dns` і використайте NS новоствореної зони.

## Перейменування в project і пароль ArgoCD із .env

Логін ArgoCD — `admin`, пароль береться з локального `ARGOCD_ADMIN_PASSWORD`.
Значення передається через sensitive variable; Helm отримує bcrypt-хеш.
Один і той самий пароль зберігає хеш при повторному apply, зміна пароля створює новий хеш.

| Перевірка | Результат |
| --- | --- |
| Папка project, Terraform/Helm relative paths, README та активні .tools helpers | PASS |
| PowerShell validate після перенесення | PASS |
| Повний Bash validate у WSL після перенесення | PASS |
| Bash / PowerShell: .env у папці з пробілами, CRLF, буквальні $, #, &, = і лапки | PASS |
| Порожній, короткий, задовгий пароль або пароль із пробілами | PASS: відмова до першого виклику Terraform |
| Terraform password module: встановлення, повторний plan, зміна пароля, стабільність після зміни, некоректні значення | 8/8 PASS |
| Зафіксований Helm chart 10.13.1: admin.password та admin.passwordMtime в argocd-secret | PASS на публічному тестовому bcrypt-хеші |
| CI: unit tests, усі Terraform roots, password tests, Docker build/push та container HTTP smoke test | PASS: [run 42022261328](https://github.com/freimaster/test/actions/runs/42022261328) |

Ці перевірки виконано без створення AWS-ресурсів. Новий вхід у живий ArgoCD після цієї
зміни не виконувався: попередній AWS-стенд залишається видаленим для економії кредитів.
