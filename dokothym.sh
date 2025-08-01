#!/bin/bash

GREEN='\033[0;32m'
NC='\033[0m' # No Color

function banner() {
  echo -e "${GREEN}"
  echo "╔═══════════════════════════════╗"
  echo "║         DokoThym Script       ║"
  echo "║       By @amirhtym (Telegram) ║"
  echo "╚═══════════════════════════════╝"
  echo -e "${NC}"
}

function install_xray() {
  echo "[*] Installing Xray..."
  # نصب Xray...
  sudo bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
}

function create_config() {
  read -p "How many ports do you need for the tunnel? " PORT_COUNT
  # چند پورت برای تونل نیاز دارید؟
  PORTS=()
  for ((i=1; i<=PORT_COUNT; i++)); do
    read -p "Enter port number $i: " port
    # پورت شماره $i
    PORTS+=($port)
  done

  read -p "Enter destination IP: " DEST_IP
  # IP مقصد را وارد کنید

  CONFIG_PATH="/usr/local/etc/xray/config.json"
  echo "[*] Creating config.json at $CONFIG_PATH"

  cat > $CONFIG_PATH <<EOF
{
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 62789,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "127.0.0.1"
      },
      "tag": "api"
    },
EOF

  for ((i=0; i<${#PORTS[@]}; i++)); do
    port=${PORTS[$i]}
    comma=","
    if [[ $i == $((${#PORTS[@]} - 1)) ]]; then
      comma=""
    fi

    cat >> $CONFIG_PATH <<EOF
    {
      "listen": null,
      "port": $port,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "$DEST_IP",
        "followRedirect": false,
        "network": "tcp,udp",
        "port": $port
      },
      "tag": "inbound-$port"
    }$comma
EOF
  done

  cat >> $CONFIG_PATH <<EOF
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    },
    {
      "protocol": "blackhole",
      "tag": "blocked"
    }
  ]
}
EOF

  echo "[*] Restarting Xray..."
  # ریستارت Xray...
  sudo systemctl restart xray
  echo -e "[✓] Configuration applied and Xray restarted.\n"
}

function remove_tunnel() {
  echo "[*] Removing tunnel config file..."
  # حذف فایل کانفیگ تونل...
  sudo rm -f /usr/local/etc/xray/config.json
  echo "[*] Stopping and disabling Xray service..."
  # توقف و غیرفعال کردن سرویس Xray...
  sudo systemctl stop xray
  sudo systemctl disable xray
  echo "[✓] Tunnel config removed."
}

function remove_all() {
  echo "[*] Removing Xray and configuration completely..."
  # حذف کامل Xray و کانفیگ...
  sudo rm -f /usr/local/etc/xray/config.json
  sudo systemctl stop xray
  sudo systemctl disable xray
  sudo bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove
  echo "[✓] Full removal complete."
}

function menu() {
  banner
  echo "DokoThym Tunnel Script"
  echo "1) Install and Setup Tunnel"       # نصب و راه‌اندازی تانل
  echo "2) Remove Tunnel Config Only"      # حذف کانفیگ تانل
  echo "3) Uninstall Completely"           # حذف کامل
  echo "4) Exit"                           # خروج
  echo ""

  read -p "Choose an option: " CHOICE
  case $CHOICE in
    1)
      install_xray
      create_config
      ;;
    2) remove_tunnel ;;
    3) remove_all ;;
    4) exit 0 ;;
    *) echo "Invalid option." ;;           # گزینه نامعتبر
  esac
}

while true; do
  menu
done
