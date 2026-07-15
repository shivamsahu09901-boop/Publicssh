#!/bin/bash

# यहाँ अपने गिटहब की डिटेल्स डाल देना ताकि स्क्रिप्ट आपकी रेपो से फाइल्स डाउनलोड कर सके
GITHUB_USER="shivamsahu09901-boop"
REPO_NAME="Publicssh"

# रूट यूजर चेक
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root!"
  exit 1
fi

clear
echo "=================================================="
echo "      STARTING ONE-CLICK WEBSOCKET INSTALLER      "
echo "=================================================="
sleep 2

# 1. पोर्ट 80 और 443 को साफ़ करना (Kill/Stop Existing Web Servers)
echo "[*] Cleaning ports 80 and 443..."
systemctl stop nginx apache2 lsws 2>/dev/null
systemctl disable nginx apache2 lsws 2>/dev/null
apt-get remove --purge -y nginx nginx-common apache2 apache2-utils 2>/dev/null
apt-get autoremove -y 2>/dev/null

# पोर्ट 80 और 443 पर चल रहे किसी भी प्रोसेस को जबरन बंद करना
fuser -k 80/tcp 2>/dev/null
fuser -k 443/tcp 2>/dev/null

# 2. सिस्टम अपडेट और जरूरी पैकेज इंस्टॉल करना
echo "[*] Installing dependencies..."
apt-get update -y
apt-get install -y python3 python3-pip screen dropbear curl fail2ban ufw

# 3. /bin/false को शेल लिस्ट में जोड़ना
grep -qxF '/bin/false' /etc/shells || echo '/bin/false' >> /etc/shells

# 4. डिफ़ॉल्ट OpenSSH को पोर्ट 22 से रोकना (ताकि Dropbear 22 पर चल सके)
echo "[*] Disabling default OpenSSH socket on Port 22..."
systemctl stop ssh.socket 2>/dev/null
systemctl disable ssh.socket 2>/dev/null
systemctl mask ssh.socket 2>/dev/null

# 5. Dropbear कॉन्फ़िगर करना
echo "[*] Configuring Dropbear SSH Server..."
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=22/g' /etc/default/dropbear
sed -i 's/DROPBEAR_BANNER=""/DROPBEAR_BANNER="\/etc\/issue.net"/g' /etc/default/dropbear

# Dropbear Override कॉन्फ़िगरेशन बनाना (फोर्स बैनर और पोर्ट 22)
mkdir -p /etc/systemd/system/dropbear.service.d
cat << 'EOF' > /etc/systemd/system/dropbear.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/sbin/dropbear -F -E -b /etc/issue.net -p 22
EOF

# डिफ़ॉल्ट बैनर बनाना
echo -e "WebSocket Tunneling Server\nSupport: @Apimakergast" > /etc/issue.net

systemctl daemon-reload
systemctl enable dropbear
systemctl restart dropbear

# 6. Python Websocket Proxy सेटअप करना
echo "[*] Downloading and starting Python Proxy..."
pkill -f proxy.py 2>/dev/null

# गिटहब से प्रॉक्सी डाउनलोड करना
curl -s -o /usr/local/bin/proxy.py "https://raw.githubusercontent.com/${GITHUB_USER}/${REPO_NAME}/main/proxy.py"
chmod +x /usr/local/bin/proxy.py

# बैकग्राउंड में स्क्रीन के अंदर प्रॉक्सी को रन करना (पोर्ट 80 पर)
screen -dmS ws_proxy python3 /usr/local/bin/proxy.py 80

# 7. SSH Management Panel (Menu) सेटअप करना
echo "[*] Installing SSH Panel..."
curl -s -o /usr/bin/menu "https://raw.githubusercontent.com/${GITHUB_USER}/${REPO_NAME}/main/menu.sh"
chmod +x /usr/bin/menu

clear
echo "=================================================="
echo "✔ INSTALLATION COMPLETED SUCCESSFULLY!"
echo "=================================================="
echo "• Dropbear running on: Port 22"
echo "• Python Proxy running on: Port 80"
echo ""
echo "👉 Type 'menu' in terminal to open the Admin Panel!"
echo "=================================================="
