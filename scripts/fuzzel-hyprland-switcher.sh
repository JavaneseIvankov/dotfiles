#!/usr/bin/env bash

get_desktop_name() {
    case "$1" in
        code) echo "code" ;;
        Chromium-browser) echo "chromium" ;;
        *) echo "$1" ;;
    esac
}

# Get the address of the currently focused window
current_addr="$(hyprctl activewindow -j | jq -r '.address')"

# Get clients, filter out current, sort by focusHistoryID (descending = most recent first)
parsed="$(hyprctl clients -j | jq -r --arg curr "$current_addr" '
    map(select(.address != $curr))
    | sort_by(.focusHistoryID)
    | .[] | "\(.address)\t\(.class)\t\(.title)"
')"

# Build visible list with icons
list=""
while IFS=$'\t' read -r addr class title; do
    desktop_name=$(get_desktop_name "$class")
    list+="$title\0icon\037$desktop_name\n"
done <<< "$parsed"

# Show menu
sel="$(printf "%b" "$list" | fuzzel --icon-theme Papirus -d -p 'FOCUS:')"

# Find address from title
addr="$(printf "%s\n" "$parsed" | awk -F'\t' -v t="$sel" '$3 == t {print $1; exit}')"

# Focus window
[ -n "$addr" ] && hyprctl dispatch focuswindow address:"$addr"
