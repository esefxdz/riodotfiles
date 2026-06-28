# ==================
#  Basic Paths & Tools
# ==================
export PATH="$HOME/.local/bin:$PATH"

# Pyenv (optional, only if installed)
if command -v pyenv >/dev/null 2>&1; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

# NVM (Node Version Manager)
if [[ -d "$HOME/.nvm" ]]; then
  export NVM_DIR="$HOME/.nvm"
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
fi

# ==================
# Oh My Zsh & Plugins
# ==================
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  export ZSH="$HOME/.oh-my-zsh"
  source "$ZSH/oh-my-zsh.sh"
fi

[[ -f "$HOME/.zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh" ]] && \
  source "$HOME/.zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh"

[[ -f "$HOME/.zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh" ]] && \
  source "$HOME/.zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh"

# ==================
# User's Config (zshrcyuuka)
# ==================
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

# FZF
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'

# eza
alias ls='eza --icons --group-directories-first'
alias ll='eza -lah --icons --group-directories-first'
alias la='eza -a --icons --group-directories-first'
alias lt='eza --tree --level=2 --icons'

# zoxide
alias cd='z'

# utils
alias cat='bat'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -h'
alias free='free -h'

# safety
alias cp='cp -i'
alias mv='mv -i'
alias rm='trash-put'

# system
alias sysinfo='fastfetch'
alias monitor='btop'
alias ports='sudo netstat -tulpn'
alias myip='curl ifconfig.me'

# navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'

# extract helper
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2)  tar xjf "$1"    ;;
      *.tar.gz)   tar xzf "$1"    ;;
      *.bz2)      bunzip2 "$1"    ;;
      *.rar)      unrar e "$1"    ;;
      *.gz)       gunzip "$1"     ;;
      *.tar)      tar xf "$1"     ;;
      *.tbz2)     tar xjf "$1"    ;;
      *.tgz)      tar xzf "$1"    ;;
      *.zip)      unzip "$1"      ;;
      *.Z)        uncompress "$1" ;;
      *.7z)       7z x "$1"       ;;
      *)          echo "'$1' can't be extracted" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# git
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'

# history
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# completion
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
setopt AUTO_CD

#fetch
if [[ -n $PS1 ]]; then
  fastfetch
fi

# ── PATH ──────────────────────────────────────────────────────────────────────
export PATH="$HOME/.config/scripts:$PATH"

# ── Dev Tools ─────────────────────────────────────────────────────────────────
alias zj='zellij'                           # terminal multiplexer
alias lg='lazygit'                           # git TUI
alias lzd='lazydocker'                       # docker TUI

# zellij needs TERM to be set correctly inside alacritty
export TERM=xterm-256color

# ── Custom commands ───────────────────────────────────────────────────────────
bedtime() {
  bash "$HOME/.config/hypr/scripts/bedtime.sh"
}

togglestats() {
  bash "$HOME/.config/hypr/scripts/togglestats.sh"
}
