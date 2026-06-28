# Rio's FFmpeg Tools

I will store my python ffmpeg scripts here for basic video editing.

## Available Scripts

### `mp4togif` (and `webmtogif`)
Converts an `.mp4` (or mov, mkv, webm, avi) file to a high-quality GIF using lanczos scaling and palette generation.

**Usage:** Just type `mp4togif` or `webmtogif` in your terminal. It will prompt you to drag and drop your video file.

### `webmtopng` and `webmtojpg`
Extracts a single frame from a video as a high-quality thumbnail image. 

**Usage:** Just type `webmtopng` or `webmtojpg` in your terminal. It asks you to drop your video, and then asks if you want the first frame (just hit Enter) or a specific timestamp (e.g., `00:01:23`).

### `compressvid`
Compresses any fat video file to fit under a specific file size limit (default 10MB, but asks you how much). Uses `ffprobe` to calculate the required bitrate based on video length, and runs a 2-pass encoding for maximum quality at that tiny size.

**Usage:** Just type `compressvid` in your terminal. It will prompt you to drag and drop your video file and ask for a target size in MB.

### `trimvid`
Instantly cuts a chunk out of a video using a start and end timestamp. It uses `-c copy` to copy the video streams rather than re-encoding, meaning it takes literally 0.1 seconds to process and loses absolutely zero quality.

**Usage:** Just type `trimvid` in your terminal. It will ask for the video, the start time, and the end time.

*Note: Requires `ffmpeg` to be installed (added to `packages.txt`).*