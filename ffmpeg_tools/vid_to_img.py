#!/usr/bin/env python3
"""
vid_to_img.py — Rio's ffmpeg tools
Extracts a frame from a video and saves it as PNG or JPG depending on the arg.
"""

import subprocess
import sys
import os

RED   = "\033[38;5;196m"
DIM   = "\033[38;5;88m"
WHITE = "\033[97m"
GRAY  = "\033[38;5;244m"
RESET = "\033[0m"

def rio(msg):
    print(f"  {RED}rio »{RESET} {msg}")

def hint(msg):
    print(f"  {GRAY}      {msg}{RESET}")

def main():
    if len(sys.argv) < 2 or sys.argv[1].lower() not in ("png", "jpg"):
        fmt = "png"
    else:
        fmt = sys.argv[1].lower()

    print()
    print(f"  {RED}┌─ video → {fmt.upper()} ────────────────────────────────────┐{RESET}")
    print(f"  {RED}│{RESET}  {WHITE}drop video, pick a time, get an image{RESET}              {RED}│{RESET}")
    print(f"  {RED}└──────────────────────────────────────────────────────┘{RESET}")
    print()
    rio(f"want a thumbnail? drop the video here.")
    print()

    try:
        raw = input(f"  {DIM}drop here »{RESET} ").strip()
    except KeyboardInterrupt:
        print("\n  rio » fine. leaving.")
        sys.exit(0)

    path = raw.strip("'\"").replace("file://", "").strip()
    path = bytes(path, "utf-8").decode("unicode_escape") if "\\" in path else path
    print()

    if not path or not os.path.isfile(path):
        rio("can't find that file. try again.")
        sys.exit(1)

    # Ask for timestamp
    rio("first frame or specific time?")
    hint("hit Enter for first frame, or type time (e.g. 5, or 00:01:23)")
    print()
    
    try:
        timestamp = input(f"  {DIM}time [0] »{RESET} ").strip()
        if not timestamp:
            timestamp = "0"
    except KeyboardInterrupt:
        print("\n  rio » aborting.")
        sys.exit(0)
    print()

    output = os.path.splitext(path)[0] + f"_thumb.{fmt}"
    name = os.path.basename(path)

    rio(f"snapping a {WHITE}{fmt.upper()}{RESET} from {WHITE}{name}{RESET} at {WHITE}{timestamp}{RESET}...")

    cmd = [
        "ffmpeg", "-y", 
        "-ss", timestamp, 
        "-i", path, 
        "-vframes", "1", 
        "-q:v", "2",  # High quality for jpg, ignored by png
        "-loglevel", "error", 
        output
    ]

    subprocess.run(cmd)

    print()
    if os.path.exists(output):
        rio(f"done. your image is ready.")
        hint(f"saved to: {output}")
    else:
        rio("ffmpeg failed. did you type a valid timestamp?")
        sys.exit(1)
    print()

if __name__ == "__main__":
    main()
