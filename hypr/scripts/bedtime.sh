#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  bedtime — toggle secret wallpaper mode
#
#  normal → secret : switches to rio_secret.mp4 + rio_static_secret.png
#  secret → normal : switches back to rio_main.mp4 + rio_static.png
#
#  waybar_watcher.sh polls ~/.cache/hypr_wallpaper_mode every 0.5s
# ─────────────────────────────────────────────────────────────────────────────

MODE_FILE="$HOME/.cache/hypr_wallpaper_mode"
mkdir -p "$(dirname "$MODE_FILE")"

current=$(cat "$MODE_FILE" 2>/dev/null || echo "normal")

if [[ "$current" == "normal" ]]; then
    echo "secret" > "$MODE_FILE"
    echo "You are in that mood, are you not esef?"
else
    echo "normal" > "$MODE_FILE"
    echo "That's enough esef..."
fi
