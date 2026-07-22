#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
#  Rio Dotfiles — Installation Script
#  Arch Linux · Hyprland · NVIDIA RTX 3060 Ti · Ryzen 7 5700X
#  Run from the root of the cloned dotfiles repo.
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
ICONS_DIR="$HOME/.icons"
SCRIPTS_DIR="$CONFIG_DIR/scripts"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[1;31m'
GRN='\033[1;32m'
YEL='\033[1;33m'
CYN='\033[1;36m'
RST='\033[0m'

banner() {
  echo -e ""
  echo -e "${RED}══════════════════════════════════════════${RST}"
  echo -e "${RED}  RIO DOTFILES INSTALLER — dystopian red  ${RST}"
  echo -e "${RED}══════════════════════════════════════════${RST}"
  echo -e ""
}

info()    { echo -e "${CYN}[·]${RST} $1"; }
success() { echo -e "${GRN}[✓]${RST} $1"; }
warn()    { echo -e "${YEL}[!]${RST} $1"; }
die()     { echo -e "${RED}[✗] $1${RST}"; exit 1; }

confirm() {
  read -rp "$(echo -e "${YEL}[?]${RST} $1 [y/N] ")" ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

# ── Preflight checks ──────────────────────────────────────────────────────────
check_arch() {
  [[ -f /etc/arch-release ]] || die "This script is for Arch Linux only."
  success "Arch Linux detected."
}

check_internet() {
  ping -c1 archlinux.org &>/dev/null || die "No internet connection."
  success "Internet connection verified."
}

check_not_root() {
  [[ "$EUID" -ne 0 ]] || die "Do NOT run this as root. Run as your regular user."
}

# ── AUR helper ────────────────────────────────────────────────────────────────
install_aur_helper() {
  if command -v yay &>/dev/null; then
    success "yay already installed."
    AUR=yay
  elif command -v paru &>/dev/null; then
    success "paru already installed."
    AUR=paru
  else
    info "Installing yay (AUR helper)..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
    rm -rf /tmp/yay
    AUR=yay
    success "yay installed."
  fi
}

# ── Package install ───────────────────────────────────────────────────────────
install_packages() {
  info "Installing packages from packages.txt..."
  # Strip comments and blank lines
  PACKAGES=$(grep -v '^\s*#' "$DOTFILES_DIR/packages.txt" | grep -v '^\s*$' | awk '{print $1}')
  # shellcheck disable=SC2086
  $AUR -S --needed --noconfirm $PACKAGES
  success "All packages installed."
}

# ── Python deps (textual for paladin) ────────────────────────────────────────
install_python_deps() {
  info "Installing Python dependencies..."
  # pip install --user --break-system-packages textual  # needed only if paladin is present
  success "Python deps skipped (nothing to install)."
}

# ── Stow configs ──────────────────────────────────────────────────────────────
link_configs() {
  info "Linking configs into $CONFIG_DIR..."
  mkdir -p "$CONFIG_DIR"

  # Directories to link — each folder name matches the app config name
  DIRS=(
    alacritty
    btop
    cava
    eww
    fastfetch
    ffmpeg_tools
    gtk
    hypr
    lazydocker
    lazygit
    mangohud
    rofi
    scripts
    swaync
    thunar
    waybar
    zellij
  )

  for dir in "${DIRS[@]}"; do
    SRC="$DOTFILES_DIR/$dir"
    DEST="$CONFIG_DIR/$dir"
    if [[ -d "$SRC" ]]; then
      if [[ -d "$DEST" ]] && ! [[ -L "$DEST" ]]; then
        warn "$DEST already exists. Backing up to $DEST.bak"
        mv "$DEST" "$DEST.bak"
      fi
      ln -sfn "$SRC" "$DEST"
      success "Linked: $dir → $CONFIG_DIR/$dir"
    else
      warn "Source not found, skipping: $dir"
    fi
  done
}

# ── Cursor theme ──────────────────────────────────────────────────────────────
install_cursor() {
  info "Installing mycursor theme..."
  mkdir -p "$ICONS_DIR"
  if [[ -d "$DOTFILES_DIR/mycursor" ]]; then
    cp -r "$DOTFILES_DIR/mycursor" "$ICONS_DIR/mycursor"
    # Also set as system default
    mkdir -p "$HOME/.local/share/icons"
    ln -sfn "$ICONS_DIR/mycursor" "$HOME/.local/share/icons/mycursor"
    success "Cursor installed to $ICONS_DIR/mycursor"
  else
    warn "mycursor directory not found in dotfiles. Skipping cursor install."
  fi
}

# ── Zsh as default shell ──────────────────────────────────────────────────────
set_shell() {
  if [[ "$SHELL" != "$(which zsh)" ]]; then
    info "Setting Zsh as default shell..."
    chsh -s "$(which zsh)"
    success "Default shell set to Zsh. Takes effect on next login."
  else
    success "Zsh is already the default shell."
  fi
}

# ── Oh My Zsh ─────────────────────────────────────────────────────────────────
install_omz() {
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    info "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    success "Oh My Zsh installed."
  else
    success "Oh My Zsh already installed."
  fi

  # Plugins
  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions \
      "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    success "zsh-autosuggestions installed."
  fi

  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting \
      "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    success "zsh-syntax-highlighting installed."
  fi
}

# ── Symlink .zshrc ────────────────────────────────────────────────────────────
link_zshrc() {
  info "Linking .zshrc..."
  if [[ -f "$HOME/.zshrc" ]] && ! [[ -L "$HOME/.zshrc" ]]; then
    warn "Backing up existing .zshrc to ~/.zshrc.bak"
    mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
  fi
  ln -sfn "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
  success "Linked .zshrc"
}

# ── Scripts ───────────────────────────────────────────────────────────────────
setup_scripts() {
  info "Making scripts executable..."
  chmod +x "$SCRIPTS_DIR/mp4togif"          2>/dev/null || true
  chmod +x "$SCRIPTS_DIR/webmtogif"         2>/dev/null || true
  chmod +x "$SCRIPTS_DIR/webmtopng"         2>/dev/null || true
  chmod +x "$SCRIPTS_DIR/webmtojpg"         2>/dev/null || true
  chmod +x "$SCRIPTS_DIR/compressvid"       2>/dev/null || true
  chmod +x "$SCRIPTS_DIR/trimvid"           2>/dev/null || true
  chmod +x "$SCRIPTS_DIR/zapret"            2>/dev/null || true
  chmod +x "$SCRIPTS_DIR/nozapret"          2>/dev/null || true
  chmod +x "$DOTFILES_DIR/zapret/install.sh"   2>/dev/null || true
  chmod +x "$DOTFILES_DIR/zapret/uninstall.sh" 2>/dev/null || true
  chmod +x "$CONFIG_DIR/hypr/scripts/"*.sh  2>/dev/null || true
  shopt -s globstar 2>/dev/null || true
  chmod +x "$CONFIG_DIR/eww/scripts/"**/*.sh 2>/dev/null || true
  chmod +x "$CONFIG_DIR/eww/scripts/"**/*.py 2>/dev/null || true
  shopt -u globstar 2>/dev/null || true
  success "Scripts are executable."
}


# ── qBittorrent themes ────────────────────────────────────────────────────────
setup_qbittorrent() {
  QB_THEME_SRC="$DOTFILES_DIR/qbittorremnt/themes/custom"
  QB_THEME_DEST="$HOME/.local/share/qBittorrent/themes"

  if [[ -d "$QB_THEME_SRC" ]]; then
    info "Installing qBittorrent themes..."
    mkdir -p "$QB_THEME_DEST"
    cp -r "$QB_THEME_SRC/"*.qbtheme "$QB_THEME_DEST/"
    success "qBittorrent themes installed to $QB_THEME_DEST"
    warn "Activate in qBittorrent: Tools → Preferences → Behavior → Use custom UI theme → pick DarkRed.qbtheme"
  else
    warn "qBittorrent themes not found, skipping."
  fi
}

# ── GitHub Auth ───────────────────────────────────────────────────────────────
setup_github() {
  info "Installing GitHub CLI and Git LFS..."
  sudo pacman -S --needed --noconfirm git-lfs github-cli
  git lfs install

  info "Authenticating with GitHub (needed for private wallpapers)..."
  if gh auth status &>/dev/null; then
    success "Already logged into GitHub."
  else
    echo -e "Follow the prompts below to authenticate (select HTTPS, then login via web browser):\n"
    gh auth login
    if gh auth status &>/dev/null; then
      success "Successfully authenticated with GitHub."
    else
      warn "GitHub authentication failed. Private wallpapers will be skipped."
    fi
  fi
}

# ── Wallpapers (Private Repo) ─────────────────────────────────────────────────
fetch_wallpapers() {
  local wallpaper_dir="$CONFIG_DIR/hypr/wallpapers"
  local wallpaper_repo="esefxdz/riowallpapers"

  if [[ -d "$wallpaper_dir" ]] && [[ -n "$(ls -A "$wallpaper_dir" 2>/dev/null)" ]]; then
    warn "Wallpapers already exist at $wallpaper_dir. Skipping."
    return
  fi

  info "Setting up private wallpapers repository..."

  if gh auth status &>/dev/null; then
    info "Cloning private wallpapers..."
    GIT_LFS_SKIP_SMUDGE=0 gh repo clone "$wallpaper_repo" "$wallpaper_dir"
    success "Private wallpapers downloaded."
  else
    warn "Not logged into GitHub. Creating fallback wallpaper..."
    mkdir -p "$wallpaper_dir"
    # Generate a solid black 1920x1080 PNG as fallback
    if command -v ffmpeg &>/dev/null; then
      ffmpeg -y -f lavfi -i color=c=0x0c0c0c:s=1920x1080:d=1 -frames:v 1 "$wallpaper_dir/black.png" &>/dev/null
      success "Fallback black.png created."
    else
      warn "ffmpeg not available — no wallpaper fallback."
    fi
  fi
}

# ── ly Display Manager ─────────────────────────────────────────────────────
setup_ly() {
  info "Setting up ly display manager..."
  sudo systemctl enable ly

  # Copy ly config
  if [[ -f "$DOTFILES_DIR/ly/config.ini" ]]; then
    sudo cp "$DOTFILES_DIR/ly/config.ini" /etc/ly/config.ini
    success "ly config applied."
  fi

  success "ly enabled — TUI login on next boot."
}

# ── lm-sensors ────────────────────────────────────────────────────────────────
setup_sensors() {
  if confirm "Run sensors-detect now? (required for Eww hardware widgets — needs root)"; then
    sudo sensors-detect --auto
    success "Sensors configured."
  else
    warn "Skipped sensors-detect. Run 'sudo sensors-detect' manually before using the Eww hardware panel."
  fi
}

# ── Hyprland NVIDIA Env Check ─────────────────────────────────────────────────
nvidia_reminder() {
  echo ""
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
  echo -e "${RED}  NVIDIA REMINDER                              ${RST}"
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
  echo -e "  ${YEL}Make sure 'nvidia_drm.modeset=1' is set${RST}"
  echo -e "  in your bootloader kernel params."
  echo -e ""
  echo -e "  The hyprland.conf is already pre-configured with"
  echo -e "  GBM_BACKEND, LIBVA_DRIVER_NAME, NVD_BACKEND, etc."
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
  echo ""
}

# ── Done ──────────────────────────────────────────────────────────────────────
finish() {
  echo ""
  echo -e "${RED}══════════════════════════════════════════${RST}"
  echo -e "${GRN}  Installation complete. Welcome to Rio.  ${RST}"
  echo -e "${RED}══════════════════════════════════════════${RST}"
  echo ""
  echo -e "  Next steps:"
  echo -e "  ${CYN}1.${RST} Reboot — ly will greet you, then Hyprland"
  echo -e "  ${CYN}2.${RST} Check NVIDIA kernel param (see above)"
  echo -e "  ${CYN}3.${RST} Run 'sudo sensors-detect' if you skipped it"
  echo -e "  ${CYN}4.${RST} Edit ~/config/eww/scripts/net/*.sh"
  echo -e "     and set your network interface name"
  echo -e ""
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  banner
  check_not_root
  check_arch
  check_internet

  setup_github
  install_aur_helper
  install_packages
  install_python_deps
  link_configs
  install_cursor
  install_omz
  link_zshrc
  set_shell
  setup_scripts
  setup_qbittorrent
  fetch_wallpapers
  setup_ly
  setup_sensors
  nvidia_reminder
  finish
}

main "$@"
