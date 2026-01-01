#!/usr/bin/env bash
# ==============================================================================
#  install_cm4_wifi_nas.sh
#
#  CM4 Wi‑Fi AP + Web File Portal installer
#
#  - hostapd (AP)
#  - dnsmasq (DHCP/DNS for AP clients)
#  - filebrowser (web file portal)
#  - cm4ap-net service (wlan0 static + optional NAT via nftables)
#
#  IMPORTANT:
#    Run this while the system is UNLOCKED (root filesystem is ext4, not overlay).
#    Check:
#      findmnt -no FSTYPE,SOURCE,TARGET /
#    If it shows "overlay", run scripts/unlock_overlayroot.sh first.
# ==============================================================================

set -euo pipefail

banner() {
  echo "============================================================"
  echo " CM4-AP Wi‑Fi NAS + Web File Portal Setup"
  echo "============================================================"
}

need_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "Please run as root:"
    echo "  sudo $0"
    exit 1
  fi
}

ensure_unlocked() {
  local fstype
  fstype="$(findmnt -no FSTYPE / || true)"
  if [[ "$fstype" == "overlay" ]]; then
    echo
    echo "[ERROR] You are currently in LOCKED overlayroot mode."
    echo "Unlock first so changes persist:"
    echo "  sudo ./scripts/unlock_overlayroot.sh"
    exit 1
  fi
}

prompt_default() {
  local prompt="$1" default="$2" var
  read -r -p "${prompt} [${default}]: " var
  if [[ -z "$var" ]]; then var="$default"; fi
  echo "$var"
}

prompt_secret() {
  local prompt="$1" var
  while true; do
    read -r -s -p "$prompt: " var; echo
    if [[ -n "$var" ]]; then
      echo "$var"
      return 0
    fi
  done
}

validate_passphrase() {
  local p="$1"
  local n=${#p}
  if (( n < 8 || n > 63 )); then
    echo "[ERROR] WPA2 passphrase must be 8..63 characters." >&2
    return 1
  fi
}

validate_port() {
  local p="$1"
  [[ "$p" =~ ^[0-9]+$ ]] || return 1
  (( p >= 1024 && p <= 65535 )) || return 1
}

apt_update_safe() {
  # Work around "Suite changed stable->oldstable" etc.
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y --allow-releaseinfo-change || apt-get update -y --allow-releaseinfo-change-suite || apt-get update -y
}

install_packages() {
  echo "[1/7] Installing packages..."
  apt_update_safe
  apt-get install -y hostapd dnsmasq nftables curl ca-certificates
  systemctl unmask hostapd >/dev/null 2>&1 || true
}

install_filebrowser() {
  echo "[2/7] Installing File Browser..."
  if command -v filebrowser >/dev/null 2>&1; then
    echo "filebrowser already installed: $(command -v filebrowser)"
    return 0
  fi
  curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
}

render_hostapd() {
  echo "[3/7] Configuring hostapd..."
  mkdir -p /etc/hostapd

  local tmpl="./configs/hostapd.conf.template"
  local out="/etc/hostapd/hostapd.conf"

  sed \
    -e "s/{{SSID}}/${SSID//\//\\/}/g" \
    -e "s/{{PASSPHRASE}}/${PASSPHRASE//\//\\/}/g" \
    -e "s/{{COUNTRY}}/${COUNTRY//\//\\/}/g" \
    -e "s/{{CHANNEL}}/${CHANNEL//\//\\/}/g" \
    "$tmpl" > "$out"

  chmod 600 "$out"
}

configure_dnsmasq() {
  echo "[4/7] Configuring dnsmasq..."
  mkdir -p /etc/dnsmasq.d
  cp -a ./configs/dnsmasq_cm4ap.conf /etc/dnsmasq.d/cm4ap.conf

  # Patch IPs to match chosen settings
  sed -i "s/10\.42\.0\.50/${DHCP_START//./\\.}/" /etc/dnsmasq.d/cm4ap.conf
  sed -i "s/10\.42\.0\.200/${DHCP_END//./\\.}/" /etc/dnsmasq.d/cm4ap.conf
  sed -i "s/10\.42\.0\.1/${AP_IP//./\\.}/g" /etc/dnsmasq.d/cm4ap.conf
}

install_cm4ap_env() {
  echo "[5/7] Writing CM4-AP environment..."
  mkdir -p /etc/cm4ap
  cat > /etc/cm4ap/cm4ap.env <<EOF
# CM4-AP runtime settings
WLAN_IF=wlan0
ETH_IF=eth0
AP_IP=${AP_IP}
AP_CIDR=${AP_CIDR}
ENABLE_NAT=${ENABLE_NAT}
EOF
  chmod 600 /etc/cm4ap/cm4ap.env

  cat > /etc/cm4ap/filebrowser.env <<EOF
PORT=${FB_PORT}
ROOT=${FB_ROOT}
DB=/etc/filebrowser/filebrowser.db
EOF
  chmod 600 /etc/cm4ap/filebrowser.env
}

setup_portal_folder() {
  echo
  echo "Your NAS volume is mounted at: ${NAS_MOUNT}"
  echo "[*] Creating/ensuring portal folder: ${FB_ROOT}"

  mkdir -p "$FB_ROOT"
  chown -R "$SUDO_USER":"$SUDO_USER" "$FB_ROOT" 2>/dev/null || true
  chmod 775 "$FB_ROOT"
}

configure_filebrowser_db() {
  echo "[6/7] Configuring File Browser..."
  mkdir -p /etc/filebrowser
  filebrowser -d /etc/filebrowser/filebrowser.db config init >/dev/null 2>&1 || true

  # baseURL flag changed in newer versions. Detect what this binary supports.
  if filebrowser config set --help 2>&1 | grep -q -- '--baseURL'; then
    filebrowser -d /etc/filebrowser/filebrowser.db config set \
      --address 0.0.0.0 --port "$FB_PORT" --root "$FB_ROOT" --baseURL "" >/dev/null
  else
    filebrowser -d /etc/filebrowser/filebrowser.db config set \
      --address 0.0.0.0 --port "$FB_PORT" --root "$FB_ROOT" >/dev/null
  fi

  # Password flag changed too. Detect supported syntax.
  local user_help
  user_help="$(filebrowser users add --help 2>&1 || true)"

  if echo "$user_help" | grep -q -- '--password'; then
    # Newer syntax
    filebrowser -d /etc/filebrowser/filebrowser.db users add "$FB_USER" --password "$FB_PASS" --perm.admin >/dev/null 2>&1 || \
    filebrowser -d /etc/filebrowser/filebrowser.db users update "$FB_USER" --password "$FB_PASS" --perm.admin >/dev/null
  elif echo "$user_help" | grep -q -- ' -p'; then
    # Older syntax
    filebrowser -d /etc/filebrowser/filebrowser.db users add "$FB_USER" -p "$FB_PASS" --perm.admin >/dev/null 2>&1 || \
    filebrowser -d /etc/filebrowser/filebrowser.db users update "$FB_USER" -p "$FB_PASS" --perm.admin >/dev/null
  else
    # Fallback: create without password, then ask user to set it in the UI
    filebrowser -d /etc/filebrowser/filebrowser.db users add "$FB_USER" --perm.admin >/dev/null 2>&1 || true
    echo "[WARN] Could not detect a CLI password flag for filebrowser."
    echo "       Set the password in the File Browser UI after first login."
  fi
}

install_systemd_units() {
  echo "[7/7] Installing systemd units..."

  # helper script
  install -m 0755 ./scripts/cm4ap-net.sh /usr/local/sbin/cm4ap-net.sh

  # services
  install -m 0644 ./systemd/cm4ap-net.service /etc/systemd/system/cm4ap-net.service
  install -m 0644 ./systemd/filebrowser.service /etc/systemd/system/filebrowser.service

  # hostapd override
  mkdir -p /etc/systemd/system/hostapd.service.d
  install -m 0644 ./systemd/hostapd.override.conf /etc/systemd/system/hostapd.service.d/override.conf

  # dnsmasq override
  mkdir -p /etc/systemd/system/dnsmasq.service.d
  install -m 0644 ./systemd/dnsmasq.override.conf /etc/systemd/system/dnsmasq.service.d/override.conf

  systemctl daemon-reload

  # enable services
  systemctl enable cm4ap-net.service
  systemctl enable hostapd.service
  systemctl enable dnsmasq.service
  systemctl enable filebrowser.service
}

restart_services() {
  echo
  echo "[*] Restarting services..."
  systemctl restart cm4ap-net.service
  systemctl restart dnsmasq.service
  systemctl restart hostapd.service
  systemctl restart filebrowser.service
}

print_done() {
  echo
  echo "============================================================"
  echo " DONE!"
  echo "============================================================"
  echo "AP SSID:        ${SSID}"
  echo "AP subnet:      ${AP_IP}/${AP_CIDR}"
  echo "DHCP range:     ${DHCP_START} - ${DHCP_END}"
  echo "NAT enabled:    ${ENABLE_NAT}"
  echo
  echo "Web portal:"
  echo "  http://${AP_IP}:${FB_PORT}"
  echo "Root folder:"
  echo "  ${FB_ROOT}"
  echo
  echo "Check status:"
  echo "  systemctl status cm4ap-net hostapd dnsmasq filebrowser --no-pager"
  echo
  echo "If you want to 'lock' (run from RAM), do:"
  echo "  sudo ./scripts/lock_overlayroot.sh"
  echo
}

main() {
  banner
  need_root
  ensure_unlocked

  SSID="$(prompt_default 'Enter Wi-Fi AP SSID' 'CM4-AP')"
  PASSPHRASE="$(prompt_secret 'Enter Wi-Fi AP passphrase (8..63 chars)')"
  validate_passphrase "$PASSPHRASE"

  COUNTRY="$(prompt_default 'Wi-Fi country code' 'US')"
  CHANNEL="$(prompt_default 'Wi-Fi channel (2.4GHz typical: 1,6,11)' '6')"

  AP_IP="$(prompt_default 'AP gateway IP (clients connect to this)' '10.42.0.1')"
  AP_CIDR="$(prompt_default 'AP subnet CIDR' '24')"
  DHCP_START="$(prompt_default 'DHCP range start' '10.42.0.50')"
  DHCP_END="$(prompt_default 'DHCP range end' '10.42.0.200')"
  ENABLE_NAT="$(prompt_default 'Enable NAT so AP clients can reach the internet via eth0? (yes/no)' 'yes')"
  [[ "$ENABLE_NAT" == "yes" || "$ENABLE_NAT" == "no" ]] || ENABLE_NAT="yes"

  echo
  echo "Now configure the web file portal (File Browser)."

  # Try to discover a likely NAS mount automatically; allow override
  local default_mount="/srv/nas"
  if mountpoint -q /srv/nas; then default_mount="/srv/nas"; fi
  NAS_MOUNT="$(prompt_default 'Enter your large-drive mount path' "$default_mount")"

  local default_root="${NAS_MOUNT%/}/FilePortal"
  FB_ROOT="$(prompt_default 'Enter the folder to expose in the web portal' "$default_root")"

  FB_PORT="$(prompt_default 'Web portal port (avoid OMV 80/443)' '8081')"
  if ! validate_port "$FB_PORT"; then
    echo "[ERROR] Port must be 1024..65535"
    exit 1
  fi

  FB_USER="$(prompt_default 'Web portal admin username' "${SUDO_USER:-admin}")"
  FB_PASS="$(prompt_secret 'Web portal admin password (min 8 chars)')"

  install_packages
  install_filebrowser
  render_hostapd
  configure_dnsmasq
  install_cm4ap_env
  setup_portal_folder
  configure_filebrowser_db
  install_systemd_units
  restart_services
  print_done
}

main "$@"
