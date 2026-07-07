this directory holds my custom scripts and launchers. it's added to PATH in zshrc so i can run them from anywhere.

### video stuff (ffmpeg wrappers)
all these tools are interactive. just type the command, press enter, and drag-and-drop the video file into the terminal when it asks.

* `mp4togif` (or `webmtogif`): drops out a high quality gif.
* `webmtopng` (or `webmtojpg`): extracts a thumbnail. hit enter for the very first frame, or type a timestamp like `00:01:23` to snap exactly there.
* `compressvid`: squishes a fat video. it asks for a target size (like `9.9` or `25`) and uses 2 passes to perfectly hit that limit without going over. good for discord.
* `trimvid`: instant cut. type start time, type end time. doesn't re-encode anything so it takes zero seconds and loses no quality.

### other
* `paladin`: workspace management stuff
* `yuuka`: ssh into yuuka (100kg calculator wife)

### zapret (discord unblock)
* `zapret`: installs zapret + encrypted DNS. bypasses erdogan's DPI. discord works after this.
* `nozapret`: uninstalls everything, restores DNS to default.

both need root (they'll sudo themselves). pass `--debug` to see full output.