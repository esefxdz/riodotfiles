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
| **Display Manager** | SDDM |
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

---

## Device Role

This is my main workstation (`Rio`). Built for raw performance and maximum aesthetic, im not the greatest ricer tho this ll get updated.

---

## Installation

Fresh Arch base install. No desktop, no extras. Just internet.

```bash
git clone https://github.com/yourusername/riodotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

Don't run it as root if that wasnt obvious.

The script installs `yay` if you don't have it, pulls everything from `packages.txt`, symlinks all the configs into `~/.config/`, drops the cursor into `~/.icons/`, sets up Zsh with Oh My Zsh and the plugins, and enables SDDM. It'll ask you once whether you want Hivemind running as a background service — say yes, that's the right choice.

`eww` comes from the AUR so it compiles from source. Give it a minute.

---

### Things you still need to do yourself

**Before rebooting** — add `nvidia_drm.modeset=1` to your kernel params or the GPU won't cooperate with Hyprland:

```bash
# /etc/default/grub
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nvidia_drm.modeset=1"
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

**After you're in** — the Eww network widgets are hardcoded to `wlp4s0`. Check your interface name and fix it:

```bash
ip link
# then edit ~/.config/eww/scripts/net/*.sh
```

NOTES FOR ME INCASE BRAINFART
**`yuuka`** is the SSH shortcut to the laptop. It's set to `192.168.1.108`. If that IP ever changes, edit `~/.config/scripts/yuuka`.

**`sensors-detect`** — the script prompts you for this. Run it, it configures lm-sensors for the hardware panel in Eww. Takes about a minute.

---

## Notes

- The `scripts/` folder is on PATH. `paladin` monitors Hivemind, `yuuka` SSHs into the laptop.
- Cursor is `XsX - Alpha Blended with Shadows`, renamed to `mycursor` internally.
- The NVIDIA env vars (`GBM_BACKEND`, `LIBVA_DRIVER_NAME`, etc.) are already in `hyprland.conf`. Don't touch them unless you know what you're doing.
- Workspace 9 has Firefox preloaded silently on boot. Don't close it or you lose the instant-load trick.
- Throughout installation only 5 packages are pulled from the AUR. eww, mpvpaper, lazydocker, python-textual, hyprpicker. As of now these are not malware but you need to check that for yourself.
- thx 1k2s pewds and elars
- cargo install chess-tui and type chess on terminal for funny
