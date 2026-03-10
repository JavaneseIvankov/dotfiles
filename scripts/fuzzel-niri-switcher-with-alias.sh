#!/usr/bin/env bash

set -euo pipefail

ALIAS_FILE="$HOME/.cache/hypr-window-aliases"
mkdir -p "$(dirname "$ALIAS_FILE")"
touch "$ALIAS_FILE"

get_desktop_name() {
    # prefer helper located next to this script
    "$(dirname "$0")/get_desktop_name.sh" "$1"
}

declare -A aliases
while IFS='|' read -r addr alias; do
    [ -n "${addr:-}" ] && aliases["$addr"]="$alias"
done < "$ALIAS_FILE"

# Enumerate Niri windows
parsed="$(niri msg --json windows | jq -r '.[] | "\(.id)\t\(.app_id)\t\(.title)"')"

declare -A display_to_id
list=""

while IFS=$'\t' read -r id app_id title; do
    [ -z "$id" ] && continue

    base_display="${aliases[$id]:-$title}"
    display="$base_display ($app_id)"

    icon="$(get_desktop_name "$app_id")"

    display_to_id["$display"]="$id"
    list+="$display\0icon\x1f$icon\n"
done <<< "$parsed"

sel="$(printf "%b" "$list" | fuzzel --icon-theme Papirus -d -p 'FOCUS:')"
[ -z "$sel" ] && exit 0

id="${display_to_id[$sel]:-}"
[ -n "$id" ] && niri msg action focus-window --id "$id"
