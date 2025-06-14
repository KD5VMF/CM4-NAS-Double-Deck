
# CM4-NAS-Double-Deck Setup Guide

This repository contains a **backup** of the official Waveshare demo so you can continue setup even if the original file becomes unavailable.

## 📥 1. Download & Use Backup File

- **Filename:** `waveshare_demo_backup.zip`  
- **Located in this repo:** [./waveshare_demo_backup.zip](./waveshare_demo_backup.zip)
- **Installation steps:**
  ```bash
  wget https://github.com/KD5VMF/CM4-NAS-Double-Deck---Waveshare-/raw/main/waveshare_demo_backup.zip
  unzip waveshare_demo_backup.zip
  cd CM4-NAS-Double-Deck_Demo/RaspberryPi/example
  python3 main.py
  ```
- **Auto-start on boot:** Add before `exit 0` in `/etc/rc.local`:
  ```bash
  cd /home/pi/CM4-NAS-Double-Deck_Demo/RaspberryPi/example
  sudo python3 main.py &
  ```

---

## 🔗 2. Official Waveshare Download

Prefer the original? You can still download directly from Waveshare:

[https://www.waveshare.net/w/upload/7/73/CM4-NAS-Double-Deck_Demo.zip](https://www.waveshare.net/w/upload/7/73/CM4-NAS-Double-Deck_Demo.zip)

Check the demo contents and follow the same installation steps in section 1.

---

## 🧰 Setup Instructions

### 1. Flash Raspberry Pi OS Lite (64-bit)
- Use **Raspberry Pi Imager**
- Enable SSH, set hostname, configure Wi‑Fi if needed

### 2. Enable Interfaces (SPI, USB, RTC)

Edit `/boot/config.txt`:
```ini
# Enable SPI for LCD
dtparam=spi=on

# Enable USB 2.0 ports
dtoverlay=dwc2,dr_mode=host

# Enable I2C RTC (PCF85063A)
dtoverlay=i2c-rtc,pcf85063a
```

Reboot and verify RTC:
```bash
sudo reboot
sudo hwclock -r
```

### 3. Install LCD Display Script

Install dependencies:
```bash
sudo apt update
sudo apt install python3-numpy python3-pil python3-psutil -y
```

Download and run the demo (either backup or official):
```bash
wget <URL-from-01-or-02>
unzip *.zip
cd CM4-NAS-Double-Deck_Demo/RaspberryPi/example
python3 main.py
```

### 4. Auto-Start on Boot

Edit `/etc/rc.local` **before** `exit 0`:
```bash
cd /home/pi/CM4-NAS-Double-Deck_Demo/RaspberryPi/example
sudo python3 main.py &
```

### 5. Install OpenMediaVault (OMV)

```bash
wget -O - https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install | sudo bash
```
Access via browser: `http://<your-device-ip>/`

### 6. Networking

- **Ethernet:** Plug and go  
- **Wi‑Fi:**  
  ```bash
  sudo raspi-config
  # Navigate to Network Options → Wi‑Fi
  ```  
  Or set manually in `/etc/wpa_supplicant/wpa_supplicant.conf`:
  ```conf
  network={
    ssid="YourWiFiSSID"
    psk="YourWiFiPassword"
  }
  ```

---

## ✅ Summary

| Feature               | Result |
|-----------------------|:------:|
| Raspberry Pi OS       | ✅     |
| RTC (PCF85063A)       | ✅     |
| USB/SPI/I2C enabled   | ✅     |
| LCD Display           | ✅     |
| NAS via OMV           | ✅     |
| Networking            | ✅     |

---

### ℹ️ Attribution & License

- Original demo package © Waveshare (licensed under their terms).  
- This repo provides a **backup copy** for convenience.

---

For questions or issues, feel free to open an issue or fork the project. Enjoy your CM4 NAS setup! 🚀
