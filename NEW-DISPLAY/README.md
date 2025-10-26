# CM4 NAS LCD Dashboard (Bookworm)

Large, clean, and flicker-free stats dashboard for a CM4 NAS with a Waveshare **2-inch SPI LCD**.
Shows big **NAS usage**, CPU/RAM, temp, uptime, RAID1 status, and live network throughput.

> ✅ **Tested & supported on Raspberry Pi OS / Debian 12 Bookworm only.**

---

## Features

- Big NAS percentage with used/free numbers
- Fixed to your RAID1 mirror (`/dev/md0` mounted at `/srv/nas`) via `NAS_MOUNT`
- Header with title, **red IP**, **green Date/Time**
- CPU/RAM bars, CPU temp (warns in yellow at ≥70 °C), uptime
- RAID status (**green OK** or **red DEGRADED**)
- Live network Rx/Tx
- Solid backlight (no PWM flicker) via GPIO18
- Rotation control (0/90/180/270)
- Tweak the CPU block vertical offset without editing code (`CPU_Y_SHIFT`)

---

## Requirements (Bookworm only)

- Raspberry Pi **CM4** (or Pi with SPI display)
- Waveshare **2-inch SPI LCD** (uses `lib/LCD_2inch.py` from their demo)
- Raspberry Pi OS **Bookworm** (Debian 12)
- Two SSDs if building the RAID1 mirror

> This project is tailored for **Bookworm**. Other releases are not supported.

---

## Quick install

```bash
# Install prerequisites (SPI, git)
sudo raspi-config nonint do_spi 0    # enables SPI (0 = enable)
sudo apt-get update
sudo apt-get install -y git

# Clone this repo
git clone https://github.com/yourname/cm4-nas-lcd.git
cd cm4-nas-lcd/scripts

# Install the dashboard service
sudo ./install.sh

# Edit environment (set LCD_LIB_DIR to your Waveshare demo path if needed)
sudo nano /etc/default/cm4lcd_pretty

# Restart and watch logs
sudo systemctl restart cm4lcd_pretty
journalctl -u cm4lcd_pretty -n 80 --no-pager
```

### Environment file (`/etc/default/cm4lcd_pretty`)

```ini
NAS_MOUNT=/srv/nas          # your RAID mount
LCD_ROTATE=90               # 0/90/180/270
LCD_TITLE=CM4-NAS
LCD_LIB_DIR=/home/sysop/CM4-NAS-Double-Deck_Demo/RaspberryPi  # path that contains lib/LCD_2inch.py

# Optional
CPU_Y_SHIFT=1               # pixel offset for CPU/RAM/etc block
LCD_BL_PIN=18               # backlight pin (BCM)
```

> If the LCD library isn’t found, set `LCD_LIB_DIR` to the root of your Waveshare demo where `lib/LCD_2inch.py` lives.

---

## Storage setup (RAID1 at `/srv/nas`)

Below is a minimal, Bookworm-friendly recipe similar to what we used.

> ⚠️ **This will wipe both SSDs** (`/dev/sda` and `/dev/sdb`). Adjust device names if different.

```bash
# 1) Partition each SSD to a single primary partition
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
sudo blkid /dev/md0    # copy the UUID
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

> The dashboard will read usage from `NAS_MOUNT` (default `/srv/nas`) and display it as **NAS**.

---

## Running in the foreground (debug)

```bash
sudo systemctl stop cm4lcd_pretty
cm4-nas-lcd/scripts/test_foreground.sh
# Ctrl+C to exit
sudo systemctl start cm4lcd_pretty
```

---

## Uninstall

```bash
cd cm4-nas-lcd/scripts
sudo ./uninstall.sh
```

---

## Notes & Tips

- If the screen ever appears upside down, set `LCD_ROTATE=90|180|270` and restart.
- Backlight flicker? We drive the BL pin high (GPIO18) to avoid PWM hunting.
- If you see `GPIO busy` when running the script manually, stop the service first:
  `sudo systemctl stop cm4lcd_pretty`

---

## License

MIT — see [LICENSE](LICENSE).
