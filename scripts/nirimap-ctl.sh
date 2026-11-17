#!/usr/bin/env bash
# Control the nirimap overlay (manual-only fork build).
#
#   nirimap-ctl.sh hold-start   # $MOD+v press: pin visible, arm the hold
#   nirimap-ctl.sh hold-end     # $MOD+v release: hide, only if armed
#   nirimap-ctl.sh toggle       # $MOD+Shift+v
#   nirimap-ctl.sh show|hide
#   nirimap-ctl.sh stop
#
# nirimap runs with behavior.manual_only = true, so niri events never surface
# it; only these commands do. A cold start costs ~250 ms, so show/hold-start
# spawn a resident instance and wait for its control socket; after that every
# command is ~25 ms.
#
# The armed marker exists because the release carrier ($MOD+Print, emitted by
# kanata) also fires for the toggle combo; without it a toggle would be
# cancelled the moment the key is released.
set -euo pipefail

ctl="$(command -v nirimapctl || true)"
if [ -z "$ctl" ]; then
  echo 'nirimap-ctl: nirimapctl not found (fork build not installed)' >&2
  exit 1
fi

runtime="${XDG_RUNTIME_DIR:-/tmp}"
socket="$runtime/nirimap.sock"
marker="$runtime/nirimap-hold-armed"
printf '%s %s\n' "$(date +%H:%M:%S.%3N)" "${1:-<none>}" >> /tmp/nirimap-ctl.log

spawn() {
  if ! command -v nirimap >/dev/null; then
    echo 'nirimap-ctl: nirimap not found' >&2
    exit 1
  fi
  setsid -f nirimap >/dev/null 2>&1
  for _ in $(seq 1 100); do
    [ -S "$socket" ] && return 0
    sleep 0.02
  done
  echo 'nirimap-ctl: control socket did not appear' >&2
  return 1
}

show() {
  if ! "$ctl" show 2>/dev/null; then
    spawn
    "$ctl" show
  fi
}

case "${1:-}" in
  hold-start)
    show
    : > "$marker"
    ;;
  hold-end)
    if [ -e "$marker" ]; then
      rm -f "$marker"
      "$ctl" hide 2>/dev/null || true
    fi
    ;;
  show)
    show
    ;;
  hide)
    rm -f "$marker"
    "$ctl" hide 2>/dev/null || true
    ;;
  toggle)
    rm -f "$marker"
    if ! "$ctl" toggle 2>/dev/null; then
      spawn
      "$ctl" show
    fi
    ;;
  stop)
    rm -f "$marker"
    if pkill -x nirimap; then echo 'nirimap stopped'; else echo 'nirimap is not running'; fi
    ;;
  *)
    echo "usage: ${0##*/} hold-start|hold-end|toggle|show|hide|stop" >&2
    exit 2
    ;;
esac
