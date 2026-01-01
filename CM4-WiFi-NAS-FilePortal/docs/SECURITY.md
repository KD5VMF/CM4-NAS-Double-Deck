# Security notes

This project intentionally makes a small “private LAN” on `wlan0`. Treat it like a router.

Recommended:
- Use a strong WPA2 passphrase (12+ chars)
- Keep the web portal on a non-standard port (default 8081 is fine)
- Use a strong File Browser admin password
- Consider creating a non-admin File Browser user for everyday use
- If you enable NAT, AP clients can reach the internet via `eth0`. If you do NOT want that, disable NAT in installer.
- Consider firewalling the portal to `wlan0` only (advanced)
- Keep OS updated (temporarily unlock overlayroot to update)
