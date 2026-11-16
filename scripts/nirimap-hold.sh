#!/usr/bin/env bash
# Drive the nirimap overlay (fork build) from key bindings.
#
#   nirimap-hold.sh hold-start   # $MOD+m press: pin visible, arm the hold
#   nirimap-hold.sh hold-end     # $MOD+m release: hide, but only if armed
#   nirimap-hold.sh toggle       # $MOD+Shift+m: flip pinned visibility
#   nirimap-hold.sh show|hide    # plain control
#   nirimap-hold.sh stop         # kill the resident process
#
# Hold works because an acknowledged show/hide is ~25 ms, but only with a
# resident process: a cold start costs ~250 ms, so `show` spawns nirimap and
# waits for its control socket.
#
# The armed marker exists because the release fake key also fires for the
# toggle combo (kanata cannot branch on Shift there), and a toggle release
# must not hide the overlay again.
set -euo pipefail

ctl="$(command -v nirimapctl || true)"
if [ -z "$ctl" ]; then
  echo 'nirimap-hold: nirimapctl not found (fork build not installed)' >&2
  exit 1
fi

runtime="${XDG_RUNTIME_DIR:-/tmp}"
socket="$runtime/nirimap.sock"
marker="$runtime/nirimap-hold-armed"

spawn() {
  if ! command -v nirimap >/dev/null; then
    echo 'nirimap-hold: nirimap not found' >&2
    exit 1
  fi
  setsid -f nirimap >/dev/null 2>&1
  for _ in $(seq 1 100); do
    [ -S "$socket" ] && return 0
    sleep 0.02
  done
  echo 'nirimap-hold: control socket did not appear' >&2
  return 1
}

show() {
  if ! "$ctl" show 2>/dev/null; then
    spawn
    "$ctl" show
  fi
}

hide() { "$ctl" hide 2>/dev/null || true; }

case "${1:-}" in
  hold-start)
    show
    : > "$marker"
    ;;
  hold-end)
    if [ -e "$marker" ]; then
      rm -f "$marker"
      hide
    fi
    ;;
  show)
    show
    ;;
  hide)
    rm -f "$marker"
    hide
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
