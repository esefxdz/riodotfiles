#!/usr/bin/env python3
"""
mp4_to_gif.py — Rio's ffmpeg tools
Drag and drop an mp4 into the terminal. Get a high-quality gif back.

Install: symlink or copy this to ~/.config/scripts/mp4togif and chmod +x it.
Usage:   mp4togif
"""

import subprocess
import sys
import os

# ── Colors ────────────────────────────────────────────────────────────────────
RED   = "\033[38;5;196m"
DIM   = "\033[38;5;88m"
WHITE = "\033[97m"
GRAY  = "\033[38;5;244m"
RESET = "\033[0m"

def rio(msg):
    print(f"  {RED}rio »{RESET} {msg}")

def hint(msg):
    print(f"  {GRAY}      {msg}{RESET}")

# ── Entry ─────────────────────────────────────────────────────────────────────
def main():
    print()
    print(f"  {RED}┌─ mp4 → gif ──────────────────────────────────────────┐{RESET}")
    print(f"  {RED}│{RESET}  {WHITE}drag your mp4 in here and press enter{RESET}              {RED}│{RESET}")
    print(f"  {RED}└──────────────────────────────────────────────────────┘{RESET}")
    print()
    rio(f"fine, fine... i'll convert it for you. just drop the file.")
    print()

    try:
        raw = input(f"  {DIM}drop here »{RESET} ").strip()
    except KeyboardInterrupt:
        print()
        rio("i was right in the middle of something, you know.")
        sys.exit(0)

    # Clean the path — handles quotes, escaped spaces, and file:// prefixes
    # (all common when dragging into terminals on Wayland)
    path = raw.strip("'\"").replace("file://", "").strip()
    # Handle escaped spaces like /path/with\ spaces
    path = bytes(path, "utf-8").decode("unicode_escape") if "\\" in path else path

    print()

    if not path:
        rio("you gave me nothing. seriously.")
        sys.exit(1)

    if not os.path.isfile(path):
        rio(f"i can't find that file. did you drag it correctly?")
        hint(f"path i got: {path}")
        sys.exit(1)

    ext = os.path.splitext(path)[1].lower()
    if ext not in (".mp4", ".mov", ".mkv", ".webm", ".avi"):
        rio(f"that's a {ext} file. i only do video files, not whatever that is.")
        sys.exit(1)

    output = os.path.splitext(path)[0] + ".gif"
    name   = os.path.basename(path)

    rio(f"okay, got {WHITE}{name}{RESET}. give me a second...")
    hint("using palette-based conversion for best quality.")
    print()

    # High-quality gif: lanczos scale + palettegen + bayer dithering
    cmd = [
        "ffmpeg",
        "-y",
        "-i", path,
        "-vf", (
            "fps=15,"
            "scale=640:-1:flags=lanczos,"
            "split[s0][s1];"
            "[s0]palettegen=max_colors=256[p];"
            "[s1][p]paletteuse=dither=bayer:bayer_scale=5"
        ),
        "-loglevel", "error",
        "-stats",
        output
    ]

    try:
        result = subprocess.run(cmd)
    except FileNotFoundError:
        print()
        rio("ffmpeg isn't installed. run: sudo pacman -S ffmpeg")
        sys.exit(1)

    print()

    if result.returncode == 0:
        size_mb = os.path.getsize(output) / (1024 * 1024)
        rio(f"done. {WHITE}{os.path.basename(output)}{RESET} is ready.")
        hint(f"saved to: {output}")
        hint(f"size:     {size_mb:.1f} MB")
        print()
        rio("next time maybe say thank you. just a thought.")
    else:
        rio("ffmpeg ran into a problem. check the output above.")
        sys.exit(1)

    print()

if __name__ == "__main__":
    main()
