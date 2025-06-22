#!/bin/bash

set -e

PT_REPO="https://github.com/esrrhs/pingtunnel"
PT_RELEASES="$PT_REPO/releases/latest"
INSTALL_DIR="/usr/local/bin"
SERVICE_DIR="/etc/systemd/system"
CONF_DIR="/etc/pingtunnel"

# Function to print bold text
function print_bold() {
    echo -e "\033[1m$1\033[0m"
}

function detect_arch() {
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        echo "linux64"
    elif [[ "$ARCH" == "aarch64" ]]; then
        echo "linuxarm64"
    else
        echo "Unsupported architecture: $ARCH"
        exit 1
    fi
}

function install_tunnel() {
    echo "Detecting OS and architecture..."
    PT_ARCH=$(detect_arch)
    echo "Detected: $PT_ARCH"
    #ZIP_NAME="pingtunnel_linux_${PT_ARCH}.zip"
    ZIP_NAME="pingtunnel_linux_amd64.zip"
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"
    echo "Fetching latest release URL..."
    #DOWNLOAD_URL=$(curl -sL "$PT_RELEASES" | grep -oP "https://[^\"]*${PT_ARCH}\\.zip" | head -n1)
    DOWNLOAD_URL="https://github.com/esrrhs/pingtunnel/releases/download/2.8/pingtunnel_linux_amd64.zip"
    if [[ -z "$DOWNLOAD_URL" ]]; then
        echo "Could not find download URL for $PT_ARCH"
        exit 1
    fi
    echo "Downloading $DOWNLOAD_URL"
    curl -LO "$DOWNLOAD_URL"
    echo "Extracting to $INSTALL_DIR"
    sudo unzip -o "$ZIP_NAME" -d "$INSTALL_DIR"
    sudo chmod +x "$INSTALL_DIR/pingtunnel"
    cd -
    rm -rf "$TMP_DIR"
    echo "pingtunnel installed to $INSTALL_DIR"

    # Prompt for next step
    while true; do
        echo "Do you want to configure the server or client side now?"
        read -rp "Enter 'server', 'client', or 'n' to skip: " nextstep
        case "$nextstep" in
            server|Server)
                configure_server
                break
                ;;
            client|Client)
                configure_client
                break
                ;;
            n|N|no|No)
                break
                ;;
            *)
                echo "Please enter 'server', 'client', or 'n' to skip."
                ;;
        esac
    done
}

function prompt_key() {
    read -rp "Enter the tunnel key (must be identical on both server and client) [default: 123456]: " KEY
    if [[ -z "$KEY" ]]; then
        KEY=123456
    fi
    echo "$KEY"
}

function configure_server() {
    echo "Configuring server-side systemd service..."
    KEY=$(prompt_key)
    sudo tee "$SERVICE_DIR/pingtunnel.service" > /dev/null <<EOF
[Unit]
Description=PingTunnel Server
Documentation=$PT_REPO
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
Group=root
ExecStart=$INSTALL_DIR/pingtunnel -type server -key $KEY -tcp 1 -nolog 1
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
EOF

    echo "Reloading systemd, enabling and starting service..."
    sudo systemctl daemon-reload
    sudo systemctl enable pingtunnel.service
    sudo systemctl start pingtunnel.service
    echo "Server started. Check status with: sudo systemctl status pingtunnel.service"
}

function configure_client() {
    echo "Configuring client-side systemd service..."
    KEY=$(prompt_key)
    read -rp "Enter the server IP: " SERVER_IP
    read -rp "Enter the local client port to listen on [default: 1080]: " CLIENT_PORT
    if [[ -z "$CLIENT_PORT" ]]; then CLIENT_PORT=1080; fi
    read -rp "Enter the server port [default: 4455]: " SERVER_PORT
    if [[ -z "$SERVER_PORT" ]]; then SERVER_PORT=4455; fi
    read -rp "TCP mode? (1 for yes, 0 for no) [default: 1]: " TCP_MODE
    if [[ -z "$TCP_MODE" ]]; then TCP_MODE=1; fi
    read -rp "Suppress output? (NO_PRINT, 1 for yes, 0 for no) [default: 0]: " NO_PRINT
    if [[ -z "$NO_PRINT" ]]; then NO_PRINT=0; fi
    read -rp "Disable logging? (NO_LOG, 1 for yes, 0 for no) [default: 1]: " NO_LOG
    if [[ -z "$NO_LOG" ]]; then NO_LOG=1; fi
    read -rp "Any extra parameters? (leave blank for none): " EXTRA_PARAMS
    sudo tee "$SERVICE_DIR/pingtunnel@.service" > /dev/null <<EOF
[Unit]
Description=Pingtunnel Client Service (%i)
Documentation=$PT_REPO
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
Group=root
EnvironmentFile=$CONF_DIR/pingtunnel-%i.conf
ExecStart=$INSTALL_DIR/pingtunnel -type client -l :\${CLIENT_PORT} -s \${SERVER_IP} -t \${SERVER_IP}:\${SERVER_PORT} -tcp \${TCP_MODE} -key \${KEY} -noprint \${NO_PRINT} -nolog \${NO_LOG} \${EXTRA_PARAMS}
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
EOF

    echo "Creating config directory: $CONF_DIR"
    sudo mkdir -p "$CONF_DIR"
    CONF_FILE="$CONF_DIR/pingtunnel-server1.conf"
    sudo tee "$CONF_FILE" > /dev/null <<EOF
SERVER_IP=$SERVER_IP
CLIENT_PORT=$CLIENT_PORT
SERVER_PORT=$SERVER_PORT
KEY=$KEY
TCP_MODE=$TCP_MODE
NO_PRINT=$NO_PRINT
NO_LOG=$NO_LOG
EXTRA_PARAMS="$EXTRA_PARAMS"
EOF
    echo "Reloading systemd, enabling and starting client service..."
    sudo systemctl daemon-reload
    sudo systemctl enable pingtunnel@server1.service
    sudo systemctl start pingtunnel@server1.service
    echo "Client started. Check status with: sudo systemctl status pingtunnel@server1.service"
}

function main_menu() {
    clear
    print_bold "==============================="
    print_bold "        PINGTUNNEL         "
    print_bold "==============================="
    echo
    echo -e "\033[36m1)\033[0m Install pingtunnel"
    echo -e "\033[36m2)\033[0m Configure \033[32mserver-side\033[0m systemd service"
    echo -e "\033[36m3)\033[0m Configure \033[34mclient-side\033[0m systemd service"
    echo -e "\033[36mq)\033[0m Quit"
    echo
    read -rp $'\033[1mSelect an option:\033[0m ' opt
    case "$opt" in
        1)
            install_tunnel
            ;;
        2)
            configure_server
            ;;
        3)
            configure_client
            ;;
        q|Q)
            exit 0
            ;;
        *)
            echo -e "\033[31mInvalid option\033[0m"
            ;;
    esac
}

main_menu
# while true; do
#     main_menu
# done