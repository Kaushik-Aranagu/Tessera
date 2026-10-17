#!/bin/sh
# Usage: lane_lock.sh acquire <lane> <purpose> | wait <lane> <purpose> [max_s] | beat <lane> | run <lane> <purpose> -- cmd... | release <lane> | status   (see docs/ops/lane-lock.md)
# The lock is always the directory /tmp/tessera-mac-lock.d (no override, so nothing else can be removed). A hold is abandoned (freed with a log line) when its pid is dead, it is older than 2h, or it has had no heartbeat for 10 min.
set -eu
L=/tmp/tessera-mac-lock.d; F="$L/info"; MAX=7200; BEAT=600; LOG=/tmp/tessera-mac-lock.log; now=$(date +%s); Q=/tmp/tessera-mac-lock.q
field() { sed -n "s/^$1=//p" "$F" 2>/dev/null || true; }
drop() { rm -f "$L/info" "$L/beat"; rmdir "$L"; }
lastbeat() { b=$(cat "$L/beat" 2>/dev/null || true); echo "${b:-$(field start)}"; }
beat() { date +%s > "$L/beat"; }
case "${1:-}" in
 acquire) [ -n "${2:-}" ] && [ -n "${3:-}" ] || { echo "need lane and purpose" >&2; exit 2; }
  if [ -d "$L" ]; then s=$(field start); pid=$(field pid)
   lb=$(lastbeat)
   if [ -n "$s" ] && [ $((now - s)) -lt $MAX ] && [ $((now - lb)) -lt $BEAT ] && kill -0 "$pid" 2>/dev/null; then echo "BUSY: $(field lane) pid $pid held $((now - s))s, last beat $((now - lb))s ago: $(field purpose)"; exit 1; fi
   why="pid $pid"; kill -0 "$pid" 2>/dev/null && why="no heartbeat for $((now - lb))s"
   msg="$(date -u +%FT%TZ) freed stale lock from $(field lane) ($why, held $((now - ${s:-$now}))s): $(field purpose)"; echo "$msg" >> "$LOG"; echo "$msg"; drop; fi
  mkdir "$L" 2>/dev/null || { echo "BUSY: lost race"; exit 1; }
  printf 'lane=%s\npid=%s\nstart=%s\nstart_iso=%s\npurpose=%s\n' "$2" "${LOCK_PID:-$PPID}" "$now" "$(date -u +%FT%TZ)" "$3" > "$F"; beat; echo "acquired by $2 (pid ${LOCK_PID:-$PPID})";;
 wait) [ -n "${2:-}" ] && [ -n "${3:-}" ] || { echo "need lane and purpose" >&2; exit 2; }
  # FIFO queue: a ticket is "<epoch>-<lane>" holding the waiter's pid; dead tickets are skipped. Polls every 15 s.
  mkdir -p "$Q"; T="$Q/$(date +%s)-$2"; echo "$PPID" > "$T"; end=$((now + ${4:-1800}))
  while :; do
   head=""; for t in $(ls "$Q" 2>/dev/null); do kill -0 "$(cat "$Q/$t" 2>/dev/null)" 2>/dev/null && { head=$t; break; } || rm -f "$Q/$t"; done
   if [ "$head" = "$(basename "$T")" ] && LOCK_PID=$PPID "$0" acquire "$2" "$3" >/dev/null 2>&1; then rm -f "$T"; echo "acquired by $2 (pid $PPID) after waiting"; exit 0; fi
   [ "$(date +%s)" -lt "$end" ] || { rm -f "$T"; echo "TIMEOUT waiting for $(field lane)" >&2; exit 1; }
   [ $((i = ${i:-0} + 1)) -lt 4 ] || { i=0; echo "waiting: $(sh "$0" status | tr '\n' ' ')"; }
   sleep 15; done;;
 beat) if [ "$(field lane)" = "${2:-}" ]; then beat; else echo "not held by ${2:-}" >&2; exit 1; fi;;
 run) [ -n "${2:-}" ] && [ -n "${3:-}" ] && [ "${4:-}" = "--" ] && [ -n "${5:-}" ] || { echo "usage: run <lane> <purpose> -- cmd..." >&2; exit 2; }
  # Holds the lock for the life of cmd, beating every 60 s, and always releases. Waits in the queue if busy.
  lane=$2; purpose=$3; shift 4; "$0" wait "$lane" "$purpose" 3600 || exit 1
  ( while sleep 60; do "$0" beat "$lane" || break; done ) & hb=$!
  rc=0; "$@" || rc=$?; kill "$hb" 2>/dev/null || true; "$0" release "$lane" || true; exit $rc;;
 release) if [ "$(field lane)" = "${2:-}" ]; then drop; echo released; else echo "not held by ${2:-}" >&2; exit 1; fi;;
 status) if [ -d "$L" ]; then cat "$F"; echo "age_s=$((now - $(field start))) beat_age_s=$((now - $(lastbeat)))"; else echo free; fi;;
 *) echo "usage: acquire|wait|beat|run|release|status" >&2; exit 2;;
esac
