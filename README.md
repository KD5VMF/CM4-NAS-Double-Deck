
# CM4-NAS-Double-Deck Setup Guide

This guide helps you fully configure your Raspberry Pi CM4 NAS in the Waveshare CM4-NAS-Double-Deck enclosure — including LCD, RTC, USB, buttons, and OpenMediaVault.

---

## 🔐 Before You Begin: Accessing Your CM4 NAS

You will need to SSH into your Raspberry Pi CM4 after flashing Raspberry Pi OS Lite.

If you haven’t enabled SSH yet:
- Use the Raspberry Pi Imager “Advanced Options” to enable SSH and set the username/password
- Or, create an empty file named `ssh` (no extension) in the boot partition of the SD card

Then connect via SSH from your PC:

```bash
ssh pi@<your-pi-ip-address>
```

Replace `<your-pi-ip-address>` with the actual IP shown by your router or network scanner.

---

## 📺 1. LCD Display Demo Setup (Backup File Provided)

This repository includes a **backup of the Waveshare LCD demo**. This is only the graphical Python script that shows real-time info (like temperature and disk usage) on the attached LCD.

The image.py file in this repository has been fully reviewed and cleaned compared to the original Waveshare version: See below for changes.
### 🔧 Install Python Dependencies First

```bash
sudo apt update
sudo apt install python3-spidev python3-numpy python3-pil python3-psutil -y
```

---

### 🔽 Download and Test the LCD Demo (Backup)

```bash
wget https://github.com/KD5VMF/CM4-NAS-Double-Deck---Waveshare-/raw/main/CM4-NAS-Double-Deck_Demo.zip
unzip CM4-NAS-Double-Deck_Demo.zip
cd CM4-NAS-Double-Deck_Demo/RaspberryPi/example
python3 main.py
```

### 🛑 To Stop the Demo

Press `Ctrl+C` in the terminal.

---

### 🚀 Auto-Start LCD on Boot (Optional)

To auto-run the display program at boot:

```bash
sudo nano /etc/rc.local
```

Add **before** `exit 0`:

```bash
cd /home/pi/CM4-NAS-Double-Deck_Demo/RaspberryPi/example
sudo python3 main.py &
```

---

## 🔗 2. Official Waveshare LCD Demo Download (Alternate Source)

You can also get the **official demo** from Waveshare’s website. The contents are the same as the backup provided in this repository.

### 🔧 Install Python Dependencies First

```bash
sudo apt update
sudo apt install python3-spidev python3-numpy python3-pil python3-psutil -y
```

### 🔽 Download and Test the Official Demo

```bash
wget https://www.waveshare.net/w/upload/7/73/CM4-NAS-Double-Deck_Demo.zip
unzip CM4-NAS-Double-Deck_Demo.zip
cd CM4-NAS-Double-Deck_Demo/RaspberryPi/example
python3 main.py
```

### 🛑 To Stop the Demo

Press `Ctrl+C` in the terminal.

---

### 🚀 Auto-Start the Official Demo on Boot (Optional)

To run the official LCD script on boot, add this before `exit 0` in `/etc/rc.local`:

```bash
cd /home/pi/CM4-NAS-Double-Deck_Demo/RaspberryPi/example
sudo python3 main.py &
```

---

## ⚙️ 3. Enable Interfaces (RTC, USB, SPI, I2C, Buttons)

Edit the config file:

```bash
sudo nano /boot/config.txt
```

Add the following lines:

```ini
# Enable SPI for LCD
dtparam=spi=on

# Enable USB 2.0 ports
dtoverlay=dwc2,dr_mode=host

# Enable I2C RTC
dtoverlay=i2c-rtc,pcf85063a
```

### 🔁 Reboot and Check RTC

```bash
sudo reboot
sudo hwclock -r
```

---

## 🌐 4. Networking Setup

### Ethernet  
Just plug in the cable.

### Wi-Fi  
Use `raspi-config`:

```bash
sudo raspi-config
# Go to Network Options → Wi-Fi
```

Or manually edit:

```bash
sudo nano /etc/wpa_supplicant/wpa_supplicant.conf
```

Add your network info:

```conf
network={
    ssid="YourWiFiSSID"
    psk="YourWiFiPassword"
}
```

---

## 🗄 Final Step: Install OpenMediaVault (NAS GUI)

To install OMV (web-based NAS management):

```bash
wget -O - https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install | sudo bash
```

Then open the browser and go to:

```
http://<your-device-ip>/
```

---

## ✅ Summary

| Feature               | Status |
|-----------------------|:------:|
| Raspberry Pi OS Lite  | ✅     |
| LCD Info Display      | ✅     |
| RTC (PCF85063A)       | ✅     |
| USB/SPI/I2C enabled   | ✅     |
| OMV Installed         | ✅     |
| Networking (LAN/Wi-Fi)| ✅     |

---

## 🧹 LCD Demo Code Cleanup & Enhancements

The `image.py` file in this repository has been fully reviewed and cleaned compared to the original Waveshare version:

### ✅ 1. Language Cleanup
We removed or translated all non-English comments, originally written in Chinese:

| Original Comment (Partial)       | New Comment                 |
|----------------------------------|-----------------------------|
| `#TIME 时间`                     | `# TIME`                    |
| `#CPU usage CPU使用率`          | `# CPU usage`              |
| `#TEMP 温度`                    | `# Temperature`            |
| `#System disk usage 系统磁盘使用率` | `# System disk usage`  |
| `#Disk 使用情况`               | `# Disk usage`             |
| `#memory_percentage 内存百分比` | `# Memory usage percentage`|
| `#speed 网速`                  | `# Network speed`          |
| Non-English-only comments        | ✅ Removed entirely         |

---

### 🔐 2. Safety & Code Quality Observations

We have not yet changed logic behavior, but we identified areas improved in our version:

- ⚠ `eval(self.CPU_usage[3])` replaced with safe `float(...)` call
- ⚠ `os.popen()` usages flagged for future replacement with `psutil` methods
- 🤏 Font loading optimized (fonts not reloaded repeatedly)
- 📁 Paths and naming made more portable and consistent

You are encouraged to continue improving the logic, but this version is stable and runs safely.

🆕 The cleaned file is named `image.py` in this repo.

---

### ℹ️ Attribution & License

- Original demo © Waveshare  
- This repository includes a backup copy of the LCD display demo for educational and restoration purposes.

---

For questions or contributions, open an issue or pull request. Enjoy your Raspberry Pi CM4 NAS! 🚀
