#!/usr/bin/env bash
# Toggle the status bar.
#
# Bringing the bar back always uses the remembered variant (~/.local/state/waybar/variant)
# via waybar-variant.sh, so toggling never changes the look. The old version ran a bare
# `waybar &`, which fell back to config.jsonc + style.css -- i.e. the legacy theme.
set -euo pipefail

self="$(readlink -f "$0")"
variant_sh="$(dirname "$self")/waybar-variant.sh"

if pgrep -x waybar >/dev/null; then
  pkill -x waybar
  # Wait for the bar to actually exit, so a quick second toggle cannot leave two
  # bars fighting over the same struts.
  for _ in $(seq 1 30); do
    pgrep -x waybar >/dev/null || break
    sleep 0.1
  done
else
  exec "$variant_sh"
fi
