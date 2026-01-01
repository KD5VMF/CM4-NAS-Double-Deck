# Quickstart (copy/paste)

## 1) Get into the repo folder
```bash
cd ~
git clone https://github.com/<you>/CM4-WiFi-NAS-FilePortal.git
cd CM4-WiFi-NAS-FilePortal
```

## 2) If you're currently locked (overlayroot)
```bash
findmnt -no FSTYPE,SOURCE,TARGET /
# if overlay -> unlock:
sudo ./scripts/unlock_overlayroot.sh
```

## 3) Install
```bash
sudo ./scripts/install_cm4_wifi_nas.sh
```

## 4) Verify
```bash
systemctl status cm4ap-net hostapd dnsmasq filebrowser --no-pager
ip -4 addr show wlan0
sudo iw dev wlan0 info
sudo ss -tulpn | egrep ':8081|:67|:53' || true
```

## 5) Optional lock
```bash
sudo ./scripts/lock_overlayroot.sh
```
