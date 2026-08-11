# Ansible

Ansible повністю автоматизує конфігурацію GitLab та GitLab Runner.

## Файли

- `site.yml` — запускає всі playbook-и у правильній послідовності.
- `gitlab.yml` — GitLab CE + Docker + nginx.
- `runner.yml` — Docker + GitLab Runner + автоматична реєстрація.
- `inventory.ini` — автоматично генерується Terraform.

## GitLab

GitLab працює на On-Demand EC2 у public subnet.

nginx приймає HTTP-запити на порту 80 та передає їх у GitLab container.

Користувач:

    root

Пароль:

    your-strong_passwd20260808

Після запуску GitLab Ansible автоматично створює API token.

## GitLab Runner

Runner розташований на Spot EC2 у private subnet.

Ansible:

1. встановлює Docker;
2. встановлює GitLab Runner;
3. використовує API token GitLab;
4. створює Runner через GitLab API;
5. отримує `glrt-` token;
6. реєструє Runner;
7. вмикає `privileged = true`.

Runner tags:

    docker,dind,proxmox

Executor:

    docker

Default image:

    docker:28

## Запуск

Запускаються обидва playbook-и однією командою:

    ansible-playbook -i inventory.ini site.yml
