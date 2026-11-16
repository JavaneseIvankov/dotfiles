#!/usr/bin/env bash
# Switch nirimap config presets for quick A/B testing.
#
#   nirimap-preset.sh list
#   nirimap-preset.sh current
#   nirimap-preset.sh apply <preset> [--no-restart]
#   nirimap-preset.sh stop
#
# Presets live in ~/dotfiles/nirimap/presets/*.toml and are copied over the live
# config (~/.config/nirimap -> ~/dotfiles/nirimap). nirimap hot-reloads colors,
# sizes and behavior, but anchor + margins only apply after a restart, so this
# script restarts the process when those change.
set -euo pipefail

presets_dir="${NIRIMAP_PRESETS:-$HOME/dotfiles/nirimap/presets}"
live="${NIRIMAP_CONFIG:-$HOME/dotfiles/nirimap/config.toml}"
restart_keys='^(anchor|margin_x|margin_y) ='

running() { pgrep -x nirimap >/dev/null 2>&1; }

preset_name() { basename "$1" .toml; }

preset_desc() { sed -n '1s/^# [a-zA-Z0-9_-]* — //p' "$1"; }

list() {
  local f name marker
  for f in "$presets_dir"/*.toml; do
    [ -e "$f" ] || continue
    name="$(preset_name "$f")"
    marker=' '
    if cmp -s "$f" "$live"; then marker='*'; fi
    printf '%s %-10s %s\n' "$marker" "$name" "$(preset_desc "$f")"
  done
  printf '\n* = sedang aktif\n'
}

current() {
  local f
  for f in "$presets_dir"/*.toml; do
    if cmp -s "$f" "$live"; then preset_name "$f"; return 0; fi
  done
  echo 'custom'
}

stop() {
  if running; then
    pkill -x nirimap
    echo 'nirimap stopped'
  else
    echo 'nirimap is not running'
  fi
}

restart() {
  if running; then
    pkill -x nirimap
    sleep 0.3
  fi
  setsid -f nirimap >/tmp/nirimap.log 2>&1
  printf 'nirimap restarted (log: /tmp/nirimap.log)\n'
}

apply() {
  local name="$1" opt="${2:-}" file restart_needed=0
  file="$presets_dir/$name.toml"
  if [ ! -f "$file" ]; then
    printf 'unknown preset: %s\n\ntry: %s list\n' "$name" "${0##*/}" >&2
    exit 2
  fi
  if ! cmp -s <(grep -E "$restart_keys" "$file") <(grep -E "$restart_keys" "$live"); then
    restart_needed=1
  fi
  cp "$file" "$live"
  printf 'applied preset: %s  (%s)\n' "$name" "$(preset_desc "$file")"

  if ! running; then
    printf 'nirimap tidak berjalan. jalankan: setsid nirimap >/tmp/nirimap.log 2>&1 &\n'
    return 0
  fi
  if [ "$opt" = '--no-restart' ]; then
    if [ "$restart_needed" = 1 ]; then
      printf 'catatan: anchor/margin berubah, perlu restart manual untuk melihat efeknya\n'
    else
      printf 'nirimap running: hot-reload, tanpa restart\n'
    fi
    return 0
  fi
  restart
}

cmd="${1:-}"
case "$cmd" in
  list|ls) list ;;
  current) current ;;
  stop)    stop ;;
  apply)   apply "${2:?usage: nirimap-preset.sh apply <preset> [--no-restart]}" "${3:-}" ;;
  ''|-h|--help) sed -n '2,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' ;;
  *) printf 'unknown command: %s\n\ntry: nirimap-preset.sh list\n' "$cmd" >&2; exit 2 ;;
esac
