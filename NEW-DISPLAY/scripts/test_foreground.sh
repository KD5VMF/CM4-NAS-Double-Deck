#!/usr/bin/env bash
set -euo pipefail
if [ -f /etc/default/cm4lcd_pretty ]; then
  set -a
  . /etc/default/cm4lcd_pretty
  set +a
fi
python3 -u /opt/cm4lcd/pretty_dashboard.py
