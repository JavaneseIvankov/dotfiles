#!/usr/bin/env bash

APP_ID="$1"
shift

WINDOW_ID=$(niri msg --json windows | jq -r \
    --arg app "$APP_ID" '
    map(select(.app_id==$app))
    | sort_by(.focus_timestamp.secs,.focus_timestamp.nanos)
    | last
    | .id // empty
')

if [ -n "$WINDOW_ID" ]; then
    niri msg action focus-window --id "$WINDOW_ID"
else
    $@ &
fi
