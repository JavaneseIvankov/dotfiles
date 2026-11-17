#!/usr/bin/env bash
# Control the nirimap overlay (manual-only fork build).
#
#   nirimap-ctl.sh hold-start   # $MOD+v press: pins it, or hides it if already pinned
#   nirimap-ctl.sh hold-end     # $MOD+v release: hides after a hold, keeps a quick tap
#   nirimap-ctl.sh toggle       # explicit toggle (manual use)
#   nirimap-ctl.sh show|hide
#   nirimap-ctl.sh stop
#
# One key covers both gestures: a tap (< $NIRIMAP_TAP_MS) leaves the overlay
# pinned, holding it brings it up only while held, and pressing again while it is
# pinned hides it. That keeps $MOD+Shift+v free for the floating-layout switch.
#
# nirimap runs with behavior.manual_only = true, so niri events never surface it;
# only these commands do. A cold start costs ~250 ms, so show/hold-start spawn a
# resident instance and wait for its control socket; after that it is ~25 ms.
#
# The press timestamp marker is what lets release decide tap vs hold; kanata
# emits the release as fake key Pause ($MOD+Pause), since niri has no key-release.
set -euo pipefail

ctl="$(command -v nirimapctl || true)"
if [ -z "$ctl" ]; then
  echo 'nirimap-ctl: nirimapctl not found (fork build not installed)' >&2
  exit 1
fi

runtime="${XDG_RUNTIME_DIR:-/tmp}"
socket="$runtime/nirimap.sock"
marker="$runtime/nirimap-hold-armed"
tap_ms="${NIRIMAP_TAP_MS:-250}"
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

hidden() {
  rm -f "$marker"
  "$ctl" hide 2>/dev/null || true
}

visible() {
  niri msg layers 2>/dev/null | grep -qi nirimap
}

case "${1:-}" in
  hold-start)
    if visible; then
      # Second press while pinned: this is a toggle-off. Mark the release inert.
      printf 'consumed\n' > "$marker"
      hidden
    else
      show
      printf '%s\n' "$(date +%s%3N)" > "$marker"
    fi
    ;;
  hold-end)
    [ -e "$marker" ] || exit 0
    read -r pressed < "$marker"
    rm -f "$marker"
    [ "$pressed" = consumed ] && exit 0
    now="$(date +%s%3N)"
    # A quick tap leaves it pinned; a real hold hides on release.
    if [ "$((now - pressed))" -ge "$tap_ms" ]; then
      "$ctl" hide 2>/dev/null || true
    fi
    ;;
  show)
    show
    ;;
  hide)
    hidden
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
