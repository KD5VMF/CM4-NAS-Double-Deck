#!/usr/bin/env bash
set -euo pipefail
sudo mkdir -p /etc/systemd/journald.conf.d
echo -e '[Journal]\nStorage=volatile\nSystemMaxUse=64M' | sudo tee /etc/systemd/journald.conf.d/volatile.conf >/dev/null
sudo systemctl restart systemd-journald
echo "[OK] Journald set to volatile."
