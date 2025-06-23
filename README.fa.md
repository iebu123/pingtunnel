# پینگ‌تونل (Pingtunnel)

[<img src="https://img.shields.io/github/license/esrrhs/pingtunnel">](https://github.com/esrrhs/pingtunnel)
[<img src="https://img.shields.io/github/languages/top/esrrhs/pingtunnel">](https://github.com/esrrhs/pingtunnel)
[![Go Report Card](https://goreportcard.com/badge/github.com/esrrhs/pingtunnel)](https://goreportcard.com/report/github.com/esrrhs/pingtunnel)
[<img src="https://img.shields.io/github/v/release/esrrhs/pingtunnel">](https://github.com/esrrhs/pingtunnel/releases)
[<img src="https://img.shields.io/github/downloads/esrrhs/pingtunnel/total">](https://github.com/esrrhs/pingtunnel/releases)
[<img src="https://img.shields.io/docker/pulls/esrrhs/pingtunnel">](https://hub.docker.com/repository/docker/esrrhs/pingtunnel)
[<img src="https://img.shields.io/github/actions/workflow/status/esrrhs/pingtunnel/go.yml?branch=master">](https://github.com/esrrhs/pingtunnel/actions)

پینگ‌تونل ابزاری است که ترافیک TCP/UDP را از طریق ICMP ارسال می‌کند.

## توجه: این ابزار فقط برای اهداف مطالعاتی و پژوهشی است. استفاده غیرقانونی ممنوع است.

![image](network.jpg)

## نحوه استفاده

### 🚀 نصب و راه‌اندازی سریع (توصیه‌شده)

دستور زیر را اجرا کنید تا اسکریپت نصب دانلود و اجرا شود:

```bash
curl -fsSL https://raw.githubusercontent.com/iebu123/pingtunnel/master/pingtunnel-install.sh -o pingtunnel-install.sh && bash pingtunnel-install.sh
```

---

### 💻 نصب دستی

#### نصب سرور

- یک سرور با IP عمومی تهیه کنید (مثلاً EC2 در AWS) و فرض کنید دامنه یا IP سرور شما www.yourserver.com است.
- بسته مناسب را از [releases](https://github.com/esrrhs/pingtunnel/releases) دانلود و استخراج کنید و با دسترسی root اجرا نمایید.
- پارامتر `-key` باید عددی بین ۰ تا ۲۱۴۷۴۸۳۶۴۷ باشد.

```
sudo wget (لینک آخرین نسخه)
sudo unzip pingtunnel_linux64.zip
sudo ./pingtunnel -type server
```

- (اختیاری) غیرفعال کردن پینگ پیش‌فرض سیستم:

```
echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all
```

#### نصب کلاینت

- بسته مناسب را از [releases](https://github.com/esrrhs/pingtunnel/releases) دانلود و استخراج کنید.
- با دسترسی administrator اجرا کنید. دستورات زیر برای انواع مختلف فورواردینگ است.
- اگر لاگ ping pong را مشاهده کردید، اتصال برقرار است.
- پارامتر `-key` باید عددی بین ۰ تا ۲۱۴۷۴۸۳۶۴۷ باشد.

##### فورواردینگ sock5

```
pingtunnel.exe -type client -l :4455 -s www.yourserver.com -sock5 1
```

##### فورواردینگ tcp

```
pingtunnel.exe -type client -l :4455 -s www.yourserver.com -t www.yourserver.com:4455 -tcp 1
```

##### فورواردینگ udp

```
pingtunnel.exe -type client -l :4455 -s www.yourserver.com -t www.yourserver.com:4455
```

### استفاده از داکر

می‌توانید با داکر نیز اجرا کنید. پارامترها مشابه بالا هستند.
- سرور:
```
docker run --name pingtunnel-server -d --privileged --network host --restart=always esrrhs/pingtunnel ./pingtunnel -type server -key 123456
```
- کلاینت:
```
docker run --name pingtunnel-client -d --restart=always -p 1080:1080 esrrhs/pingtunnel ./pingtunnel -type client -l :1080 -s www.yourserver.com -sock5 1 -key 123456
```

---

### 🔧 راه‌اندازی پینگ‌تونل به عنوان سرویس systemd (حالت سرور)

۱. فایل سرویس را در مسیر زیر بسازید:

```
/etc/systemd/system/pingtunnel.service
```

۲. محتوای زیر را در فایل قرار دهید:

```ini
[Unit]
Description=PingTunnel Server
Documentation=https://github.com/esrrhs/pingtunnel
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/local/bin/pingtunnel -type server -key 123456 -tcp 1 -nolog 1
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=pingtunnel

# تنظیمات امنیتی
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true

# دسترسی‌های شبکه (برای ICMP)
AmbientCapabilities=CAP_NET_RAW
CapabilityBoundingSet=CAP_NET_RAW

[Install]
WantedBy=multi-user.target
```

۳. سرویس را فعال و اجرا کنید:

```bash
sudo systemctl daemon-reload
sudo systemctl enable pingtunnel.service
sudo systemctl start pingtunnel.service
sudo systemctl status pingtunnel.service
```

🛡️ **توجه:**
مقدار `-key` باید یک عدد صحیح مثبت و غیرصفر باشد (بین ۱ تا ۲۱۴۷۴۸۳۶۴۷). از کلیدهای ساده استفاده نکنید.

---

### 🔧 راه‌اندازی پینگ‌تونل به عنوان سرویس systemd (حالت کلاینت)

۱. فایل سرویس را در مسیر زیر بسازید:

```
/etc/systemd/system/pingtunnel@.service
```

محتوای زیر را در فایل قرار دهید:

```ini
[Unit]
Description=Pingtunnel Client Service (%i)
Documentation=https://github.com/esrrhs/pingtunnel
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
Group=root
EnvironmentFile=/etc/pingtunnel/pingtunnel-%i.conf
ExecStart=/usr/local/bin/pingtunnel -type client -l :${CLIENT_PORT} -s ${SERVER_IP} -t ${SERVER_IP}:${SERVER_PORT} -tcp ${TCP_MODE} -key ${KEY} -noprint ${NO_PRINT} -nolog ${NO_LOG} ${EXTRA_PARAMS}
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=pingtunnel-%i

# تنظیمات امنیتی
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictRealtime=true
RestrictSUIDSGID=true

# دسترسی‌های شبکه (برای ICMP)
AmbientCapabilities=CAP_NET_RAW
CapabilityBoundingSet=CAP_NET_RAW

[Install]
WantedBy=multi-user.target
```

۲. فایل پیکربندی را بسازید:

```bash
sudo mkdir -p /etc/pingtunnel/
sudo nano /etc/pingtunnel/pingtunnel-server1.conf
```

نمونه محتوا برای `/etc/pingtunnel/pingtunnel-server1.conf`:

```bash
SERVER_IP=1.2.3.4
CLIENT_PORT=1080
SERVER_PORT=4455
KEY=123456
TCP_MODE=1
NO_PRINT=0
NO_LOG=1
EXTRA_PARAMS=""
```

> **توجه:** مقادیر را با اطلاعات واقعی خود جایگزین کنید. همه متغیرها باید به درستی تنظیم شوند.

۳. سرویس را فعال و اجرا کنید:

```bash
sudo systemctl daemon-reload
sudo systemctl enable pingtunnel@server1.service
sudo systemctl start pingtunnel@server1.service
sudo systemctl status pingtunnel@server1.service
```

## با تشکر از JetBrains برای لایسنس رایگان Open Source

<img src="https://resources.jetbrains.com/storage/products/company/brand/logos/GoLand.png" height="200"/>
