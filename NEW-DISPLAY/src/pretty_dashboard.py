#!/usr/bin/env python3
import os, sys, time, signal, socket, subprocess
from datetime import datetime
from PIL import Image, ImageDraw, ImageFont
import psutil

# ---- Waveshare lib path ----
LCD_LIB_DIR = os.getenv("LCD_LIB_DIR", "/home/sysop/CM4-NAS-Double-Deck_Demo/RaspberryPi")
if os.path.isfile(os.path.join(LCD_LIB_DIR, "lib", "LCD_2inch.py")):
    sys.path.insert(0, LCD_LIB_DIR)
else:
    here = os.path.dirname(os.path.abspath(__file__))
    for probe in ("../CM4-NAS-Double-Deck_Demo/RaspberryPi", "../RaspberryPi"):
        p = os.path.realpath(os.path.join(here, probe))
        if os.path.isfile(os.path.join(p, "lib", "LCD_2inch.py")):
            sys.path.insert(0, p)
            break

from lib import LCD_2inch

# ---- Config (env-overridable) ----
NAS_MOUNT   = os.getenv("NAS_MOUNT", "/srv/nas")
ROTATE      = int(os.getenv("LCD_ROTATE", "90"))   # 0/90/180/270
TITLE       = os.getenv("LCD_TITLE", "CM4 NAS")
TICK        = 2.0
CPU_Y_SHIFT = int(os.getenv("CPU_Y_SHIFT","1"))    # vertical offset for CPU block (and below)
LCD_BL_PIN  = int(os.getenv("LCD_BL_PIN","18"))    # backlight pin (BCM numbering)

# Colors
ACCENT = (64,170,255)           # Title & highlights (blue)
BG     = (10,14,18)             # Background
FG     = (235,240,245)          # Main text (white-ish)
WARN   = (255,200,40)           # Yellow
ALERT  = (255,86,86)            # Red
GREEN  = (140,255,160)          # Green

def font(size, bold=False):
    try:
        path = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
        return ImageFont.truetype(path, size)
    except Exception:
        return ImageFont.load_default()

F_BIG  = font(56)
F_MED  = font(28)
F_SM   = font(16)

def human(n: int) -> str:
    for unit in ("B","KB","MB","GB","TB","PB"):
        if abs(n) < 1024.0:
            return f"{n:3.1f} {unit}"
        n /= 1024.0
    return f"{n:.1f} EB"

def dev_for_mount(m):
    try:
        with open("/proc/self/mounts","r") as f:
            for line in f:
                dev, mnt = line.split()[:2]
                if mnt == m:
                    return dev
    except Exception:
        pass
    return "?"

def find_nas_mount():
    m = NAS_MOUNT
    if os.path.ismount(m):
        return m
    # Fallback to first md* device if present
    try:
        with open("/proc/self/mounts","r") as f:
            for line in f:
                dev, mnt = line.split()[:2]
                if dev.startswith("/dev/md"):
                    return mnt
    except Exception:
        pass
    return "/"

def disk():
    m = find_nas_mount()
    du = psutil.disk_usage(m)
    pct = int(du.used * 100 / max(1, du.total))
    return m, du.total, du.used, du.free, pct, dev_for_mount(m)

def ip_addr():
    for ifname, addrs in psutil.net_if_addrs().items():
        if ifname.startswith(("lo","veth","docker")): 
            continue
        for a in addrs:
            if getattr(a,"family",None) == socket.AF_INET and not a.address.startswith("169.254."):
                return a.address
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.connect(("1.1.1.1",80))
        ip = s.getsockname()[0]; s.close(); return ip
    except Exception:
        return "0.0.0.0"

def raid_status():
    try:
        txt = open("/proc/mdstat").read()
        if "md0" in txt:
            return ("RAID1 md0 OK", True) if "[UU]" in txt else ("RAID1 md0 DEGRADED", False)
    except Exception:
        pass
    return ("RAID not found", False)

def uptime():
    bt = datetime.fromtimestamp(psutil.boot_time())
    delta = datetime.now() - bt
    d = delta.days; h = delta.seconds//3600; m = (delta.seconds%3600)//60
    return f"{d}d {h}h {m}m" if d else f"{h}h {m}m"

def cpu_temp():
    for p in ("/sys/class/thermal/thermal_zone0/temp","/sys/class/thermal/thermal_zone1/temp"):
        try:
            v = open(p).read().strip()
            if v:
                vi = int(v); return vi/1000.0 if vi>200 else float(vi)
        except Exception: pass
    try:
        out = subprocess.check_output(["vcgencmd","measure_temp"], text=True)
        return float(out.split("=")[1].split("'")[0])
    except Exception:
        return float("nan")

def bar(draw, x, y, w, h, pct):
    draw.rounded_rectangle([x,y,x+w,y+h], radius=h//2, fill=(40,60,80))
    pw  = max(1, int(w * max(0, min(100,pct)) / 100))
    col = ACCENT if pct < 85 else (WARN if pct < 95 else ALERT)
    draw.rounded_rectangle([x,y,x+pw,y+h], radius=h//2, fill=col)

def draw_right_label_value(d, x, y, label, value, font_label, font_value, color_label, color_value):
    """Draw right-aligned 'label value' where value ends at x and label sits to its left, with separate colors."""
    try:
        vb = d.textbbox((0,0), value, font=font_value)
        vw = vb[2] - vb[0]
    except Exception:
        vw = font_value.getlength(value) if hasattr(font_value, "getlength") else len(value)*8
    d.text((x, y), value, font=font_value, fill=color_value, anchor="ra")
    d.text((x - vw, y), label, font=font_label, fill=color_label, anchor="ra")

def force_backlight_on():
    """Drive the LCD backlight pin high to avoid PWM flicker. Uses RPi.GPIO or lgpio."""
    pin = LCD_BL_PIN
    try:
        import RPi.GPIO as GPIO
        GPIO.setwarnings(False)
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(pin, GPIO.OUT)
        GPIO.output(pin, True)
        return
    except Exception:
        pass
    try:
        import lgpio
        h = lgpio.gpiochip_open(0)
        lgpio.gpio_claim_output(h, pin, 1)
        lgpio.gpio_write(h, pin, 1)
    except Exception:
        pass

def run():
    lcd = LCD_2inch.LCD_2inch(); lcd.Init()
    force_backlight_on()
    W, H = lcd.width, lcd.height
    cw, ch = (H, W) if ROTATE in (90,180,270) else (W, H)

    last_io = psutil.net_io_counters(); last_t = time.monotonic()
    my_ip = ip_addr()

    running = True
    def stop(*_): 
        nonlocal running; running=False
    signal.signal(signal.SIGTERM, stop); signal.signal(signal.SIGINT, stop)

    while running:
        img = Image.new("RGB", (cw, ch), BG); d = ImageDraw.Draw(img)

        # Header
        now = datetime.now().strftime("%a %b %d  %I:%M:%S %p")
        d.text((12, 8), TITLE, font=F_MED, fill=ACCENT)               # title (blue)
        d.text((cw-12, 10), my_ip, font=F_SM, fill=ALERT, anchor="ra")# IP (red)
        d.text((12, 40), now, font=F_SM, fill=GREEN)                   # Date/Time (green)

        # NAS usage (fixed to NAS_MOUNT or detected md*)
        mnt, total, used, free, pct, dev = disk()
        d.text((12, 58), "NAS", font=F_SM, fill=ALERT)                 # NAS label (red)
        d.text((12, 76), f"{pct}%", font=F_BIG, fill=FG)               # Big percent (white)
        d.text((cw-12, 70), f"{os.path.basename(dev) or dev} @ {mnt}", font=F_SM, fill=ALERT, anchor="ra")  # dev@mount (red)
        draw_right_label_value(d, cw-12, 90,  "Used ", human(used), F_SM, F_SM, ACCENT, FG)  # Used label blue, value white
        draw_right_label_value(d, cw-12, 110, "Free ", human(free), F_SM, F_SM, ACCENT, FG)  # Free label blue, value white
        bar(d, 12, 136, cw-24, 22, pct)

        # CPU / RAM / Temp / Uptime (positions include CPU_Y_SHIFT)
        cpu_pct = int(psutil.cpu_percent(interval=None))
        d.text((12, 185 + CPU_Y_SHIFT), f"CPU {cpu_pct:>2d}%", font=F_MED, fill=FG)
        bar(d, 150, 193 + CPU_Y_SHIFT, cw-162, 16, cpu_pct)

        mem = int(psutil.virtual_memory().percent)
        d.text((12, 219 + CPU_Y_SHIFT), f"RAM {mem:>2d}%", font=F_MED, fill=FG)
        bar(d, 150, 227 + CPU_Y_SHIFT, cw-162, 16, mem)

        t   = cpu_temp()
        up  = uptime()
        d.text((12, 253 + CPU_Y_SHIFT), f"Temp {t:.1f}°C" if t==t else "Temp n/a", font=F_MED, fill=(255,220,160) if (t==t and t>=70) else FG)
        d.text((cw-12, 255 + CPU_Y_SHIFT), f"Up {up}", font=F_SM, fill=(190,200,210), anchor="ra")

        # RAID + Net
        rtxt, rok = raid_status()
        d.text((12, 287 + CPU_Y_SHIFT), rtxt, font=F_MED, fill=(140,255,160) if rok else ALERT)

        now_t = time.monotonic(); io = psutil.net_io_counters(); dt = max(0.001, now_t-last_t)
        rx = (io.bytes_recv - last_io.bytes_recv)/dt; tx = (io.bytes_sent - last_io.bytes_sent)/dt
        last_io, last_t = io, now_t
        d.text((cw-12, 289 + CPU_Y_SHIFT), f"Net {human(rx)}/s ↓  {human(tx)}/s ↑", font=F_SM, fill=(170,200,255), anchor="ra")

        if ROTATE in (90,180,270): img = img.rotate(ROTATE, expand=True)
        lcd.ShowImage(img); time.sleep(TICK)

if __name__ == "__main__":
    try:
        run()
    except Exception as e:
        import traceback
        print("[pretty_dashboard] FATAL:", e, file=sys.stderr)
        traceback.print_exc()
        time.sleep(2)
        raise
