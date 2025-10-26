#!/usr/bin/env bash
set -euo pipefail
for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.list; do
  [ -e "$f" ] || continue
  sudo sed -ri 's/[[:space:]](stable|testing|trixie)[[:space:]]/ bookworm /g' "$f" || true
done
sudo tee /etc/apt/preferences.d/limit-to-bookworm >/dev/null <<'PINS'
Package: *
Pin: release n=bookworm
Pin-Priority: 700
Package: *
Pin: release n=bookworm-updates
Pin-Priority: 700
Package: *
Pin: release n=bookworm-security
Pin-Priority: 700
Package: *
Pin: release n=bookworm-backports
Pin-Priority: 650
Package: *
Pin: release a=testing
Pin-Priority: -10
Package: *
Pin: release n=trixie
Pin-Priority: -10
Package: *
Pin: release a=unstable
Pin-Priority: -10
PINS
echo 'APT::Default-Release "bookworm";' | sudo tee /etc/apt/apt.conf.d/99default-release >/dev/null
sudo tee /etc/apt/apt.conf.d/52unattended-upgrades-bookworm >/dev/null <<'UUA'
Unattended-Upgrade::Allowed-Origins {
  "${distro_id}:${distro_codename}";
  "${distro_id}:${distro_codename}-security";
  "Raspberry Pi Foundation:${distro_codename}";
  "Raspberry Pi Foundation:${distro_codename}-stable";
};
UUA
sudo apt-get update
echo "[OK] Bookworm lock applied."
