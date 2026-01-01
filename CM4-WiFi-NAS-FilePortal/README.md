# CM4 Wi‑Fi NAS + Web File Portal (hostapd + dnsmasq + File Browser) — with “run from RAM” lock mode

This project turns a Raspberry Pi **Compute Module 4 NAS** (or any Pi with Wi‑Fi + Ethernet) into a **standalone Wi‑Fi access point** that serves:
- a **NAS share over the network you already have** (OMV/Samba/NFS etc. can keep working on `eth0`)
- a **web-based file portal** (File Browser) for uploads/downloads to your large drive
- optional **internet sharing** from `eth0` to AP clients (NAT)

It also includes an optional “**locked**” mode where the Pi boots read-only and runs from RAM using **overlayroot** (`overlayroot=tmpfs...`), exactly like the hardened setup we used.

---

## What you get

### Services (systemd)
- `cm4ap-net.service` — assigns a static IP to `wlan0`, enables forwarding, and optional NAT
- `hostapd.service` — runs the AP
- `dnsmasq.service` — DHCP/DNS for AP clients (bound to `wlan0` only)
- `filebrowser.service` — web file portal bound to `0.0.0.0:<PORT>`

### Defaults
- SSID: `CM4-AP`
- AP subnet: `10.42.0.0/24` (`wlan0` = `10.42.0.1`)
- DHCP: `10.42.0.50 - 10.42.0.200`
- File portal path: `/srv/nas/FilePortal` (you can change it)
- File portal port: `8081`

---

## REQUIREMENTS

- Debian Bookworm / Raspberry Pi OS Bookworm (or similar)
- Wi‑Fi interface `wlan0`
- Ethernet interface `eth0` (for LAN and/or internet uplink)
- Your big drive mounted somewhere (example we used: `/srv/nas`)
- You must run the installer while the root filesystem is **unlocked** (not overlayroot).

### Check if you are locked
```bash
findmnt -no FSTYPE,SOURCE,TARGET /
```
If it says `overlay`, you are locked. You need to unlock before installing.

---

## Quick install

### 1) Clone
```bash
git clone https://github.com/<you>/CM4-WiFi-NAS-FilePortal.git
cd CM4-WiFi-NAS-FilePortal
```

### 2) Unlock (only needed if you're currently locked)
```bash
sudo ./scripts/unlock_overlayroot.sh
# it reboots
```

### 3) Run installer (interactive)
```bash
sudo ./scripts/install_cm4_wifi_nas.sh
```

### 4) Re-lock (optional hardening)
```bash
sudo ./scripts/lock_overlayroot.sh
# it reboots
```

---

## How to access after install

### Connect to Wi‑Fi
Join SSID `CM4-AP` (or your chosen SSID). You’ll get an IP via DHCP.

### Web file portal
Open in your browser:
- `http://10.42.0.1:8081`

(You can also try `http://cm4ap.local:8081` if your client honors local DNS; otherwise use the IP.)

---

## Notes / Compatibility

### Does this break OMV networking?
No. This project:
- does **not** change `eth0` IP configuration
- runs DHCP/DNS only on `wlan0`
- does not modify OMV web ports (we default to `8081`)

### Overlayroot “locked mode”
When locked:
- system changes in `/etc`, `/usr`, etc. do **not** persist across reboot
- your NAS mount (e.g. `/srv/nas`) still persists (it’s on your large drive)

---

## Files in this repo

- `scripts/install_cm4_wifi_nas.sh` — main installer
- `scripts/lock_overlayroot.sh` / `scripts/unlock_overlayroot.sh` — toggle “run from RAM”
- `configs/hostapd.conf.template` — AP config template
- `configs/dnsmasq_cm4ap.conf` — dnsmasq config
- `configs/filebrowser_defaults.env` — default settings
- `systemd/*.service` — unit files
- `scripts/cm4ap-net.sh` — runtime network prep helper
- `docs/SECURITY.md` — suggestions
- `LICENSE` — MIT

---

## License
MIT — see `LICENSE`.
