#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  Waybar screen recorder helper — uses wf-recorder
#  Usage: recorder.sh [toggle|status]
# ─────────────────────────────────────────────────────────────────────────────

PIDFILE="/tmp/waybar-recorder.pid"
OUTDIR="$HOME/Videos/Recordings"
mkdir -p "$OUTDIR"

is_recording() {
  [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null
}

case "$1" in
  toggle)
    if is_recording; then
      kill -SIGINT "$(cat "$PIDFILE")" && rm -f "$PIDFILE"
    else
      FILENAME="$OUTDIR/$(date '+%Y-%m-%d_%H-%M-%S').mp4"
      wf-recorder -f "$FILENAME" &
      echo $! > "$PIDFILE"
    fi
    ;;
  status|*)
    if is_recording; then
      echo '{"text":"[ 󰑊 REC ]","class":"recording","tooltip":"Recording… click to stop"}'
    else
      echo '{"text":"[ 󰄀 ]","class":"idle","tooltip":"Click to start recording"}'
    fi
    ;;
esac
