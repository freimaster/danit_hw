# Моніторинг Ubuntu VM та Docker-контейнерів
Працюючі EFK і Node.js не потрібно змінювати або
підключати до його Docker-мережі: cAdvisor бачить контейнери через Docker на цій VM.
Потрібні Ubuntu/Linux, звичайний rootful Docker Engine та Docker Compose v2.
Перевірте, що порти 3000, 9090, 9093, 9100 та локальний 8080 не зайняті.
Моніторинг додасть споживання RAM і диска до EFK; перевіряйте free -h та df -h.
Prometheus/Alertmanager/експортери призначені для приватної навчальної мережі,
не мають автентифікації; не відкривайте їх у публічний Інтернет.

```bash
cd monitoring
cp .env.example .env
cp alertmanager/alertmanager.yml.example alertmanager/alertmanager.yml
nano .env
nano alertmanager/alertmanager.yml
```

У .env задайте власний GRAFANA_ADMIN_PASSWORD.
У alertmanager.yml замініть REPLACE_WITH_BOT_TOKEN і chat_id: 0 своїми значеннями.
chat_id — число без лапок.

Telegram: створіть бота через @BotFather, отримайте token, відкрийте свого бота
й надішліть /start. Для групи додайте бота й надішліть /start у групі.
Щоб дізнатися chat_id, відкрийте на своєму пристрої
https://api.telegram.org/bot<TOKEN>/getUpdates після повідомлення боту:
знайдіть message.chat.id. 

## 2. Запуск

```bash
docker compose up -d
docker compose ps
```

Образи готові, власний Dockerfile не потрібен: Docker-код для здачі — docker-compose.yml.
Не створюємо зайві Dockerfile, які лише повторюють FROM.

Для VM 192.168.1.199:
- Grafana: http://192.168.1.199:3000 — admin і пароль із .env.
- Prometheus targets: http://192.168.1.199:9090/targets
- Prometheus alerts: http://192.168.1.199:9090/alerts
- Alertmanager: http://192.168.1.199:9093

## 3. Метрики для перевірки

На VM:
```bash
curl -s http://localhost:9100/metrics | grep '^node_memory_MemAvailable_bytes'
curl -s http://localhost:8080/metrics | grep '^container_memory_working_set_bytes' | head
```

У Prometheus Query введіть:
```promql
up
```
```promql
100 * (1 - avg by(instance) (rate(node_cpu_seconds_total{job="node-exporter",mode="idle"}[2m])))
```
```promql
100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)
```
```promql
container_memory_working_set_bytes{job="cadvisor",image!=""}
```

Якщо node-exporter DOWN: перевірте docker compose logs node-exporter та доступ
із Docker bridge до host.docker.internal:9100 (зокрема firewall VM).
Якщо у cAdvisor немає назв контейнерів: docker compose logs cadvisor;
перевірте docker info --format '{{.DockerRootDir}}'. При нестандартному DockerRootDir
потрібне відповідне монтування замість /var/lib/docker. Для іншого container runtime
цей конфіг потрібно адаптувати.

## 4. Алерти

### TargetDown (реальний тест)

```bash
docker compose stop cadvisor
```

Зачекайте приблизно 1–2 хв: Targets → DOWN, Alerts → FIRING, Telegram.
Після скрінів:
```bash
docker compose start cadvisor
```

### CPU >80% (реальний тест, сам зупиниться)

На цій VM:
```bash
sudo apt-get update
sudo apt-get install -y stress-ng
stress-ng --cpu 0 --timeout 240s
```

Навантажує всі доступні CPU на 4 хв; EFK у цей час може сповільнитися.
Дострокова зупинка — Ctrl+C.

### Диск <15%
```bash
  sudo dd if=/dev/zero of=/var/tmp/monitoring-fill.bin bs=1M count="вказати Мб" conv=fsync status=progress
```

```bash
  sudo rm -f /var/tmp/monitoring-fill.bin
  ```