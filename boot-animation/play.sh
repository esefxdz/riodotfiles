#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  Rio Boot Animation
#  Plays boot.mp4 with audio on the DRM framebuffer before SDDM loads.
#
#  Behaviour:
#  - Video loops indefinitely until killed.
#  - Script holds for a minimum of 4 seconds before killing mpv.
#  - SDDM (display-manager.service) is blocked until this script exits.
#    So the desktop only loads once we're done here.
# ─────────────────────────────────────────────────────────────────────────────

VIDEO="/opt/boot-animation/boot.mp4"

# Hide the blinking cursor
setterm -cursor off 2>/dev/null

# Launch mpv on the DRM framebuffer with ALSA audio, looping
mpv \
  --vo=drm \
  --ao=alsa \
  --loop \
  --fs \
  --really-quiet \
  --no-terminal \
  "$VIDEO" &

MPV_PID=$!

# Hold here for at least 4 seconds — forces the first 4 seconds to always play.
# If the video is shorter than 4 seconds it will have already looped by now.
sleep 4

# Kill the looping video. SDDM will now proceed.
kill "$MPV_PID" 2>/dev/null
wait "$MPV_PID" 2>/dev/null

# Restore cursor before handing off to SDDM
setterm -cursor on 2>/dev/null
