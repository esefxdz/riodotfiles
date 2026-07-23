# rio dotfiles

> She's a big girl ngl
>
> Dark. Transparent. Dystopian red. No bloat.

## Preview

#images soon go here tm

## Hardware

| Component | Spec |
|-----------|------|
| **Machine** | MS-7C56 Custom Desktop (Rio) |
| **CPU** | AMD Ryzen 7 5700X 8-Core @ 4.65 GHz |
| **GPU** | NVIDIA GeForce RTX 3060 Ti |
| **RAM** | 32 GB |
| **Display** | LG ULTRAGEAR 1920x1080 @ 144 Hz |
| **OS** | Arch Linux |

---

## Stack

| Role | Tool |
|------|------|
| **Display Manager** | ly |
| **Compositor** | Hyprland |
| **Status Bar** | Waybar |
| **Widgets** | Eww |
| **Terminal** | Alacritty |
| **Shell** | Zsh + Starship |
| **App Launcher** | Rofi (Wayland) |
| **System Monitor** | Btop |
| **File Manager** | Thunar |
| **Fonts** | JetBrainsMono Nerd Font, GohuFont |
| **Clipboard** | Cliphist |
| **Screenshot** | Grim + Swappy |
| **Boot Animation** | mpv on DRM framebuffer |

---

## Device Role

This is my main workstation (`Rio`). Built for raw performance and maximum aesthetic, im not the greatest ricer tho this ll get updated.

---

## Installation

Fresh Arch base install. No desktop, no extras. Just internet.

```bash
git clone https://github.com/esefxdz/riodotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

Don't run it as root if that wasnt obvious.

The script installs `yay` if you don't have it, pulls everything from `packages.txt`, symlinks all the configs into `~/.config/`, sets up Zsh with Oh My Zsh and the plugins, and enables `ly` as the display manager. It also installs a custom boot animation (Plymouth-style `.mp4` video on the DRM framebuffer).

`eww` comes from the AUR so it compiles from source. Give it a minute.

---

### Things you still need to do yourself

**Before rebooting** — add `nvidia_drm.modeset=1` to your bootloader's kernel params or the GPU won't cooperate with Hyprland. The boot animation also needs this for `--vo=drm`.

**Network widgets** — the Eww net scripts auto-detect your default interface via `ip route`. No manual config needed. If you have multiple interfaces and need to override, edit `~/.config/eww/scripts/net/*.sh`.

**`sensors-detect`** — the script prompts you for this. Run it, it configures lm-sensors for the hardware panel in Eww. Takes about a minute.

---

## Notes

- The `scripts/` folder is on PATH. `compressvid`, `trimvid`, and ffmpeg wrappers live here.
- The NVIDIA env vars (`GBM_BACKEND`, `LIBVA_DRIVER_NAME`, etc.) are already in `hyprland.conf`. Don't touch them unless you know what you're doing.
- Several packages come from the AUR: `eww`, `mpvpaper`, `gohufont`, `lazydocker`, `hyprpicker`, and others. `yay` handles them automatically.
- thx 1k2s pewds and elars
