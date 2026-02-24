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
# Load existing aliases
# -------------------------------
declare -A aliases

while IFS='|' read -r addr alias; do
    [ -n "${addr:-}" ] && aliases["$addr"]="$alias"
done < "$ALIAS_FILE"

# -------------------------------
# Get clients (sorted by focus order, MRU first)
# -------------------------------
parsed="$(hyprctl -j clients | jq -r '
    sort_by(.focusHistoryID) |
    .[] |
    "\(.address)\t\(.class)\t\(.title)"
')"

declare -A display_to_addr
list=""

while IFS=$'\t' read -r addr class title; do
    [ -z "$addr" ] && continue

    base="${aliases[$addr]:-$title}"
    display="$base ($class)"

    icon="$(get_desktop_name "$class")"

    display_to_addr["$display"]="$addr"
    list+="$display\0icon\x1f$icon\n"
done <<< "$parsed"

# -------------------------------
# Select window to alias
# -------------------------------
sel="$(printf "%b" "$list" | fuzzel --icon-theme Papirus -d -p 'Alias for:')"
[ -z "$sel" ] && exit 0

addr="${display_to_addr[$sel]:-}"
[ -z "$addr" ] && exit 0

# -------------------------------
# Ask for new alias
# -------------------------------
current_alias="${aliases[$addr]:-}"

new_alias="$(printf "%s" "$current_alias" | fuzzel -d -l 0 -p 'New alias: ')"
[ -z "$new_alias" ] && exit 0

# -------------------------------
# Save alias
# -------------------------------
grep -v "^$addr|" "$ALIAS_FILE" > "$ALIAS_FILE.tmp" || true
mv "$ALIAS_FILE.tmp" "$ALIAS_FILE"

echo "$addr|$new_alias" >> "$ALIAS_FILE"
