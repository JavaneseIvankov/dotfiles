# .zprofile

# User specific environment and startup programs
export XDG_CONFIG_HOME="$HOME/.config"
export PNPM_HOME="/home/arundaya/.local/share/pnpm"
export PATH="$HOME/.local/bin:$PNPM_HOME:$PATH"

# opencode
export PATH=/home/arundaya/.opencode/bin:$PATH
export PATH=/home/arundaya/go:$PATH

export EDITOR=/usr/bin/nvim
export VISUAL=/usr/bin/code


# Added by Antigravity CLI installer
export PATH="/home/arundaya/.local/bin:$PATH"



# QODER_DISPATCHER_PATH v1
path=("$HOME/.qoder/entry" ${path:#"$HOME/.qoder/entry"})
export PATH
# END QODER_DISPATCHER_PATH v1
