#!/usr/bin/env bash
set -euo pipefail

link() {
  src="$1"
  dest="$2"
  sudo_flag="${3:-}"   # optional: "sudo" if we need root

  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "Backing up $dest to ${dest}.bak"
    if [ "$sudo_flag" = "sudo" ]; then
      sudo mv "$dest" "${dest}.bak"
    else
      mv "$dest" "${dest}.bak"
    fi
  fi

  if [ -L "$dest" ]; then
    echo "Removing existing symlink $dest"
    if [ "$sudo_flag" = "sudo" ]; then
      sudo rm "$dest"
    else
      rm "$dest"
    fi
  fi

  echo "Linking $dest -> $src"
  if [ "$sudo_flag" = "sudo" ]; then
    sudo ln -s "$src" "$dest"
  else
    ln -s "$src" "$dest"
  fi
}

# User-level configs
link "$HOME/dotfiles/nvim" "$HOME/.config/nvim"
link "$HOME/dotfiles/fuzzel" "$HOME/.config/fuzzel"
link "$HOME/dotfiles/hypr" "$HOME/.config/hypr"
link "$HOME/dotfiles/lazygit" "$HOME/.config/lazygit"
link "$HOME/dotfiles/zed" "$HOME/.config/zed"
link "$HOME/dotfiles/zsh/sheldon" "$HOME/.config/sheldon"
link "$HOME/dotfiles/waybar" "$HOME/.config/waybar"
link "$HOME/dotfiles/xremap" "$HOME/.config/xremap"
link "$HOME/dotfiles/swaylock" "$HOME/.config/swaylock"
link "$HOME/dotfiles/tmux" "$HOME/.config/tmux"
link "$HOME/dotfiles/sioyek" "$HOME/.config/sioyek"
link "$HOME/dotfiles/niri" "$HOME/.config/niri"
link "$HOME/dotfiles/wlr-which-key" "$HOME/.config/wlr-which-key"
link "$HOME/dotfiles/walker" "$HOME/.config/walker"
link "$HOME/dotfiles/wl-kbptr" "$HOME/.config/wl-kbptr"
link "$HOME/dotfiles/code/argv.json" "$HOME/.config/Code/argv.json"

link "$HOME/dotfiles/scripts" "$HOME/scripts"
link "$HOME/dotfiles/desktop-entry" "$HOME/.local/share/applications/desktop-entry"

link "$HOME/dotfiles/zsh/.zshrc" "$HOME/.zshrc"
link "$HOME/dotfiles/zsh/.zprofile" "$HOME/.zprofile"
