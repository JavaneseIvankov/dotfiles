#!/usr/bin/env bash

set -euo pipefail

ALIAS_FILE="$HOME/.cache/hypr-window-aliases"
mkdir -p "$(dirname "$ALIAS_FILE")"
touch "$ALIAS_FILE"

get_desktop_name() {
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

    base="${aliases[$id]:-$title}"
    display="$base ($app_id)"

    icon="$(get_desktop_name "$app_id")"

    display_to_id["$display"]="$id"
    list+="$display\0icon\x1f$icon\n"
done <<< "$parsed"

sel="$(printf "%b" "$list" | fuzzel -a top --y-margin 40 --icon-theme Papirus -d -p 'Alias for:')"
[ -z "$sel" ] && exit 0

id="${display_to_id[$sel]:-}"
[ -z "$id" ] && exit 0

current_alias="${aliases[$id]:-}"

# Pre-fill current alias into fuzzel via stdin
new_alias="$(printf "%s" "$current_alias" | fuzzel -d -l 0 -p 'New alias: ' )"
[ -z "$new_alias" ] && exit 0

# Save alias (atomic-ish)
grep -v "^$id|" "$ALIAS_FILE" > "$ALIAS_FILE.tmp" || true
mv "$ALIAS_FILE.tmp" "$ALIAS_FILE"

echo "$id|$new_alias" >> "$ALIAS_FILE"
