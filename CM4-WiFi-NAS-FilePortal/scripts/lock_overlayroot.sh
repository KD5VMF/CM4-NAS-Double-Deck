#!/usr/bin/env bash
# lock_overlayroot.sh
# Enable overlayroot (run from RAM), then reboot.
set -euo pipefail

BOOT="/boot/firmware"
CMDLINE="${BOOT}/cmdline.txt"

sudo mount -o remount,rw "$BOOT"

sudo cp -a "$CMDLINE" "${CMDLINE}.bak.$(date +%F_%H%M%S)"
if grep -q 'overlayroot=disabled' "$CMDLINE"; then
  sudo sed -i 's/overlayroot=disabled/overlayroot=tmpfs:recurse=0/' "$CMDLINE"
elif ! grep -q 'overlayroot=' "$CMDLINE"; then
  sudo sed -i 's/$/ overlayroot=tmpfs:recurse=0/' "$CMDLINE"
fi

echo "Updated cmdline:"
cat "$CMDLINE"
echo
echo "Rebooting into LOCKED mode (overlayroot tmpfs)..."
sudo reboot
