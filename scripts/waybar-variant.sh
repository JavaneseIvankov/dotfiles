#!/usr/bin/env bash
# Switch (and start) the Waybar variant for this machine.
#
#   waybar-variant.sh          start the remembered variant (default: a)
#   waybar-variant.sh a        refined flat strip  (config-a.jsonc + style-a.css)
#   waybar-variant.sh b        floating island     (config-b.jsonc + style-b.css)
#   waybar-variant.sh old      the previous look   (config.niri.jsonc + style.css)
#
# The choice is remembered in $XDG_STATE_HOME/waybar/variant, so the next login
# picks it up without touching niri/config.kdl again.

set -euo pipefail

conf_dir="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/waybar"
state_file="$state_dir/variant"
default_variant="a"

usage() {
  echo "usage: $(basename "$0") [a|b|old]" >&2
  exit 2
}

variant="${1:-}"
if [[ -z "$variant" ]]; then
  variant="$(cat "$state_file" 2>/dev/null || echo "$default_variant")"
fi

case "$variant" in
  a)   args=(-c "$conf_dir/config-a.jsonc" -s "$conf_dir/style-a.css") ;;
  b)   args=(-c "$conf_dir/config-b.jsonc" -s "$conf_dir/style-b.css") ;;
  old) args=(-c "$conf_dir/config.niri.jsonc" -s "$conf_dir/style.css") ;;
  *)   usage ;;
esac

# Validate before persisting anything.
for f in "${args[1]}" "${args[3]}"; do
  [[ -r "$f" ]] || { echo "missing file: $f" >&2; exit 1; }
done

if [[ $# -gt 0 ]]; then
  mkdir -p "$state_dir"
  printf '%s\n' "$variant" >"$state_file"
fi

# Restart only when the running bar is not already the requested variant.
if pid="$(pgrep -x waybar | head -1)" && [[ -n "${pid:-}" ]]; then
  running="$(tr '\0' ' ' <"/proc/${pid}/cmdline" 2>/dev/null || true)"
  if [[ "$running" == *"${args[1]}"* && "$running" == *"${args[3]}"* ]]; then
    echo "waybar already running; variant ${variant}"
    exit 0
  fi
  pkill -x waybar 2>/dev/null || true
  for _ in $(seq 1 30); do
    pgrep -x waybar >/dev/null || break
    sleep 0.1
  done
fi

# Start detached: the bar must outlive this shell (it is also spawned at login by
# niri), so no exec here -- otherwise closing the terminal would kill the bar.
log="${state_dir}/waybar.log"
mkdir -p "${state_dir}"
setsid env GSK_RENDERER=vulkan waybar "${args[@]}" >"${log}" 2>&1 </dev/null &
disown 2>/dev/null || true

for _ in $(seq 1 30); do
  pgrep -x waybar >/dev/null && break
  sleep 0.1
done

if pgrep -x waybar >/dev/null; then
  echo "waybar started: variant ${variant}  (log: ${log})"
else
  echo "waybar failed to start; see ${log}" >&2
  exit 1
fi
