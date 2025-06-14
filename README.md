
# CM4-NAS-Double-Deck Setup Guide

This guide helps you fully configure your Raspberry Pi CM4 NAS in the Waveshare CM4-NAS-Double-Deck enclosure — including LCD, RTC, USB, buttons, and OpenMediaVault.

---

## 📺 1. LCD Display Demo Setup (Backup File Provided)

This repository includes a **backup of the Waveshare LCD demo**. This is only the graphical Python script that shows real-time info (like temperature and disk usage) on the attached LCD.

### 🔽 Download and Test the LCD Demo

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

## 🧾 2. Install Dependencies

Install the required Python libraries for the LCD demo to work:

```bash
sudo apt update
sudo apt install python3-spidev python3-numpy python3-pil python3-psutil -y
```

---

## 🔗 3. Official Waveshare LCD Demo Download (Alternate Source)

You can also get the official demo from Waveshare (same contents):

[https://www.waveshare.net/w/upload/7/73/CM4-NAS-Double-Deck_Demo.zip](https://www.waveshare.net/w/upload/7/73/CM4-NAS-Double-Deck_Demo.zip)

---

## 🗄 4. Install OpenMediaVault (NAS GUI)

To install OMV (web-based NAS management):

```bash
wget -O - https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install | sudo bash
```

Then open the browser and go to:

```
http://<your-device-ip>/
```

---

## ⚙️ 5. Enable Interfaces (RTC, USB, SPI, I2C, Buttons)

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

## 🌐 6. Networking Setup

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

### ℹ️ Attribution & License

- Original demo © Waveshare  
- This repository includes a backup copy of the LCD display demo for educational and restoration purposes.

---

For questions or contributions, open an issue or pull request. Enjoy your Raspberry Pi CM4 NAS! 🚀
