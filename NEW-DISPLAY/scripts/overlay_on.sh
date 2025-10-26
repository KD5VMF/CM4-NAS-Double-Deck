#!/usr/bin/env bash
set -euo pipefail
sudo raspi-config nonint do_overlayfs 0
sudo sed -i 's/overlayroot=tmpfs/overlayroot=tmpfs:recurse=0/' /boot/firmware/cmdline.txt || true
echo "[OK] Overlay ON (root in RAM). Rebooting…"
sudo reboot
