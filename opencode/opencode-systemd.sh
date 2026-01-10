#!/bin/bash

ACTION="${1:-start}"

OPENCODE_BIN=$(which opencode 2>/dev/null)
if [ -z "$OPENCODE_BIN" ]; then
    echo "Error: opencode binary not found in PATH"
    exit 1
fi

SERVICE_USER="${SUDO_USER:-$(whoami)}"
SERVICE_NAME="opencode-serve"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
SERVICE_CONTENT="[Unit]
Description=OpenCode Serve with mDNS
After=network.target

[Service]
ExecStart=$OPENCODE_BIN serve --mdns --port 4096
Restart=always
RestartSec=10
User=$SERVICE_USER

[Install]
WantedBy=multi-user.target"

if [ "$EUID" -ne 0 ]; then
    echo "This script requires root privileges. Running with sudo..."
    exec sudo bash "$0" "$@"
fi

if [ "$ACTION" = "stop" ]; then
    systemctl stop "$SERVICE_NAME"
    systemctl disable "$SERVICE_NAME"
    rm -f "$SERVICE_FILE"
    systemctl daemon-reload
    echo "OpenCode serve service removed"
else
    echo "$SERVICE_CONTENT" > "$SERVICE_FILE"
    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
    systemctl start "$SERVICE_NAME"
    echo "OpenCode serve service installed and started with mDNS support"
fi
