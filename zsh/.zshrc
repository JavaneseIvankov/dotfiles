autoload -Uz compinit
compinit

eval "$(sheldon source)"
eval "$(zoxide init zsh --cmd cd)"

DOTFILES="$HOME/dotfiles"
source $DOTFILES/zsh/history-settings.zsh

alias syndot='$DOTFILES/install.sh'
alias zen-browser='flatpak run app.zen_browser.zen'
alias n='nvim'
alias nn='nvim .'
alias lg='lazygit'
alias lg='lazydocker'
alias zen-browser='flatpak run app.zen_browser.zen'

# plugins related config
eval "$(sheldon completions --shell zsh)"
bindkey '^f' autosuggest-accept
bindkey '^r' fzf-history-widget
ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
