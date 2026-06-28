#!/usr/bin/env python3
"""
trimvid.py — Rio's ffmpeg tools
Drag and drop a video. Pick a start and end time. 
Instantly trims the video without re-encoding (lossless).
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
    print()
    print(f"  {RED}┌─ video trimmer (instant) ────────────────────────────┐{RESET}")
    print(f"  {RED}│{RESET}  {WHITE}drop video, pick start and end, get it cut{RESET}         {RED}│{RESET}")
    print(f"  {RED}└──────────────────────────────────────────────────────┘{RESET}")
    print()
    rio(f"let's cut out the boring parts. drop the video here.")
    print()

    # 1. Get file
    try:
        raw = input(f"  {DIM}drop here »{RESET} ").strip()
    except KeyboardInterrupt:
        print("\n  rio » aborting.")
        sys.exit(0)

    path = raw.strip("'\"").replace("file://", "").strip()
    path = bytes(path, "utf-8").decode("unicode_escape") if "\\" in path else path
    print()

    if not path or not os.path.isfile(path):
        rio("can't find that file. try again.")
        sys.exit(1)

    # 2. Get Start Time
    rio("when does the good part start?")
    hint("format: seconds (e.g. 15) or hh:mm:ss (e.g. 00:01:23)")
    print()
    
    while True:
        try:
            start_time = input(f"  {DIM}start time »{RESET} ").strip()
        except KeyboardInterrupt:
            print("\n  rio » aborting.")
            sys.exit(0)
            
        if not start_time:
            rio("you need to type a start time. even if it's 0.")
        else:
            break
            
    print()

    # 3. Get End Time
    rio("when does it end?")
    hint("type the end timestamp, same format as before.")
    print()
    
    while True:
        try:
            end_time = input(f"  {DIM}end time »{RESET} ").strip()
        except KeyboardInterrupt:
            print("\n  rio » aborting.")
            sys.exit(0)
            
        if not end_time:
            rio("you need to type an end time.")
        else:
            break

    print()

    ext = os.path.splitext(path)[1]
    output = os.path.splitext(path)[0] + f"_trimmed{ext}"
    name = os.path.basename(path)

    rio(f"cutting {WHITE}{name}{RESET} from {WHITE}{start_time}{RESET} to {WHITE}{end_time}{RESET}...")
    hint("this is a raw copy, so it will be instant and lose zero quality.")
    print()

    # -ss before -i seeks very fast. -to after -i stops writing at that time.
    # -c copy means NO re-encoding. It just copies the video/audio streams instantly.
    cmd = [
        "ffmpeg", "-y", 
        "-ss", start_time, 
        "-i", path, 
        "-to", end_time, 
        "-c", "copy", 
        "-loglevel", "error", 
        output
    ]

    subprocess.run(cmd)

    if os.path.exists(output):
        rio(f"done. cut perfectly.")
        hint(f"saved to: {output}")
    else:
        rio("ffmpeg failed. did you type the timestamps correctly?")
        sys.exit(1)
    print()

if __name__ == "__main__":
    main()
