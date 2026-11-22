#!/bin/sh

BASE_URL="https://raw.githubusercontent.com/ASHTERSAI/Web-Hardisk-SSD/main"

echo "=========================================="
echo "   INSTALLER WEB HARDISK OPENWRT (WEBSSD) "
echo "=========================================="
echo ""

printf "Masukkan alamat web hardisk anda (contoh : gantengmanis.com)\n"
printf "Halaman ini tidak harus beli domain, ketik apapun .com pasti bisa diakses: "
read -r DOMAIN </dev/tty
DOMAIN=$(printf '%s' "$DOMAIN" | tr 'A-Z' 'a-z' | sed 's|https\?://||g; s|/.*||g; s/ //g')
[ -z "$DOMAIN" ] && DOMAIN="webhardisk.com"

echo ""
printf "Masukkan PIN web hardisk (contoh : 123456): "
read -r PIN </dev/tty
[ -z "$PIN" ] && PIN="123456"

echo ""
echo "[1/4] Mengunduh file dari GitHub..."
mkdir -p /www/webssd /www/cgi-bin /etc/hotplug.d/block

dl() {
  if command -v wget >/dev/null 2>&1; then
    wget -qO "$2" "$1"
  else
    curl -fsSL -o "$2" "$1"
  fi
}

dl "$BASE_URL/index.html" "/www/webssd/index.html" || { echo "Gagal download index.html"; exit 1; }
dl "$BASE_URL/storage-api" "/www/cgi-bin/storage-api" || { echo "Gagal download storage-api"; exit 1; }
dl "$BASE_URL/99-usb-automount" "/etc/hotplug.d/block/99-usb-automount" || { echo "Gagal download auto-mount"; exit 1; }

chmod +x /www/cgi-bin/storage-api /etc/hotplug.d/block/99-usb-automount

echo "[2/4] Menerapkan PIN..."
sed -i "s|^APP_PIN=.*|APP_PIN=\"$PIN\"|" /www/cgi-bin/storage-api

echo "[3/4] Mengatur halaman utama untuk domain $DOMAIN..."
[ ! -f /www/index.html.bak ] && [ -f /www/index.html ] && cp /www/index.html /www/index.html.bak
cp /www/webssd/index.html /www/index.html
sed -i "s|<head>|<head><script>if(location.hostname!==\"$DOMAIN\"\&\&location.hostname!==\"www.$DOMAIN\"){location.replace(\"/cgi-bin/luci/\");}</script>|" /www/index.html

echo "[4/4] Mengatur DNS lokal OpenWrt..."
LAN_IP=$(uci get network.lan.ipaddr 2>/dev/null || echo "192.168.1.1")
uci add dhcp domain >/dev/null
uci set dhcp.@domain[-1].name="$DOMAIN"
uci set dhcp.@domain[-1].ip="$LAN_IP"
uci commit dhcp
/etc/init.d/dnsmasq restart

echo "DOMAIN=$DOMAIN" > /etc/webssd.conf

echo ""
echo "=========================================="
echo " INSTALASI SELESAI!"
echo " Alamat Web : http://$DOMAIN"
echo " Alamat IP  : http://$LAN_IP/webssd"
echo " PIN Anda   : $PIN"
echo "=========================================="
