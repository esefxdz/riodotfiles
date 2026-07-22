#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  ascii_live_log.sh — generates live log ASCII art for the Eww HUD
#  Writes to /tmp/live_text.txt for the live_text widget to consume
# ─────────────────────────────────────────────────────────────────────────────
output_file="/tmp/live_text.txt"

# Fallback: display system uptime as a live feed
uptime_str=$(awk '{sec=int($1); printf "%02d:%02d:%02d", sec/3600, (sec%3600)/60, sec%60}' /proc/uptime 2>/dev/null)
echo "UPTIME: $uptime_str" > "$output_file"
echo "KERNEL: $(uname -r | cut -d- -f1)" >> "$output_file"
echo "PKGS: $(pacman -Q 2>/dev/null | wc -l) installed" >> "$output_file"
