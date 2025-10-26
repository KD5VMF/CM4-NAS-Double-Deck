# CM4-NAS-Double-Deck — NEW-DISPLAY (Bookworm)

> **Tested & supported on Raspberry Pi OS (Debian 12) — Bookworm.**  
> This project provides a modern, flicker-free **LCD dashboard** for the Waveshare CM4-NAS-Double-Deck, plus **Bookworm lock** (no accidental release upgrade) and an **OS-in-RAM overlay** to protect against power loss. It also includes an optional backup of the **original Waveshare demo**.

---

## Table of Contents

- [What You Get](#what-you-get)
- [Hardware & OS Prereqs](#hardware--os-prereqs)
- [Quick Start (Recommended Dashboard)](#quick-start-recommended-dashboard)
- [Configuration File](#configuration-file)
- [Service Management](#service-management)
- [System Hardening (Lock to Bookworm + OS in RAM)](#system-hardening-lock-to-bookworm--os-in-ram)
- [RAID1 Setup for /srv/nas (Optional)](#raid1-setup-for-srvnas-optional)
- [Original Waveshare LCD Demo (Optional Backup)](#original-waveshare-lcd-demo-optional-backup)
- [Enable Interfaces (SPI / USB / I2C / RTC)](#enable-interfaces-spi--usb--i2c--rtc)
- [Networking (LAN & Wi-Fi)](#networking-lan--wi-fi)
- [OpenMediaVault (Optional NAS GUI)](#openmediavault-optional-nas-gui)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Contributing](#contributing)
- [License & Credits](#license--credits)

---

## What You Get

**Folder structure (inside this repo):**

```
CM4-NAS-Double-Deck/
└─ NEW-DISPLAY/
   ├─ src/pretty_dashboard.py
   ├─ systemd/cm4lcd_pretty.service
   ├─ config/cm4lcd_pretty.env.example
   ├─ scripts/
   │  ├─ install.sh
   │  ├─ uninstall.sh
   │  ├─ test_foreground.sh
   │  ├─ lock_bookworm.sh
   │  ├─ overlay_on.sh
   │  ├─ overlay_off.sh
   │  └─ harden_logging.sh
   ├─ README.md  ← (this file)
   └─ LICENSE
```

**Highlights:**
- **Large, clean LCD UI:** NAS usage (Used/Free), big percent, CPU/RAM bars, temp, uptime, RAID status, live net I/O.
- **Colors:** Title blue, IP red, Date/Time green; NAS label & dev@mount red; Used/Free labels blue + values white.
- **Rotation & layout tweaks** via env (no code edits).
- **Backlight forced solid** (no PWM flicker).
- **Bookworm lock** (safe updates; no release jump).
- **Overlay root (OS in RAM)** with `/srv/nas` kept read/write.

---

## Hardware & OS Prereqs

- Waveshare **CM4-NAS-Double-Deck** enclosure + **Raspberry Pi CM4**
- Waveshare **2-inch SPI LCD** (library path must include `lib/LCD_2inch.py`)
- Raspberry Pi OS **Bookworm (Debian 12)** — Lite recommended
- (Optional) Two SSDs for RAID1 at `/srv/nas`

> This project is tailored to **Bookworm**. Other releases are **not supported**.

---

## Quick Start (Recommended Dashboard)

### 0) Enable SPI
```bash
sudo raspi-config nonint do_spi 0   # 0 = enable
```

### 1) Clone + Install
```bash
git clone https://github.com/KD5VMF/CM4-NAS-Double-Deck.git
cd CM4-NAS-Double-Deck/NEW-DISPLAY/scripts
sudo ./install.sh
```

The installer:
- Installs Python deps (Pillow, psutil, spidev, etc.).
- Copies the app to `/opt/cm4lcd/pretty_dashboard.py`.
- Installs the systemd unit `cm4lcd_pretty.service`.
- Enables **auto-start on boot**.

### 2) Configure
Edit `/etc/default/cm4lcd_pretty`:
```ini
NAS_MOUNT=/srv/nas              # where your RAID/NAS is mounted
LCD_ROTATE=90                   # 0/90/180/270 (use 90 if the screen appears upside down)
LCD_TITLE=CM4-NAS               # header title

# Path to Waveshare demo root that contains: lib/LCD_2inch.py
# Example if you downloaded the demo:
LCD_LIB_DIR=/home/sysop/CM4-NAS-Double-Deck_Demo/RaspberryPi
# (Any path whose subfolder has lib/LCD_2inch.py will do)

# Optional look/feel
CPU_Y_SHIFT=1                   # vertical nudge for CPU/RAM/Temp/Uptime/RAID/Net
LCD_BL_PIN=18                   # backlight pin (BCM)
```

### 3) Start / Verify
```bash
sudo systemctl restart cm4lcd_pretty
journalctl -u cm4lcd_pretty -n 80 --no-pager
```
- To run in foreground (debug): `NEW-DISPLAY/scripts/test_foreground.sh`
- To stop/start manually: `sudo systemctl [stop|start] cm4lcd_pretty`

---

## Configuration File

`/etc/default/cm4lcd_pretty` is **persistent** across updates/reboots.

| Key          | Meaning                                                     | Default    |
|--------------|-------------------------------------------------------------|------------|
| `NAS_MOUNT`  | Path displayed as NAS (e.g., `/srv/nas`)                    | `/srv/nas` |
| `LCD_ROTATE` | Rotation: `0`, `90`, `180`, `270`                           | `90`       |
| `LCD_TITLE`  | Title text (top-left)                                       | `CM4-NAS`  |
| `LCD_LIB_DIR`| Folder that contains `lib/LCD_2inch.py` (Waveshare lib)     | *required* |
| `CPU_Y_SHIFT`| Move CPU/RAM/Temp/Uptime/RAID/Net block by N pixels (±)     | `1`        |
| `LCD_BL_PIN` | BCM pin for backlight (forced ON to prevent flicker)        | `18`       |

> If the LCD library isn’t found, the dashboard won’t start. Ensure `LCD_LIB_DIR` points to a directory whose **subfolder** is `lib/LCD_2inch.py`.

---

## Service Management

```bash
# Status
systemctl status cm4lcd_pretty --no-pager

# Restart after changing /etc/default/cm4lcd_pretty
sudo systemctl restart cm4lcd_pretty

# Enable on boot (installer already did this)
sudo systemctl enable cm4lcd_pretty

# Stop/Start
sudo systemctl stop cm4lcd_pretty
sudo systemctl start cm4lcd_pretty

# Logs
journalctl -u cm4lcd_pretty -n 120 --no-pager
```

---

## System Hardening (Lock to Bookworm + OS in RAM)

Keep the OS on **Bookworm** (safe updates, no accidental release upgrade) and run the root filesystem **from RAM** to protect against power loss. Scripts live in `NEW-DISPLAY/scripts/`.

### A) Lock to Bookworm (updates OK, no release jump)
```bash
cd ~/CM4-NAS-Double-Deck/NEW-DISPLAY
sudo ./scripts/lock_bookworm.sh
apt-cache policy | grep -E 'release|Version table' -A2
```
You should only see `n=bookworm`, `bookworm-updates`, and `bookworm-security` (no testing/trixie/unstable).

### B) Run the OS from RAM (overlay), keep `/srv/nas` writable
```bash
sudo ./scripts/overlay_on.sh   # reboots
# After reboot, verify:
grep -o 'overlayroot=[^ ]*' /proc/cmdline
mount | grep -E ' on / |/srv/nas'
```
> We append `:recurse=0` so **only** `/` is overlaid — your RAID/NAS at `/srv/nas` remains **read/write**.

### C) Maintenance Mode (when *you* want to update)
Because overlay routes writes to RAM, deliberately toggle OFF to do updates:
```bash
sudo ./scripts/overlay_off.sh  # reboots to writable root
# Then:
sudo apt update && sudo apt full-upgrade -y
# Re-enable protection afterward:
sudo ./scripts/overlay_on.sh   # reboots
```

### D) Optional: Put logs in RAM
```bash
sudo ./scripts/harden_logging.sh
```

---

## RAID1 Setup for /srv/nas (Optional)

> **Warning:** This erases both SSDs. Adjust device names as needed.

```bash
# 1) Partition each SSD to a single partition
sudo sgdisk --zap-all /dev/sda
sudo sgdisk --zap-all /dev/sdb
sudo sgdisk -n 1:0:0 -t 1:fd00 -c 1:"raid1" /dev/sda
sudo sgdisk -n 1:0:0 -t 1:fd00 -c 1:"raid1" /dev/sdb
sudo partprobe

# 2) Create the RAID1 array
sudo apt-get install -y mdadm
sudo mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sda1 /dev/sdb1

# 3) Make ext4 and mount at /srv/nas
sudo mkfs.ext4 -F -L nas_raid1 /dev/md0
sudo mkdir -p /srv/nas
sudo blkid /dev/md0   # copy the UUID
# Add to /etc/fstab (example):
# UUID=<YOUR-UUID>  /srv/nas  ext4  defaults,noatime,commit=60  0  2
sudo systemctl daemon-reload
sudo mount -a

# 4) Enable SMART + TRIM
sudo apt-get install -y smartmontools util-linux
sudo systemctl enable --now smartmontools.service
sudo systemctl enable --now fstrim.timer
sudo fstrim -v /srv/nas

# 5) Check status
cat /proc/mdstat
sudo mdadm --detail /dev/md0
df -h | grep /srv/nas
```

---

## Original Waveshare LCD Demo (Optional Backup)

If you prefer the **stock** demo or want it as a reference.

### Install dependencies
```bash
sudo apt update
sudo apt install -y python3-spidev python3-numpy python3-pil python3-psutil
```

### Enable SPI
```bash
sudo raspi-config nonint do_spi 0
```

### Download & run
```bash
wget https://github.com/KD5VMF/CM4-NAS-Double-Deck---Waveshare-/raw/main/CM4-NAS-Double-Deck_Demo.zip
unzip CM4-NAS-Double-Deck_Demo.zip
cd CM4-NAS-Double-Deck_Demo/RaspberryPi/example
python3 main.py
```
Stop with **Ctrl+C**.

### Optional auto-start for the demo (systemd)
```bash
sudo tee /etc/systemd/system/cm4lcd.service >/dev/null <<'UNIT'
[Unit]
Description=CM4 NAS LCD Display Service (Waveshare Demo)
After=network.target

[Service]
ExecStart=/usr/bin/python3 /home/sysop/CM4-NAS-Double-Deck_Demo/RaspberryPi/example/main.py
WorkingDirectory=/home/sysop/CM4-NAS-Double-Deck_Demo/RaspberryPi/example
StandardOutput=journal
StandardError=journal
Restart=always
User=sysop

[Install]
WantedBy=multi-user.target
UNIT

sudo systemctl daemon-reload
sudo systemctl enable --now cm4lcd.service
systemctl status cm4lcd.service --no-pager
```
If you see `status=217/USER` or `status=200/CHDIR`, correct `User=` or the paths.

---

## Enable Interfaces (SPI / USB / I2C / RTC)

Edit:
```bash
sudo nano /boot/config.txt
```

Add:
```ini
# SPI for LCD
dtparam=spi=on

# USB 2.0 host
dtoverlay=dwc2,dr_mode=host

# I2C RTC (PCF85063A)
dtoverlay=i2c-rtc,pcf85063a
```

Reboot & check RTC:
```bash
sudo reboot
sudo hwclock -r
```

> Buttons are handled by the dashboard / Waveshare library where applicable.

---

## Networking (LAN & Wi-Fi)

**Ethernet:** plug and go.  
**Wi-Fi:** `sudo raspi-config` → Network Options → Wi-Fi, or edit:

```bash
sudo nano /etc/wpa_supplicant/wpa_supplicant.conf
```

```conf
network={
    ssid="YourWiFiSSID"
    psk="YourWiFiPassword"
}
```

---

## OpenMediaVault (Optional NAS GUI)

```bash
wget -O - https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install | sudo bash
# then open http://<your-pi-ip>/
```

---

## Troubleshooting

**Screen upside down**
```bash
sudo sed -i 's/^LCD_ROTATE=.*/LCD_ROTATE=90/' /etc/default/cm4lcd_pretty
sudo systemctl restart cm4lcd_pretty
```

**GPIO busy / manual run conflicts**
```bash
sudo systemctl stop cm4lcd_pretty
python3 -u /opt/cm4lcd/pretty_dashboard.py
# Ctrl+C to exit, then:
sudo systemctl start cm4lcd_pretty
```

**No LCD library found**
- Ensure `LCD_LIB_DIR` points to a directory with a **subfolder** `lib/LCD_2inch.py`.
- Example: `/home/sysop/CM4-NAS-Double-Deck_Demo/RaspberryPi`

**Verify Bookworm lock**
```bash
apt-cache policy | grep -E 'release|Version table' -A2
# should list n=bookworm, bookworm-updates, bookworm-security
```

**Overlay is ON but /srv/nas is RW**
```bash
grep -o 'overlayroot=[^ ]*' /proc/cmdline
mount | grep -E ' on / |/srv/nas'
# root should be overlay(ro), NAS should be rw
```

**Backlight flicker**
- We drive BL pin high; verify `LCD_BL_PIN=18` and your display’s BL wiring.

---

## FAQ

**Q: Will this upgrade me off Bookworm?**  
A: No. The provided `lock_bookworm.sh` pins APT to Bookworm (and security/updates/backports only).

**Q: Can I still fully update?**  
A: Yes — `apt update && apt full-upgrade` is fine. You’ll never jump to a new Debian release unless you remove the lock.

**Q: What’s the OS-in-RAM overlay?**  
A: Root is read-only and writes go to RAM — protects from corruption if power drops. Use `overlay_off.sh` when you want to install updates (then re-enable overlay with `overlay_on.sh`).

**Q: Can I change colors or layout?**  
A: Most visual tweaks are set in code; basic adjustments (rotation, small vertical shifts, title) are in `/etc/default/cm4lcd_pretty`.

---

## Contributing

PRs welcome — especially for:
- Alternative displays / screen sizes
- Additional sensors or metrics
- Translations or docs

---

## License & Credits

- **NEW-DISPLAY dashboard**: MIT License (see `LICENSE`)
- **Original Waveshare demo** © Waveshare (included as a backup/reference)

**Author / Maintainer:** KD5VMF  
**Repo:** https://github.com/KD5VMF/CM4-NAS-Double-Deck/tree/main/NEW-DISPLAY
