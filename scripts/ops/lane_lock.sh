#!/bin/sh
# Usage: lane_lock.sh acquire <lane> <purpose> | release <lane> | status   (see docs/ops/lane-lock.md)
# The lock is always the directory /tmp/tessera-mac-lock.d (no override, so nothing else can be removed). Stale after 2h.
set -eu
L=/tmp/tessera-mac-lock.d; F="$L/info"; MAX=7200; now=$(date +%s)
field() { sed -n "s/^$1=//p" "$F" 2>/dev/null || true; }
drop() { rm -f "$L/info"; rmdir "$L"; }
case "${1:-}" in
 acquire) [ -n "${2:-}" ] && [ -n "${3:-}" ] || { echo "need lane and purpose" >&2; exit 2; }
  if [ -d "$L" ]; then s=$(field start); pid=$(field pid)
   if [ -n "$s" ] && [ $((now - s)) -lt $MAX ] && kill -0 "$pid" 2>/dev/null; then echo "BUSY: $(field lane) pid $pid: $(field purpose)"; exit 1; fi
   echo "stale lock from $(field lane) pid $pid, taking over"; drop; fi
  mkdir "$L" 2>/dev/null || { echo "BUSY: lost race"; exit 1; }
  printf 'lane=%s\npid=%s\nstart=%s\nstart_iso=%s\npurpose=%s\n' "$2" "$PPID" "$now" "$(date -u +%FT%TZ)" "$3" > "$F"; echo "acquired by $2 (pid $PPID)";;
 release) if [ "$(field lane)" = "${2:-}" ]; then drop; echo released; else echo "not held by ${2:-}" >&2; exit 1; fi;;
 status) if [ -d "$L" ]; then cat "$F"; echo "age_s=$((now - $(field start)))"; else echo free; fi;;
 *) echo "usage: acquire|wait|release|status" >&2; exit 2;;
esac
