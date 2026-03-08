## watch.sh script
stored in  `/usr/local/bin/watch.sh`

with content:

```bash
#!/bin/bash
WATCH_DIR="$HOME/watch"
mkdir -p "$WATCH_DIR"
while true
do
    for file in "$WATCH_DIR"/*; do
        #якщо файлів немає пропуск
        [ -e "$file" ] || continue
        #пропускаємо оброблені
        [[ "$file" == *.back ]] && continue
        #виводимо вміст
        cat "$file"
        #перейменовуємо
        mv "$file" "$file.back"
    done
    #чекаємо інтервал часу
    sleep 5
done
```
Make the script executable: `sudo chmod +x /usr/local/bin/watch.sh`

## watch.service
stored in  `/etc/systemd/system/watch.service`

with content:
```bash
[Unit]
Description=Watch directory ~/watch

[Service]
User=default-user
ExecStart=/usr/local/bin/watch.sh
Restart=always

[Install]
WantedBy=multi-user.target
```
After that, you need to re-read the list of daemons, activate and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable watch.service
sudo systemctl start watch.service
#chek the state of the service
sudo systemctl status watch.service
```