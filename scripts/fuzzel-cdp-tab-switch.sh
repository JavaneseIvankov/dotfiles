#!/usr/bin/env bash

# tabs=$(curl -s http://localhost:9222/json | jq -r '.[] | select(.type == "page") | "\(.title)\t\(.id)"')

tabs=$(curl -s http://localhost:9222/json \
    | jq -r '.[] | select(.type == "page") | "\(.title)\t\(.id)"' \
    | sed 's/&amp;/\&/g; s/&lt;/</g; s/&gt;/>/g; s/&quot;/"/g; s/&#39;/'"'"'/g')

selected=$(echo "$tabs" | cut -f1 | fuzzel --dmenu -p "Tab: ")
[ -z "$selected" ] && exit 0

tab_id=$(echo "$tabs" | grep -F "$selected" | head -1 | cut -f2)

# Activar pestaña via CDP
curl -s "http://localhost:9222/json/activate/$tab_id" > /dev/null

# Dar focus a la ventana de Vivaldi cuyo título contiene el nombre de la pestaña
sleep 0.1

result="$(niri msg --json windows \
    | jq -r --arg title "$selected" \
      '[.[] | select(.app_id == "brave-browser" and (.title | contains($title)))] | first | .id')"

niri msg action focus-window --id $result
