autoload -Uz compinit
compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select


eval "$(zoxide init zsh --cmd cd)"

DOTFILES="$HOME/dotfiles"
source $DOTFILES/zsh/history-settings.zsh
source $DOTFILES/zsh/plugins-settings.zsh

alias syndot='$DOTFILES/install.sh'
alias zen-browser='flatpak run app.zen_browser.zen'
alias n='nvim'
alias nn='nvim .'
alias lg='lazygit'
alias lzd='lazydocker'
alias zen-browser='flatpak run app.zen_browser.zen'
alias c='clear'

alias -g H='| head'
alias -g L='| less'
alias -g G='| grep'
alias -g F='| fzf'
alias -g W='| wc -l'
alias -g J='| jq .'
alias -g T="| tr -d '\n' "
alias -g C="| wl-copy"
