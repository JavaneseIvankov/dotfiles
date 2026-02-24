#!/usr/bin/env sh

ACTIVE_JSON=$(hyprctl activewindow -j)

ADDRESS=$(echo "$ACTIVE_JSON" | jq -r '.address')
TITLE=$(echo "$ACTIVE_JSON" | jq -r '.title')

NEW_TITLE="🔥 $TITLE"

# Remove previous dynamic rule (if any)
hyprctl keyword windowrulev2 unset,address:$ADDRESS

# Set new rule overriding title
hyprctl keyword windowrulev2 "title:$NEW_TITLE,address:$ADDRESS"
