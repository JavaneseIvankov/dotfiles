#!/usr/bin/env bash

set -euo pipefail

ALIAS_FILE="$HOME/.cache/hypr-window-aliases"
mkdir -p "$(dirname "$ALIAS_FILE")"
touch "$ALIAS_FILE"

get_desktop_name() {
    /home/arundaya/scripts/get_desktop_name.sh "$1"
}

# Cleanup stale aliases
active_addrs="$(hyprctl clients -j | jq -r '.[].address')"

tmpfile="$(mktemp)"
while IFS='|' read -r addr alias; do
    if echo "$active_addrs" | grep -qx "$addr"; then
        echo "$addr|$alias" >> "$tmpfile"
    fi
done < "$ALIAS_FILE"
mv "$tmpfile" "$ALIAS_FILE"

declare -A aliases
while IFS='|' read -r addr alias; do
    [ -n "${addr:-}" ] && aliases["$addr"]="$alias"
done < "$ALIAS_FILE"

current_addr="$(hyprctl activewindow -j | jq -r '.address')"

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

    base="${aliases[$addr]:-$title}"
    display="$base ($class)"
    icon="$(get_desktop_name "$class")"

    display_to_addr["$display"]="$addr"
    list+="$display\0icon\x1f$icon\n"
done <<< "$parsed"

# Small runtime helpers and diagnostics
# DEBUG=1 to enable verbose output; SKIP_FUZZEL=1 to print the fuzzel command and exit
DEBUG=${DEBUG:-0}
SKIP_FUZZEL=${SKIP_FUZZEL:-0}

check_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "ERROR: required command '$1' not found in PATH." >&2
        return 1
    fi
}

if [ "$DEBUG" = "1" ]; then
    echo "DEBUG: ALIAS_FILE=$ALIAS_FILE" >&2
fi

# If there are no entries, print debug info and exit early
if [ -z "$list" ]; then
    if [ "$DEBUG" = "1" ]; then
        echo "DEBUG: generated list is empty. Parsed clients output follows:" >&2
        hyprctl clients -j | jq '.' 2>/dev/null || true
    fi
    echo "No windows to show / no clients returned by hyprctl." >&2
    exit 0
fi

fuzzel_cmd=(fuzzel --icon-theme Papirus -d -p 'FOCUS (Ctrl-R to rename):')

if [ "$DEBUG" = "1" ]; then
    echo "DEBUG: checking required commands..." >&2
    check_cmd fuzzel || true
    check_cmd hyprctl || true
    check_cmd jq || true
    echo "DEBUG: prepared fuzzel command: ${fuzzel_cmd[*]}" >&2
    printf "DEBUG: list preview:\n" >&2
    printf "%b" "$list" | head -n 8 >&2 || true
fi

if [ "$SKIP_FUZZEL" = "1" ]; then
    echo "SKIP_FUZZEL=1 set, not launching fuzzel. Exiting (dry-run)." >&2
    exit 0
fi

sel="$(
    printf "%b" "$list" | \
    "${fuzzel_cmd[@]}"
)"

exit_code=$?

[ -z "$sel" ] && exit 0

addr="${display_to_addr[$sel]:-}"
[ -z "$addr" ] && exit 0

# fuzzel uses special exit codes for actions. Historically `execute` maps to
# exit code 10. Custom mappings via `custom-<n>` will typically return
# 10 + n. To support both `--key-bind` and `custom-<n>` workarounds, we
# compute an action index from exit_code when exit_code >= 10.
if [ "$exit_code" -ge 10 ]; then
    action_index=$((exit_code - 10))
else
    action_index=0
fi

# If action_index == 1 (e.g. custom-1 or execute mapped to 11), treat as rename.
# This keeps the old behavior (exit_code == 10) covered via action_index 0
# and supports custom-1 -> action_index 1.
if [ "$action_index" -eq 1 ]; then
    current_alias="${aliases[$addr]:-}"

    new_alias="$(
        printf "%s" "$current_alias" | \
        fuzzel -d -p 'New alias:'
    )"

    [ -z "$new_alias" ] && exit 0

    grep -v "^$addr|" "$ALIAS_FILE" > "$ALIAS_FILE.tmp" || true
    mv "$ALIAS_FILE.tmp" "$ALIAS_FILE"

    echo "$addr|$new_alias" >> "$ALIAS_FILE"

    exit 0
fi

# Default: focus
hyprctl dispatch focuswindow address:"$addr"