#!/usr/bin/env bash
# Control the nirimap overlay directly (manual-only mode).
#
#   nirimap-ctl.sh toggle   # what $MOD+m runs
#   nirimap-ctl.sh show     # pin visible
#   nirimap-ctl.sh hide
#   nirimap-ctl.sh stop     # kill the resident process
#
# nirimap runs with behavior.manual_only = true, so niri events (focus moves,
# workspace switches, new windows) never surface it — only these commands do.
# A cold start costs ~250 ms, so show/toggle spawn a resident instance and wait
# for its control socket; afterwards every command is ~25 ms.
set -euo pipefail

ctl="$(command -v nirimapctl || true)"
if [ -z "$ctl" ]; then
  echo 'nirimap-ctl: nirimapctl not found (fork build not installed)' >&2
  exit 1
fi

runtime="${XDG_RUNTIME_DIR:-/tmp}"
socket="$runtime/nirimap.sock"
# Trace invocations so a missing binding is visible in /tmp/nirimap-ctl.log.
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

run() {
  local action="$1"
  if ! "$ctl" "$action" 2>/dev/null; then
    spawn
    "$ctl" "$action" 2>/dev/null || { [ "$action" = toggle ] && "$ctl" show; }
  fi
}

case "${1:-}" in
  show|hide|toggle) run "$1" ;;
  stop)
    if pkill -x nirimap; then echo 'nirimap stopped'; else echo 'nirimap is not running'; fi
    ;;
  *)
    echo "usage: ${0##*/} toggle|show|hide|stop" >&2
    exit 2
    ;;
esac
