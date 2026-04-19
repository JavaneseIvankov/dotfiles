autoload -Uz compinit
compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select


eval "$(zoxide init zsh --cmd cd)"

DOTFILES="$HOME/dotfiles"
source $DOTFILES/zsh/history-settings.zsh
source $DOTFILES/zsh/plugins-settings.zsh

alias syndot='$DOTFILES/install.sh'
alias n='nvim'
alias nn='nvim .'
alias lg='lazygit'
alias lzd='lazydocker'
alias pn='pnpm'

alias -g H='| head'
alias -g L='| less'
alias -g G='| grep'
alias -g F='| fzf'
alias -g W='| wc -l'
alias -g J='| jq .'
alias -g T="| tr -d '\n' "
alias -g C="| wl-copy"

hash -d code='/home/arundaya/Documents/Workspace/Code_Stuff'
hash -d coll='/home/arundaya/Documents/College\ Docs'
hash -d dl='/home/arundaya/Downloads'
