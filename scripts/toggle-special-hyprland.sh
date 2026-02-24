#!/usr/bin/env bash

# Usage:
#   ./toggle_special_ws.sh <APP_CLASS> <SPECIAL_WS> [COMMAND...]
# Example:
#   ./toggle_special_ws.sh kitty notes
#   ./toggle_special_ws.sh obsidian obsidian "obsidian --disable-gpu"
#   ./toggle_special_ws.sh firefox research "firefox --new-window"

# Parse arguments
APP_CLASS="$1"
SPECIAL_WS="$2"
shift 2
CMD="${*:-$APP_CLASS}"  # If no command is given, just use APP_CLASS

if [[ -z "$APP_CLASS" || -z "$SPECIAL_WS" ]]; then
    echo "Usage: $0 <APP_CLASS> <SPECIAL_WS> [COMMAND...]"
    exit 1
fi

# Check if the app is already in the special workspace
if hyprctl clients -j | jq -e --arg APP_CLASS "$APP_CLASS" --arg SPECIAL_WS "$SPECIAL_WS" '
    .[] | select(.class == $APP_CLASS and .workspace.name == "special:" + $SPECIAL_WS)
' >/dev/null; then
    # Already running there → toggle it
    hyprctl dispatch togglespecialworkspace "$SPECIAL_WS"
else
    # Not running → spawn in special ws, then toggle to show
    hyprctl dispatch exec "[workspace special:$SPECIAL_WS silent] $CMD"
    
    # Wait until the app appears or timeout after 3 seconds
    for _ in {1..30}; do
        if hyprctl clients -j | jq -e --arg APP_CLASS "$APP_CLASS" --arg SPECIAL_WS "$SPECIAL_WS" '
            .[] | select(.class == $APP_CLASS and .workspace.name == "special:" + $SPECIAL_WS)
        ' >/dev/null; then
            break
        fi
        sleep 0.1
    done
    
    hyprctl dispatch togglespecialworkspace "$SPECIAL_WS"
fi
