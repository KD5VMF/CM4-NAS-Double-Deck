
# CM4-NAS-Double-Deck Setup Guide

This repository contains everything you need to set up your Raspberry Pi Compute Module 4 (CM4) in the NAS-Double-Deck configuration, using the Waveshare demo LCD, RTC, and OpenMediaVault (OMV) for network-attached storage.

## 📦 Features

- Raspberry Pi OS Lite (64-bit)
- LCD Display with system info
- SPI, I2C, USB 2.0 enabled
- RTC (Real-Time Clock) via I2C (PCF85063A)
- OMV for full NAS management via web GUI
- Optional Wi-Fi configuration
- Autostart of LCD display on boot

## 🧰 Setup Instructions

### Step 1: Flash Raspberry Pi OS Lite
- Use the Raspberry Pi Imager to flash Raspberry Pi OS Lite (64-bit)
- Enable SSH, set hostname, and configure Wi-Fi (if needed)

### Step 2: Enable Interfaces
Edit `/boot/config.txt`:
```ini
# Enable SPI for LCD
dtparam=spi=on

# Enable USB 2.0 ports
dtoverlay=dwc2,dr_mode=host

# Enable I2C RTC
dtoverlay=i2c-rtc,pcf85063a
```

Reboot and verify RTC:
```bash
sudo reboot
sudo hwclock -r
```

### Step 3: Install LCD Display Script
```bash
sudo apt update
sudo apt install python3-numpy python3-pil python3-psutil -y
wget https://www.waveshare.net/w/upload/7/73/CM4-NAS-Double-Deck_Demo.zip
unzip CM4-NAS-Double-Deck_Demo.zip
cd CM4-NAS-Double-Deck_Demo/RaspberryPi/example
python3 main.py
```

### Auto-Start the LCD on Boot
Edit `/etc/rc.local` before `exit 0`:
```bash
cd /home/pi/CM4-NAS-Double-Deck_Demo/RaspberryPi/example
sudo python3 main.py &
```

### Step 4: Install OpenMediaVault (OMV)
```bash
wget -O - https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install | sudo bash
```
Then access OMV via:
```
http://<your-device-ip>/
```

### Step 5: Configure Networking
If using Ethernet, just plug it in.

If using Wi-Fi:
```bash
sudo raspi-config
```
Or edit manually:
```bash
sudo nano /etc/wpa_supplicant/wpa_supplicant.conf
```
Add:
```conf
network={
    ssid="YourWiFiSSID"
    psk="YourWiFiPassword"
}
```

## ✅ Summary

| Feature         | Configured |
|----------------|------------|
| Raspberry Pi OS | ✅        |
| RTC             | ✅        |
| USB, SPI, I2C   | ✅        |
| LCD Display     | ✅        |
| NAS Sharing (OMV) | ✅     |
| Networking      | ✅        |

---

For questions or issues, feel free to open an issue or fork the project. Enjoy your Raspberry Pi CM4 NAS! 🚀
