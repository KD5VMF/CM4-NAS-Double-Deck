#!/usr/bin/env bash
set -euo pipefail
sudo raspi-config nonint do_overlayfs 1
echo "[OK] Overlay OFF (root writable). Rebooting…"
sudo reboot
