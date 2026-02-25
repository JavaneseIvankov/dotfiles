#!/usr/bin/env bash

POLL_INTERVAL="${1:-10}"   

BATTERY_PATH="/sys/class/power_supply"
STATE_FILE="/tmp/hypr-animations-state"

get_status() {
    for bat in "$BATTERY_PATH"/BAT*; do
        [ -f "$bat/status" ] && cat "$bat/status" && return
    done
}

while true; do
    STATUS=$(get_status)

    if [[ "$STATUS" == "Charging" || "$STATUS" == "Full" ]]; then
        NEW_STATE="true"
    else
        NEW_STATE="false"
    fi

    OLD_STATE=$(cat "$STATE_FILE" 2>/dev/null)

    if [[ "$NEW_STATE" != "$OLD_STATE" ]]; then
        hyprctl keyword animations:enabled "$NEW_STATE"
        echo "$NEW_STATE" > "$STATE_FILE"
    fi

    sleep "$POLL_INTERVAL"
done