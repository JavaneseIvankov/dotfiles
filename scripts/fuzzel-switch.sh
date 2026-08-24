#!/usr/bin/env bash

set -euo pipefail

ALIAS_FILE="$HOME/.cache/hypr-window-aliases"
CDP_ALIAS_FILE="$HOME/.cache/cdp-tab-aliases"
mkdir -p "$(dirname "$ALIAS_FILE")"
touch "$ALIAS_FILE"
touch "$CDP_ALIAS_FILE"

get_desktop_name() {
    "$(dirname "$0")/get_desktop_name.sh" "$1"
}

declare -A aliases
while IFS='|' read -r addr alias; do
    [ -n "${addr:-}" ] && aliases["$addr"]="$alias"
done < "$ALIAS_FILE"

declare -A cdp_aliases
while IFS='|' read -r tabid url alias; do
    [ -n "${tabid:-}" ] || continue
    cdp_aliases["$tabid"]="$alias"
done < "$CDP_ALIAS_FILE"

cleanup_cdp_aliases() {
    local tmpfile tabid url alias

    tmpfile="$(mktemp)"
    while IFS='|' read -r tabid url alias; do
        [ -n "${tabid:-}" ] || continue
        [ -n "${active_cdp_tabs[$tabid]:-}" ] && printf '%s|%s|%s\n' "$tabid" "$url" "$alias" >> "$tmpfile"
    done < "$CDP_ALIAS_FILE"
    mv "$tmpfile" "$CDP_ALIAS_FILE"
}

domain_from_url() {
    local url="$1"
    local domain

    domain="${url#*://}"
    domain="${domain%%/*}"
    domain="${domain#*@}"
    domain="${domain%%:*}"
    printf '%s' "$domain"
}

decode_html_entities() {
    sed -e 's/&amp;/\&/g' \
        -e 's/&lt;/</g' \
        -e 's/&gt;/>/g' \
        -e 's/&quot;/"/g' \
        -e "s/&#39;/'/g"
}

switch_niri() {
    parsed="$(niri msg --json windows | jq -r '.[] | "\(.id)\t\(.app_id)\t\(.title)"' 2>/dev/null || true)"

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
    [ -z "$sel" ] && return 0

    id="${display_to_id[$sel]:-}"
    [ -n "$id" ] && niri msg action focus-window --id "$id"
}

switch_cdp() {
    tabs=$(curl -s http://localhost:9222/json \
        | jq -r '.[] | select(.type == "page") | "\(.title)\t\(.id)"' \
        | decode_html_entities)

    [ -z "$tabs" ] && echo "No CDP tabs found" && return 1

    selected=$(echo "$tabs" | cut -f1 | fuzzel --dmenu -p "Tab: ")
    [ -z "$selected" ] && return 0

    tab_id=$(echo "$tabs" | grep -F "$selected" | head -1 | cut -f2)

    curl -s "http://localhost:9222/json/activate/$tab_id" > /dev/null || true

   #  sleep 0.1

    result="$(niri msg --json windows \
        | jq -r --arg title "$selected" \
          '[.[] | select(.app_id == "brave-browser" and (.title | contains($title)))] | first | .id')"

    [ -n "$result" ] && niri msg action focus-window --id "$result"
}

# Config: prefix to show for CDP tabs. Set via env `TAB_PREFIX=""` to disable.
TAB_PREFIX="${TAB_PREFIX:-[.t]  }"

# Build a single combined list containing Niri windows and CDP tabs.
declare -a action_by_index
declare -a cdp_title_by_index
declare -A active_cdp_tabs
action_by_index=()
cdp_title_by_index=()
list=""

add_entry() {
    local display_text="$1"
    local icon="$2"
    local action="$3"
    local index

    index="${#action_by_index[@]}"
    action_by_index["$index"]="$action"
    list+="$display_text\0icon\x1f$icon\n"
}

is_excluded_app_id() {
   appId="$1"
   case "$appId" in
       "brave-browser")
           return 0
           ;;
       *)
           return 1
           ;;
   esac
}

# Niri windows
parsed="$(niri msg --json windows | jq -r '.[] | "\(.id)\t\(.app_id)\t\(.title)"')"
while IFS=$'\t' read -r id app_id title; do
    [ -z "$id" ] && continue
    is_excluded_app_id "$app_id" && continue
    base_display="${aliases[$id]:-$title}"
    display_text="$base_display ($app_id)"
    icon="$(get_desktop_name "$app_id")"
    add_entry "$display_text" "$icon" "niri:$id"
done <<< "$parsed"

# CDP tabs (fetch safely; tolerate missing CDP endpoint)
tabs_json="$(curl -s --max-time 1 http://localhost:9222/json 2>/dev/null || true)"
tabs=""
if [ -n "$tabs_json" ]; then
    tabs="$(printf '%s' "$tabs_json" | jq -r '.[] | select(.type == "page") | "\(.title)\t\(.id)\t\(.url // "")"' 2>/dev/null | decode_html_entities || true)"
fi

if [ -n "$tabs" ]; then
    while IFS=$'\t' read -r title tabid url; do
        [ -z "$title" ] && continue
        [ -z "$tabid" ] && continue
        active_cdp_tabs["$tabid"]=1
        alias="${cdp_aliases[$tabid]:-}"
        base_display="${alias:-$title}"
        domain="$(domain_from_url "$url")"
        if [ -n "$domain" ]; then
            display_text="${TAB_PREFIX}${base_display} (${domain})"
        else
            display_text="${TAB_PREFIX}${base_display}"
        fi
        # icon="web-browser"
        icon="$(get_desktop_name "brave-browser")"
        index="${#action_by_index[@]}"
        add_entry "$display_text" "$icon" "cdp:$tabid"
        cdp_title_by_index["$index"]="$title"
    done <<< "$tabs"
fi

if [ -n "$tabs_json" ]; then
    cleanup_cdp_aliases
fi

sel="$(printf "%b" "$list" | fuzzel --icon-theme Papirus -d --index -p 'SWITCH:')"
[ -z "$sel" ] && exit 0

action="${action_by_index[$sel]:-}"
case "$action" in
    niri:*)
        id="${action#niri:}"
        [ -n "$id" ] && niri msg action focus-window --id "$id"
        ;;
    cdp:*)
        tabid="${action#cdp:}"
        [ -n "$tabid" ] && {
            curl -s "http://localhost:9222/json/activate/$tabid" > /dev/null || true
            # attempt to focus the browser window whose title contains the tab title
            selected_title="${cdp_title_by_index[$sel]:-}"
            sleep 0.1
            result="$(niri msg --json windows \
                | jq -r --arg title "$selected_title" \
                  '[.[] | select(.app_id == "brave-browser" and (.title | contains($title)))] | first | .id')"
            [ -n "$result" ] && niri msg action focus-window --id "$result"
        }
        ;;
    *)
        exit 0
        ;;
esac
