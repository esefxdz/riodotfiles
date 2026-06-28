#!/usr/bin/env python3
"""
compress_video.py — Rio's ffmpeg tools
Drag and drop an mp4 into the terminal. Pick a target size. Compress it precisely.
Uses 2-pass encoding to accurately hit the target file size.
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
def get_duration(path):
    cmd = [
        "ffprobe", "-v", "error", "-show_entries",
        "format=duration", "-of",
        "default=noprint_wrappers=1:nokey=1", path
    ]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return float(result.stdout.strip())
    except (subprocess.CalledProcessError, ValueError):
        return None

def main():
    print()
    print(f"  {RED}┌─ video compressor ───────────────────────────────────┐{RESET}")
    print(f"  {RED}│{RESET}  {WHITE}drop your fat video file in here{RESET}                   {RED}│{RESET}")
    print(f"  {RED}└──────────────────────────────────────────────────────┘{RESET}")
    print()
    rio(f"file too big? drop it here and tell me how small to make it.")
    print()

    # 1. Get file
    try:
        raw = input(f"  {DIM}drop file here »{RESET} ").strip()
    except KeyboardInterrupt:
        print()
        rio("ok, suit yourself.")
        sys.exit(0)

    path = raw.strip("'\"").replace("file://", "").strip()
    path = bytes(path, "utf-8").decode("unicode_escape") if "\\" in path else path
    print()

    if not path or not os.path.isfile(path):
        rio(f"i can't find that file. did you drag it correctly?")
        sys.exit(1)

    duration = get_duration(path)
    if not duration:
        rio("i couldn't read how long this video is. is it corrupted?")
        sys.exit(1)

    # 2. Get target size
    rio("how many megabytes do you want to compress this to?")
    hint("type the exact number (e.g., 9.9 or 25)")
    print()
    
    while True:
        try:
            size_input = input(f"  {DIM}target size (MB) »{RESET} ").strip()
        except KeyboardInterrupt:
            print()
            rio("aborting. maybe next time.")
            sys.exit(0)
            
        if not size_input:
            rio("you have to actually type a number.")
            continue
            
        try:
            target_size_mb = float(size_input)
            if target_size_mb <= 0:
                rio("nice try. give me a number bigger than zero.")
                continue
            break
        except ValueError:
            rio("that's not a number. try again.")

    print()

    # Calculate bitrates based strictly on what they typed
    target_size_kb = target_size_mb * 8192 # Megabytes to kilobits

    # Calculate bitrates
    total_bitrate = target_size_kb / duration
    audio_bitrate = 96 # 96 kbps for audio
    video_bitrate = total_bitrate - audio_bitrate

    if video_bitrate < 50:
        rio(f"this video is {duration / 60:.1f} minutes long...")
        rio(f"squishing it to {target_size_mb}MB is going to look like pixelated garbage.")
        hint("but i'll do it anyway. don't complain.")
        print()
        video_bitrate = 50 # floor it to absolute minimum 

    output = os.path.splitext(path)[0] + f"_{target_size_mb}mb.mp4"
    name = os.path.basename(path)

    rio(f"crushing {WHITE}{name}{RESET} to hit {target_size_mb}MB. this requires 2 passes.")
    rio("this might take a minute, so sit tight.")
    hint(f"target video bitrate: {int(video_bitrate)}k")
    print()

    # Pass 1
    hint("running pass 1 (analysis)...")
    cmd_pass1 = [
        "ffmpeg", "-y", "-i", path,
        "-c:v", "libx264", "-b:v", f"{video_bitrate}k",
        "-pass", "1", "-an", "-f", "mp4",
        "-loglevel", "error", "-stats",
        os.devnull if os.name == 'nt' else '/dev/null'
    ]
    subprocess.run(cmd_pass1)

    # Pass 2
    hint("running pass 2 (encoding)...")
    cmd_pass2 = [
        "ffmpeg", "-y", "-i", path,
        "-c:v", "libx264", "-b:v", f"{video_bitrate}k",
        "-pass", "2",
        "-c:a", "aac", "-b:a", f"{audio_bitrate}k",
        "-loglevel", "error", "-stats",
        output
    ]
    subprocess.run(cmd_pass2)

    # Clean up ffmpeg pass log files
    for ext in ("-0.log", "-0.log.mbtree"):
        if os.path.exists("ffmpeg2pass" + ext):
            os.remove("ffmpeg2pass" + ext)

    print("\n")
    if os.path.exists(output):
        final_size_mb = os.path.getsize(output) / (1024 * 1024)
        rio(f"done. it's {WHITE}{final_size_mb:.2f} MB{RESET}. should fit perfectly.")
        hint(f"saved to: {output}")
        print()
        rio("there. now you can go post it wherever.")
    else:
        rio("something broke during encoding. deal with it yourself.")
        sys.exit(1)
    print()

if __name__ == "__main__":
    main()
