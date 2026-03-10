#!/usr/bin/env bash

set -euo pipefail

ALIAS_FILE="$HOME/.cache/hypr-window-aliases"
mkdir -p "$(dirname "$ALIAS_FILE")"
touch "$ALIAS_FILE"

get_desktop_name() {
    "$(dirname "$0")/get_desktop_name.sh" "$1"
}

# Try to detect focused Niri window via common keys; fall back to user picker
current_line="$(niri msg --json windows 2>/dev/null | jq -r '.[] | select((.focused==true) or (.is_focused==true) or (.active==true)) | "\(.id)\t\(.app_id)\t\(.title)"' | head -n1)"

if [ -z "$current_line" ]; then
    # No focused window found — let user pick one
    parsed="$(niri msg --json windows | jq -r '.[] | "\(.id)\t\(.app_id)\t\(.title)"')"

    declare -A display_to_id
    list=""

    while IFS=$'\t' read -r id app_id title; do
        [ -z "$id" ] && continue
        display="$title ($app_id)"
        icon="$(get_desktop_name "$app_id")"
        display_to_id["$display"]="$id"
        list+="$display\0icon\x1f$icon\n"
    done <<< "$parsed"

    sel="$(printf "%b" "$list" | fuzzel --icon-theme Papirus -d -p 'Rename:')"
    [ -z "$sel" ] && exit 0

    id="${display_to_id[$sel]:-}"
    [ -z "$id" ] && exit 0

    # fetch app_id/title for notification and display
    read -r app_id title <<< "$(niri msg --json windows | jq -r --arg id "$id" '.[] | select(.id==$id) | "\(.app_id)\t\(.title)"')"
else
    read -r id app_id title <<< "$current_line"
fi

[ -n "$id" ] || exit 0

# Load existing aliases
declare -A aliases
while IFS='|' read -r addr alias; do
    [ -n "${addr:-}" ] && aliases["$addr"]="$alias"
done < "$ALIAS_FILE"

current_alias="${aliases[$id]:-}"
display="${current_alias:-$title} ($app_id)"
icon="$(get_desktop_name "$app_id")"

# Prompt for new alias (pre-filled)
new_alias="$(printf "%s" "$current_alias" | fuzzel -d -l 0 -p 'Rename alias: ')"
[ -z "$new_alias" ] && exit 0

# Save alias (atomic-ish)
grep -v "^$id|" "$ALIAS_FILE" > "$ALIAS_FILE.tmp" || true
mv "$ALIAS_FILE.tmp" "$ALIAS_FILE"
echo "$id|$new_alias" >> "$ALIAS_FILE"

if command -v notify-send >/dev/null 2>&1; then
    notify-send "Window renamed" "$display → $new_alias" -i "${icon:-dialog-information}"
fi

exit 0
