#!/bin/bash

# रूट यूजर चेक
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root!"
  exit 1
fi

echo "[*] Updating and installing tools..."
apt-get update -y
apt-get install -y python3 python3-pip screen curl net-tools

# प्रॉक्सी फाइल डाउनलोड करें
curl -s -o /usr/local/bin/proxy.py "https://raw.githubusercontent.com/shivamsahu09901-boop/Publicssh/main/proxy.py"
chmod +x /usr/local/bin/proxy.py

# पुरानी प्रॉक्सी किल करें (अगर चल रही हो)
pkill -f proxy.py

# बैकग्राउंड में प्रॉक्सी रन करें (पोर्ट 80 पर)
screen -dmS ws_proxy python3 /usr/local/bin/proxy.py 80

# Menu फाइल डाउनलोड करें
curl -s -o /usr/bin/menu "https://raw.githubusercontent.com/shivamsahu09901-boop/Publicssh/main/menu.sh"
chmod +x /usr/bin/menu

echo "=================================================="
echo "SUCCESS: Server is ready!"
echo "1. Proxy running on Port 80."
echo "2. SSH is safe on Port 22."
echo "Type 'menu' to open your Admin Panel."
echo "=================================================="
