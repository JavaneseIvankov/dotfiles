
# for fixing zvm fzf integration issue 
# https://github.com/jeffreytse/zsh-vi-mode/issues/24 
ZVM_INIT_MODE=sourcing
ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
YSU_MESSAGE_POSITION="after"

eval "$(sheldon source)"

eval "$(sheldon completions --shell zsh)"
bindkey '^f' autosuggest-accept
bindkey '^r' fzf-history-widget