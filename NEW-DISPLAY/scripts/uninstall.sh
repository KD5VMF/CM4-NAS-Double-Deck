#!/usr/bin/env bash
set -euo pipefail
UNIT="/etc/systemd/system/cm4lcd_pretty.service"
APP_DIR="/opt/cm4lcd"
sudo systemctl disable --now cm4lcd_pretty.service 2>/dev/null || true
sudo rm -f "$UNIT"
sudo systemctl daemon-reload
echo "[OK] Service removed."
read -r -p "Delete app dir $APP_DIR? [y/N] " ans
if [[ "${ans:-N}" =~ ^[Yy]$ ]]; then
  sudo rm -rf "$APP_DIR"
  echo "[OK] Removed $APP_DIR"
fi
