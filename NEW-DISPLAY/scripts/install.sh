#!/usr/bin/env bash
set -euo pipefail
if ! grep -qi 'bookworm' /etc/os-release; then
  echo "[ERROR] This dashboard is tested/supported on Debian/raspiOS BOOKWORM only."
  cat /etc/os-release
  exit 1
fi
APP_DIR="/opt/cm4lcd"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UNIT_SRC="$SRC_DIR/systemd/cm4lcd_pretty.service"
UNIT_DST="/etc/systemd/system/cm4lcd_pretty.service"
ENV_DST="/etc/default/cm4lcd_pretty"
USER_NAME="${SUDO_USER:-$USER}"
sudo apt-get update -y
sudo apt-get install -y python3 python3-pil python3-psutil python3-spidev python3-rpi.gpio gpiod fonts-dejavu
sudo mkdir -p "$APP_DIR"
sudo install -m 0755 "$SRC_DIR/src/pretty_dashboard.py" "$APP_DIR/pretty_dashboard.py"
sudo chown -R "$USER_NAME:$USER_NAME" "$APP_DIR"
if [ ! -f "$ENV_DST" ]; then
  sudo install -m 0644 "$SRC_DIR/config/cm4lcd_pretty.env.example" "$ENV_DST"
  echo "[INFO] Wrote default env to $ENV_DST"
fi
tmp_unit="$(mktemp)"
sed "s/__USER__/$USER_NAME/g" "$UNIT_SRC" > "$tmp_unit"
sudo install -m 0644 "$tmp_unit" "$UNIT_DST"
rm -f "$tmp_unit"
sudo systemctl daemon-reload
sudo systemctl disable --now cm4lcd.service 2>/dev/null || true
sudo systemctl enable --now cm4lcd_pretty.service
echo
echo "[OK] Installed."
echo "Edit env: sudo nano $ENV_DST"
echo "Restart:  sudo systemctl restart cm4lcd_pretty"
echo "Logs:     journalctl -u cm4lcd_pretty -n 80 --no-pager"
