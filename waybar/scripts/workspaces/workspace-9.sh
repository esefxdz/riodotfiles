#!/bin/bash
# workspace-9.sh — highlight workspace 9 if active

active=$(hyprctl activeworkspace -j | jq '.id')

if [ "$active" -eq 9 ]; then
  echo "[<span foreground='#fab387'>●</span>]"
else
  echo "[И]"
fi
