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
# Get current active window
# -------------------------------
current_addr="$(hyprctl activewindow -j 2>/dev/null | jq -r '.address // empty')"
[ -n "$current_addr" ] || exit 0

current_class="$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // empty')"
current_title="$(hyprctl activewindow -j 2>/dev/null | jq -r '.title // empty')"

# -------------------------------
# Load existing aliases
# -------------------------------
declare -A aliases
while IFS='|' read -r addr alias; do
    [ -n "${addr:-}" ] && aliases["$addr"]="$alias"
done < "$ALIAS_FILE"

current_alias="${aliases[$current_addr]:-}"

display="${current_alias:-$current_title} ($current_class)"
icon="$(get_desktop_name "$current_class")"

# -------------------------------
# Prompt for new alias (pre-filled with current alias)
# -------------------------------
new_alias="$(printf "%s" "$current_alias" | fuzzel -d -l 0 -p "Rename alias: ")"
[ -n "$new_alias" ] || exit 0

# -------------------------------
# Save alias
# -------------------------------
grep -v "^$current_addr|" "$ALIAS_FILE" > "$ALIAS_FILE.tmp" || true
mv "$ALIAS_FILE.tmp" "$ALIAS_FILE"

echo "$current_addr|$new_alias" >> "$ALIAS_FILE"

# Optionally notify (if notify-send exists)
if command -v notify-send >/dev/null 2>&1; then
    notify-send "Window renamed" "$display → $new_alias" -i "${icon:-dialog-information}"
fi

exit 0
