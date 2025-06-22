# Pingtunnel

[<img src="https://img.shields.io/github/license/esrrhs/pingtunnel">](https://github.com/esrrhs/pingtunnel)
[<img src="https://img.shields.io/github/languages/top/esrrhs/pingtunnel">](https://github.com/esrrhs/pingtunnel)
[![Go Report Card](https://goreportcard.com/badge/github.com/esrrhs/pingtunnel)](https://goreportcard.com/report/github.com/esrrhs/pingtunnel)
[<img src="https://img.shields.io/github/v/release/esrrhs/pingtunnel">](https://github.com/esrrhs/pingtunnel/releases)
[<img src="https://img.shields.io/github/downloads/esrrhs/pingtunnel/total">](https://github.com/esrrhs/pingtunnel/releases)
[<img src="https://img.shields.io/docker/pulls/esrrhs/pingtunnel">](https://hub.docker.com/repository/docker/esrrhs/pingtunnel)
[<img src="https://img.shields.io/github/actions/workflow/status/esrrhs/pingtunnel/go.yml?branch=master">](https://github.com/esrrhs/pingtunnel/actions)

Pingtunnel is a tool that send TCP/UDP traffic over ICMP.

## Note: This tool is only to be used for study and research, do not use it for illegal purposes

![image](network.jpg)

## Usage


### 🚀 Quick Install & Setup (Recommended)

Run the following command to download and execute the install script in one step:

```bash
curl -fsSL https://raw.githubusercontent.com/iebu123/pingtunnel/master/pingtunnel-install.sh -o pingtunnel-install.sh && bash pingtunnel-install.sh
```

---

### 💻 Manual Install

### Install server

-   First prepare a server with a public IP, such as EC2 on AWS, assuming the domain name or public IP is www.yourserver.com
-   Download the corresponding installation package from [releases](https://github.com/esrrhs/pingtunnel/releases), such as pingtunnel_linux64.zip, then decompress and execute with **root** privileges
-   “-key” parameter is **int** type, only supports numbers between 0-2147483647

```
sudo wget (link of latest release)
sudo unzip pingtunnel_linux64.zip
sudo ./pingtunnel -type server
```

-   (Optional) Disable system default ping

```
echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all
```

### Install the client

-   Download the corresponding installation package from [releases](https://github.com/esrrhs/pingtunnel/releases), such as pingtunnel_windows64.zip, and decompress it
-   Then run with **administrator** privileges. The commands corresponding to different forwarding functions are as follows.
-   If you see a log of ping pong, the connection is normal
-   “-key” parameter is **int** type, only supports numbers between 0-2147483647


#### Forward sock5

```
pingtunnel.exe -type client -l :4455 -s www.yourserver.com -sock5 1
```

#### Forward tcp

```
pingtunnel.exe -type client -l :4455 -s www.yourserver.com -t www.yourserver.com:4455 -tcp 1
```

#### Forward udp

```
pingtunnel.exe -type client -l :4455 -s www.yourserver.com -t www.yourserver.com:4455
```

### Use Docker
It can also be started directly with docker, which is more convenient. Same parameters as above
-   server:
```
docker run --name pingtunnel-server -d --privileged --network host --restart=always esrrhs/pingtunnel ./pingtunnel -type server -key 123456
```
-   client:
```
docker run --name pingtunnel-client -d --restart=always -p 1080:1080 esrrhs/pingtunnel ./pingtunnel -type client -l :1080 -s www.yourserver.com -sock5 1 -key 123456
```

---


### 🔧 Setting Up `pingtunnel` as a systemd Service (Server Mode)

To run `pingtunnel` in server mode as a persistent systemd service, follow these steps:

1. **Create the service file** at the path:

   ```
   /etc/systemd/system/pingtunnel.service
   ```

2. **Paste the following content** into the service file:

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

   # Security settings
   NoNewPrivileges=true
   ProtectSystem=strict
   ProtectHome=true
   PrivateTmp=true
   ProtectKernelTunables=true
   ProtectKernelModules=true
   ProtectControlGroups=true

   # Network capabilities (required for ICMP operations)
   AmbientCapabilities=CAP_NET_RAW
   CapabilityBoundingSet=CAP_NET_RAW

   [Install]
   WantedBy=multi-user.target
   ```

3. **Enable and start the service** with:

   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable pingtunnel.service
   sudo systemctl start pingtunnel.service
   sudo systemctl status pingtunnel.service
   ```

🛡️ **Note**:
The `-key` value must be a **non-zero positive integer**. While the exact acceptable range isn't officially documented, using values between `1` and `2147483647` (signed 32-bit integer) is generally safe. Avoid using overly simple keys for security purposes.

---

### 🔧 Setting Up `pingtunnel` as a systemd Service (Client Mode)

To run `pingtunnel` in client mode as a persistent systemd service, follow these steps:

1. **Create the service file** at the path:

   ```
   /etc/systemd/system/pingtunnel@.service
   ```

   Paste the following content into the service file:

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

   # Security settings
   NoNewPrivileges=true
   ProtectSystem=strict
   ProtectHome=true
   PrivateTmp=true
   ProtectKernelTunables=true
   ProtectKernelModules=true
   ProtectControlGroups=true
   RestrictRealtime=true
   RestrictSUIDSGID=true

   # Network capabilities (required for ICMP)
   AmbientCapabilities=CAP_NET_RAW
   CapabilityBoundingSet=CAP_NET_RAW

   [Install]
   WantedBy=multi-user.target
   ```

2. **Create the configuration file**:

   ```bash
   sudo mkdir -p /etc/pingtunnel/
   sudo nano /etc/pingtunnel/pingtunnel-server1.conf
   ```

   Example content for `/etc/pingtunnel/pingtunnel-server1.conf`:

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

   > **Note:** Replace the values above with your actual server IP, desired client/server ports, and key. All variables must be set correctly for the service to work.

3. **Enable and start the service**:

   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable pingtunnel@server1.service
   sudo systemctl start pingtunnel@server1.service
   sudo systemctl status pingtunnel@server1.service
   ```

## Thanks for free JetBrains Open Source license

<img src="https://resources.jetbrains.com/storage/products/company/brand/logos/GoLand.png" height="200"/></a>


