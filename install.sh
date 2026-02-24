#!/usr/bin/env bash
set -euo pipefail

link() {
  src="$1"
  dest="$2"

  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "Backing up $dest to ${dest}.bak"
    mv "$dest" "${dest}.bak"
  fi

  if [ -L "$dest" ]; then
    echo "Removing existing symlink $dest"
    rm "$dest"
  fi

  echo "Linking $dest -> $src"
  ln -s "$src" "$dest"
}

link "$HOME/dotfiles/nvim" "$HOME/.config/nvim"
link "$HOME/dotfiles/hypr" "$HOME/.config/hypr"
link "$HOME/dotfiles/lazygit" "$HOME/.config/lazygit"
link "$HOME/dotfiles/zed" "$HOME/.config/zed"
link "$HOME/dotfiles/scripts" "$HOME/scripts"
link "$HOME/zsh/.zshrc" "$HOME/.zshrc"