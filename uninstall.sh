#!/bin/sh

echo "=========================================="
echo "   UNINSTALLER WEB HARDISK OPENWRT        "
echo "=========================================="
printf "Yakin ingin menghapus seluruh proyek Web Hardisk ini? (y/n): "
read -r JAWAB </dev/tty
case "$JAWAB" in
  y|Y) ;;
  *) echo "Dibatalkan."; exit 0 ;;
esac

DOMAIN=""
[ -f /etc/webssd.conf ] && . /etc/webssd.conf

echo "[1/3] Menghapus file aplikasi & auto-mount..."
rm -rf /www/webssd /www/cgi-bin/storage-api /etc/hotplug.d/block/99-usb-automount /etc/webssd.conf

echo "[2/3] Mengembalikan halaman awal LuCI..."
if [ -f /www/index.html.bak ]; then
  mv /www/index.html.bak /www/index.html
else
  printf '<!DOCTYPE html><html><head><meta http-equiv="refresh" content="0;url=/cgi-bin/luci/"></head></html>' > /www/index.html
fi

echo "[3/3] Menghapus domain lokal dari DNS..."
if [ -n "$DOMAIN" ]; then
  IDX=0
  while uci -q get dhcp.@domain[$IDX] >/dev/null; do
    NAME=$(uci -q get dhcp.@domain[$IDX].name)
    if [ "$NAME" = "$DOMAIN" ]; then
      uci delete dhcp.@domain[$IDX]
      continue
    fi
    IDX=$((IDX + 1))
  done
  uci commit dhcp
  /etc/init.d/dnsmasq restart
fi

echo ""
echo "Selesai! Semua file dan pengaturan Web Hardisk telah dihapus bersih."
