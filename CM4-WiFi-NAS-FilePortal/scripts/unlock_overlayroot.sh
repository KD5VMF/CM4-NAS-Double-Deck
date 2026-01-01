#!/usr/bin/env bash
# unlock_overlayroot.sh
# Disable overlayroot so changes persist (installer/update mode), then reboot.
set -euo pipefail

BOOT="/boot/firmware"
CMDLINE="${BOOT}/cmdline.txt"

sudo mount -o remount,rw "$BOOT"

sudo cp -a "$CMDLINE" "${CMDLINE}.bak.$(date +%F_%H%M%S)"
if grep -q 'overlayroot=tmpfs:recurse=0' "$CMDLINE"; then
  sudo sed -i 's/overlayroot=tmpfs:recurse=0/overlayroot=disabled/' "$CMDLINE"
elif ! grep -q 'overlayroot=' "$CMDLINE"; then
  # append token
  sudo sed -i 's/$/ overlayroot=disabled/' "$CMDLINE"
fi

echo "Updated cmdline:"
cat "$CMDLINE"
echo
echo "Rebooting into UNLOCKED mode (persistent writes)..."
sudo reboot
