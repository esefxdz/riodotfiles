#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  waybar_watcher.sh
#  Watches active workspace window count and switches wallpaper + UI layer.
#
#  Modes (written to MODE_FILE by the `bedtime` command):
#    normal  → rio_main.mp4  / rio_static.png
#    secret  → rio_secret.mp4 / rio_static_secret.png
#
#  State:
#    0 windows  → mpvpaper video (fallback: static PNG) + Eww widgets
#    1+ windows → black.png via hyprpaper + Waybar
# ─────────────────────────────────────────────────────────────────────────────

logfile="/tmp/waybar_watcher.log"
MODE_FILE="$HOME/.cache/hypr_wallpaper_mode"

# ── Wallpapers ───────────────────────────────────────────────────────────────
video_normal="$HOME/.config/hypr/wallpapers/rio_main.mp4"
video_secret="$HOME/.config/hypr/wallpapers/rio_secret.mp4"
static_normal="$HOME/.config/hypr/wallpapers/rio_static.png"
static_secret="$HOME/.config/hypr/wallpapers/rio_static_secret.png"
wallpaper_black="$HOME/.config/hypr/wallpapers/black.png"

# ── State ────────────────────────────────────────────────────────────────────
current_wallpaper=""   # "video_normal" | "video_secret" | "black"
eww_visible=false
waybar_visible=false
mpvpaper_pid=""

# ── Eww windows ──────────────────────────────────────────────────────────────
eww_windows="active_workspace \
             ascii_decor_frame \
             audio_status \
             cpu_ram_storage_bars \
             four_boxes \
             net_bars \
             right_internet_text \
             welcome_text \
             workspace_window_text"

# ── Helpers ──────────────────────────────────────────────────────────────────

get_mode() {
    cat "$MODE_FILE" 2>/dev/null || echo "normal"
}

get_monitor() {
    hyprctl monitors -j | jq -r '.[0].name'
}

mpvpaper_alive() {
    [[ -n "$mpvpaper_pid" ]] && kill -0 "$mpvpaper_pid" 2>/dev/null
}

start_video_wallpaper() {
    local video_file="$1"
    local static_file="$2"
    local monitor
    monitor=$(get_monitor)

    # Kill any stale mpvpaper
    pkill -x mpvpaper 2>/dev/null
    sleep 0.2

    # Set static as hyprpaper base first:
    #   visible instantly before mpvpaper paints over it,
    #   and acts as crash fallback if mpvpaper dies.
    hyprctl hyprpaper wallpaper "$monitor,$static_file"
    sleep 0.1

    if command -v mpvpaper &>/dev/null && [[ -f "$video_file" ]]; then
        mpvpaper \
            --mpv-options "no-audio loop-file=inf panscan=1.0 hwdec=nvdec video-sync=display-resample" \
            "$monitor" \
            "$video_file" &
        mpvpaper_pid=$!
        echo "[$(date)] mpvpaper started (pid=$mpvpaper_pid) monitor=$monitor file=$(basename "$video_file")" >> "$logfile"
    else
        echo "[$(date)] mpvpaper unavailable or video missing — static fallback only" >> "$logfile"
        mpvpaper_pid=""
    fi
}

stop_video_wallpaper() {
    if mpvpaper_alive; then
        kill "$mpvpaper_pid" 2>/dev/null
        wait "$mpvpaper_pid" 2>/dev/null
        echo "[$(date)] mpvpaper stopped (pid=$mpvpaper_pid)" >> "$logfile"
    else
        pkill -x mpvpaper 2>/dev/null
    fi
    mpvpaper_pid=""
}

# ── Boot: ensure hyprpaper is running and wallpapers are preloaded ────────────
if ! pgrep -x hyprpaper > /dev/null; then
    echo "[$(date)] Starting hyprpaper..." >> "$logfile"
    hyprpaper &
    sleep 1
fi

hyprctl hyprpaper preload "$static_normal"
hyprctl hyprpaper preload "$static_secret"
hyprctl hyprpaper preload "$wallpaper_black"

# Initialise mode file if missing
[[ -f "$MODE_FILE" ]] || echo "normal" > "$MODE_FILE"

# ── Main loop ─────────────────────────────────────────────────────────────────
while true; do
    monitor=$(get_monitor)
    mode=$(get_mode)
    active_workspace=$(hyprctl activeworkspace -j | jq -r '.id')
    window_count=$(hyprctl clients -j | jq "[.[] | select(.workspace.id == $active_workspace and .mapped == true)] | length")

    echo "[$(date)] workspace=$active_workspace windows=$window_count mode=$mode" >> "$logfile"

    if [ "$window_count" -eq 0 ]; then
        # ── No windows: video/static wallpaper based on mode ─────────────────
        expected_state="video_${mode}"   # "video_normal" or "video_secret"

        if [ "$current_wallpaper" != "$expected_state" ]; then
            # Mode changed or first run — pick the right video+static pair
            if [[ "$mode" == "secret" ]]; then
                echo "[$(date)] → secret video wallpaper" >> "$logfile"
                start_video_wallpaper "$video_secret" "$static_secret"
            else
                echo "[$(date)] → normal video wallpaper" >> "$logfile"
                start_video_wallpaper "$video_normal" "$static_normal"
            fi
            current_wallpaper="$expected_state"
        else
            # Same mode — only check for crash recovery
            if ! mpvpaper_alive && [[ -n "$mpvpaper_pid" ]]; then
                echo "[$(date)] mpvpaper crashed — restarting (mode=$mode)" >> "$logfile"
                if [[ "$mode" == "secret" ]]; then
                    start_video_wallpaper "$video_secret" "$static_secret"
                else
                    start_video_wallpaper "$video_normal" "$static_normal"
                fi
            fi
        fi

        if ! $eww_visible; then
            echo "[$(date)] Launching Eww widgets..." >> "$logfile"
            pgrep -x eww || eww daemon &
            sleep 1
            eww open-many $eww_windows
            pgrep -x cava || nohup cava -p "$HOME/.config/cava/config" >/dev/null 2>&1 &
            eww_visible=true
        fi

        if $waybar_visible; then
            echo "[$(date)] Stopping Waybar..." >> "$logfile"
            pkill -x waybar
            waybar_visible=false
        fi

    else
        # ── Windows open: black wallpaper + Waybar ────────────────────────────
        if [ "$current_wallpaper" != "black" ]; then
            echo "[$(date)] → black wallpaper" >> "$logfile"
            stop_video_wallpaper
            hyprctl hyprpaper wallpaper "$monitor,$wallpaper_black"
            current_wallpaper="black"
        fi

        if $eww_visible; then
            echo "[$(date)] Hiding Eww widgets..." >> "$logfile"
            eww close-all
            pkill -x cava
            eww_visible=false
        fi

        if ! $waybar_visible; then
            echo "[$(date)] Starting Waybar..." >> "$logfile"
            nohup waybar >/dev/null 2>&1 &
            waybar_visible=true
        fi
    fi

    sleep 0.5
done
