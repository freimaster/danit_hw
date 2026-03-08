## Linux може запускати декілька процесів sshd одночасно.

Так як вже є дефолтний конфіг sshd і ми його не хочемо ламати в дослідних цілях, буде:

* sshd (systemd)   -> порт 22
* sshd (manual)    -> порт 2222
* sshd (debug)     -> порт 3333

| sshd         | конфіг                 | порт |
| :----------- | :--------------------: | ---: |
| systemd ssh  |  /etc/ssh/sshd_config  | 22   |
| john`s key   |  sshd_config_2222      | 2222 |
| debug        |  параметри CLI         | 3333 |
## SSH-сервер, який прослуховує порт 2222, обмежено кореневий доступ і забороняючи авторизацію пароля. Доступно тільки john
Створити окремий конфіг: `sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config_2222`
Відредагувати конфіг `sudo mcedit /etc/ssh/sshd_config_2222` привівши наведені рядки у відповідність (можна перезаписати вміст):
```bash
Port 2222
PermitRootLogin no
PasswordAuthentication no
AllowUsers john
PubkeyAuthentication yes
```

Далі дивимось шлях до бінарника, щоб точно: `which sshd` або `command -v sshd` (типово /usr/sbin/sshd)

==Настав час згенерувати ключ:==
## Генерація ключа на клієнті Linux (Ubuntu)

ssh-keygen -t ed25519
*Натиснути **Enter** кілька разів.*
З’являться файли:
~/.ssh/id_ed25519        (приватний ключ)  
~/.ssh/id_ed25519.pub    (публічний ключ)

Подивитися публічний ключ `cat ~/.ssh/id_ed25519.pub` та копіювати **весь рядок**.
## Генерація ключа у Windows (Bitvise SSH Client)
```bash
Відкрити **Bitvise**
Client key manager
Generate New
Тип ключа: **Ed25519**
Save
З’явиться публічний ключ.
```
## Додати ключ для john на сервері

увійти на сервер і виконати:
```bash 
sudo su - john  
mkdir -p ~/.ssh  
chmod 700 ~/.ssh  
mcedit ~/.ssh/authorized_keys
```
вставити скопійований ключ і зберегти з правами доступу `600`
або:
```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```
І стартуєм сервер:
```bash
sudo /usr/sbin/sshd -f /etc/ssh/sshd_config_2222
```

## ssh у режимі налагодження, прослуховуючи порт 3333, без обмежень на підключення користувача (окрім root), з можливістю підключення за паролем і ключем ssh

Створити окремий конфіг: `sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config_3333`
Відредагувати конфіг `sudo mcedit /etc/ssh/sshd_config_3333` привівши наведені рядки у відповідність (можна перезаписати вміст):
```bash
Port 3333
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
```
Далі дивимось шлях до бінарника, щоб точно: `which sshd` або `command -v sshd` (типово /usr/sbin/sshd)
Запускаємо ssh у debug режимі: `sudo /usr/sbin/sshd -d -f /etc/ssh/sshd_config_3333`, 
де `-d` означає **debug mode**, `-f` указує конфіг, з яким стартуємо

або запускаємо без конфіга в терміналі: sudo /usr/sbin/sshd -d -p 3333 -o PermitRootLogin=no -o PasswordAuthentication=yes -o PubkeyAuthentication=yes

---
Перевірити:
`sudo ss -tlnp | grep ssh`
Та `ps aux | grep sshd`