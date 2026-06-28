#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  togglestats — toggle left-side stats widgets
#
#  visible → hidden : closes cpu/ram/net bars
#  hidden  → visible : reopens them
#
#  state is written to ~/.cache/hypr_stats_visible so the toggle
#  survives across terminal sessions.
# ─────────────────────────────────────────────────────────────────────────────

STATE_FILE="$HOME/.cache/hypr_stats_visible"
mkdir -p "$(dirname "$STATE_FILE")"

STATS_WINDOWS="cpu_ram_storage_bars net_bars right_internet_text"

current=$(cat "$STATE_FILE" 2>/dev/null || echo "visible")

if [[ "$current" == "visible" ]]; then
    eww close $STATS_WINDOWS
    echo "hidden" > "$STATE_FILE"
    echo "Gone. Enjoy the view."
else
    eww open-many $STATS_WINDOWS
    echo "visible" > "$STATE_FILE"
    echo "Back up. Numbers ruining your vibe again."
fi
