# Pet Shop

Потрібні Ubuntu VM, Docker із Buildx, Minikube, kubectl, curl, tar, sha256sum
та доступ до GitLab `http://192.168.1.182` і Registry `192.168.1.182:5050`.
У `/etc/docker/daemon.json` додайте `"insecure-registries": ["192.168.1.182:5050"]`
та перезапустіть Docker.

## Запуск

Із каталогу `src/` (або скопіюйте його вміст на VM):

```bash
docker login 192.168.1.182:5050
bash startminikube.sh
bash start.sh
bash test.sh
```

Відкрийте `http://<minikube ip>:30080/` (IP: `minikube ip`).

## CI/CD

1. У GitLab створіть Runner, увімкніть **Run untagged jobs**; попередній Runner вимкніть.
2. Запустіть `bash setup-runner.sh` і введіть токен Runner `glrt-...`.
3. У **Settings → CI/CD → Variables** додайте `REGISTRY_USER` і `REGISTRY_PASSWORD`
   (Masked, доступ до Registry на читання та запис).
4. Завантажте вміст `src/` у корінь GitLab-проєкту та зробіть push.

Pipeline: **build → test → push** одного образу; окрема **deploy** лише для default branch.
