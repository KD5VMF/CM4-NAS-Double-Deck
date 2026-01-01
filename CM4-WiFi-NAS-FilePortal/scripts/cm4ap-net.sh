#!/usr/bin/env bash
# cm4ap-net.sh
# Assign static IP to wlan0 and enable forwarding (and optional NAT)
set -euo pipefail

CFG="/etc/cm4ap/cm4ap.env"
if [[ ! -f "$CFG" ]]; then
  echo "Missing $CFG"
  exit 1
fi

# shellcheck disable=SC1090
source "$CFG"

WLAN_IF="${WLAN_IF:-wlan0}"
ETH_IF="${ETH_IF:-eth0}"
AP_IP="${AP_IP:-10.42.0.1}"
AP_CIDR="${AP_CIDR:-24}"
ENABLE_NAT="${ENABLE_NAT:-yes}"

# Bring wlan up
ip link set "$WLAN_IF" up || true

# Flush any stray IPv4 addr and set ours
ip -4 addr flush dev "$WLAN_IF" || true
ip -4 addr add "${AP_IP}/${AP_CIDR}" dev "$WLAN_IF"

# Enable IPv4 forwarding
sysctl -w net.ipv4.ip_forward=1 >/dev/null
sysctl -w net.ipv4.conf.all.forwarding=1 >/dev/null

# NAT (nftables) so AP clients can reach internet via eth0
# If your eth0 is only LAN (no internet), NAT doesn't hurt, but you can disable it.
if [[ "$ENABLE_NAT" == "yes" ]]; then
  if ! command -v nft >/dev/null 2>&1; then
    echo "nft not found; install nftables"
    exit 1
  fi

  # Create a minimal nft ruleset (idempotent)
  nft list table ip cm4ap >/dev/null 2>&1 || nft add table ip cm4ap

  # chains
  nft list chain ip cm4ap forward >/dev/null 2>&1 || nft add chain ip cm4ap forward '{ type filter hook forward priority 0 ; policy accept ; }'
  nft list chain ip cm4ap postrouting >/dev/null 2>&1 || nft add chain ip cm4ap postrouting '{ type nat hook postrouting priority 100 ; }'

  # rules (avoid duplicates)
  nft list chain ip cm4ap forward | grep -q "iifname \\\"$WLAN_IF\\\" oifname \\\"$ETH_IF\\\" accept" || \
    nft add rule ip cm4ap forward iifname "$WLAN_IF" oifname "$ETH_IF" accept

  nft list chain ip cm4ap forward | grep -q "iifname \\\"$ETH_IF\\\" oifname \\\"$WLAN_IF\\\" ct state established,related accept" || \
    nft add rule ip cm4ap forward iifname "$ETH_IF" oifname "$WLAN_IF" ct state established,related accept

  nft list chain ip cm4ap postrouting | grep -q "oifname \\\"$ETH_IF\\\" masquerade" || \
    nft add rule ip cm4ap postrouting oifname "$ETH_IF" masquerade

  # ensure nftables service persists
  systemctl enable --now nftables >/dev/null 2>&1 || true
fi

exit 0
