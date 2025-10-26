# CM4-NAS-Double-Deck Setup Guide

> **Tested on Raspberry Pi OS (Debian 12) — Bookworm.**  
> This guide covers LCD, RTC, USB, buttons, a modern LCD dashboard, and optional OpenMediaVault.

- `NEW-DISPLAY/` — modern, pretty LCD dashboard with service + hardening scripts (Bookworm only).
- **Backup** of the original Waveshare LCD demo is also referenced for users who want the stock example.

---

## 🔐 Access your CM4 NAS

After flashing Raspberry Pi OS **Lite (Bookworm)**:

1. In Raspberry Pi Imager → **Advanced Options**, enable **SSH** and set user/password, **or**
2. Create an empty file named `ssh` on the boot partition.

Then SSH in from your PC:

```bash
ssh pi@<your-pi-ip-address>
