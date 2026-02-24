#!/usr/bin/env bash

set -euo pipefail

ALIAS_FILE="$HOME/.cache/hypr-window-aliases"
mkdir -p "$(dirname "$ALIAS_FILE")"
touch "$ALIAS_FILE"

# -------------------------------
# Map class → icon name (external)
# -------------------------------
get_desktop_name() {
    /home/arundaya/scripts/get_desktop_name.sh "$1"
}

# -------------------------------
# Cleanup stale aliases
# -------------------------------
active_addrs="$(hyprctl clients -j | jq -r '.[].address')"

tmpfile="$(mktemp)"
while IFS='|' read -r addr alias; do
    if echo "$active_addrs" | grep -qx "$addr"; then
        echo "$addr|$alias" >> "$tmpfile"
    fi
done < "$ALIAS_FILE"

mv "$tmpfile" "$ALIAS_FILE"

# -------------------------------
# Load aliases into memory
# -------------------------------
declare -A aliases

while IFS='|' read -r addr alias; do
    [ -n "${addr:-}" ] && aliases["$addr"]="$alias"
done < "$ALIAS_FILE"

# -------------------------------
# Get active window
# -------------------------------
current_addr="$(hyprctl activewindow -j | jq -r '.address')"

# -------------------------------
# Get clients
# -------------------------------
parsed="$(hyprctl clients -j | jq -r --arg curr "$current_addr" '
    map(select(.address != $curr))
    | sort_by(.focusHistoryID)
    | .[]
    | "\(.address)\t\(.class)\t\(.title)"
')"

declare -A display_to_addr
list=""

while IFS=$'\t' read -r addr class title; do
    [ -z "$addr" ] && continue

    alias="${aliases[$addr]:-}"
    base_display="${alias:-$title}"

    # 🔥 Add class suffix for uniqueness
    display="$base_display ($class)"

    icon="$(get_desktop_name "$class")"

    display_to_addr["$display"]="$addr"

    list+="$display\0icon\x1f$icon\n"
done <<< "$parsed"

# -------------------------------
# Show fuzzel
# -------------------------------
sel="$(printf "%b" "$list" | fuzzel --icon-theme Papirus -d -p 'FOCUS:')"
[ -z "$sel" ] && exit 0

addr="${display_to_addr[$sel]:-}"

# -------------------------------
# Focus window
# -------------------------------
[ -n "$addr" ] && hyprctl dispatch focuswindow address:"$addr"
