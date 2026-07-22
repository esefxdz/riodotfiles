# Repository Guidelines

## Project Structure

Each top-level directory maps to an application config under `~/.config/`, except where noted.

```
riodotfiles/
├── alacritty/        # Terminal emulator (alacritty.toml)
├── boot-animation/   # Plymouth-style boot video + systemd service
├── btop/             # System monitor TUI (btop.conf + themes/)
├── cava/             # Audio visualizer (config + shaders/)
├── eww/              # Widget framework (eww.yuck, eww.scss, scripts/)
├── fastfetch/        # System info fetch (config.jsonc)
├── ffmpeg_tools/     # Video conversion helpers (optional)
├── gtk/              # GTK 3.0 & 4.0 settings (dark theme, fonts, icons)
├── hypr/             # Hyprland config, scripts, wallpapers, shaders
├── lazydocker/       # Docker TUI config
├── lazygit/          # Git TUI config
├── ly/               # ly display manager theme (config.ini)
├── mangohud/         # Performance overlay (MangoHud.conf)
├── rofi/             # App launcher (config.rasi, theme.rasi)
├── scripts/          # Custom scripts added to PATH (ffmpeg wrappers, zapret)
├── sddm/             # SDDM theme (backup; ly is the active DM)
├── swaync/           # Notification daemon (config.json, style.css)
├── waybar/           # Status bar (config, style.css, scripts/)
├── zellij/           # Terminal multiplexer (config.kdl)
├── zsh/              # Shell config (.zshrc, bedtime helper)
├── install.sh        # Full system bootstrap script
├── packages.txt      # Pacman/AUR package manifest
└── README.md
```

## Installation & Setup

The repo is designed for a fresh Arch Linux base install.

```bash
git clone https://github.com/esefxdz/riodotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

The script installs `yay` (AUR helper), pulls all packages from `packages.txt`, symlinks configs into `~/.config/`, sets up Zsh with Oh My Zsh, and enables `ly` as the display manager. Do **not** run it as root.

## Adding a New Config

1. Create a directory at the repo root named after the application (e.g., `newsboat/`).
2. Place the config file(s) inside, mirroring the `~/.config/<app>/` layout.
3. Add the directory name to the `DIRS` array in `install.sh` under `link_configs()`.
4. If it requires packages, add them to `packages.txt` with a comment.
5. If it needs post-install steps (systemd units, one-time setup), add a `setup_<name>()` function in `install.sh` and call it from `main()`.

## Config Conventions

- **Colors** — Background `#0C0C0C`, primary red `#D12424`, accent red `#FF2A2A`, foreground `#CCCCCC`. Keep the dystopian red theme consistent.
- **Fonts** — `JetBrainsMono Nerd Font` at 13px for UI elements, 14px for Waybar. GohuFont for terminal (Alacritty). Do not use bitmap fonts in Eww/GTK — they break at non-native sizes.
- **File headers** — Use the existing comment style: a boxed header with app name and version.
- **Scripts** — Shebang with `#!/usr/bin/env bash`, `set -euo pipefail` for safety.

## Commit Guidelines

- Prefix with `fix:` for bug fixes, `add:` for new features, or a short action phrase (`switch`, `bump`, `remove`).
- Keep messages lowercase, under 72 characters.
- One logical change per commit — avoid bundling unrelated edits.

## Testing

There is no CI. Test manually:

1. Spin up an Arch VM (VMware, VirtualBox, or QEMU).
2. Run `archinstall` with the `minimal` profile.
3. Clone the repo and run `bash install.sh`.
4. Launch Hyprland and verify all configs load without errors.
5. Check `journalctl -xe` for any service failures.
