# History Configuration
HISTFILE=~/.zsh_history    # Location of the history file
HISTSIZE=100000            # Maximum lines kept in internal memory
SAVEHIST=100000            # Maximum lines saved to the history file
HISTFILESIZE=1000000       # Maximum lines the history file can grow to

# History Options
setopt SHARE_HISTORY         # Share history across all sessions
setopt INC_APPEND_HISTORY    # Write to the history file immediately
setopt EXTENDED_HISTORY      # Write the history file in the ":start:elapsed;command" format
setopt APPEND_HISTORY        # Append to history file, don't overwrite it

# Duplicate Management
setopt HIST_IGNORE_DUPS      # Don't record an entry that was just recorded again
setopt HIST_IGNORE_ALL_DUPS  # Delete old recorded entry if new entry is a duplicate
setopt HIST_SAVE_NO_DUPS     # Don't write duplicate entries in the history file
setopt HIST_FIND_NO_DUPS     # Don't display duplicates when searching history with arrow keys
setopt HIST_IGNORE_SPACE     # Don't record an entry starting with a space
