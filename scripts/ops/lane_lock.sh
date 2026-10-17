#!/bin/sh
# Usage: lane_lock.sh acquire <lane> <purpose> | release <lane> | status   (see docs/ops/lane-lock.md)
# LOCKDIR overrides the lock location (default /tmp/tessera-mac-lock.d). Stale after 2h.
L="${LOCKDIR:-/tmp/tessera-mac-lock.d}"; F="$L/info"; MAX=7200; now=$(date +%s)
field() { sed -n "s/^$1=//p" "$F" 2>/dev/null; }
case "$1" in
 acquire) [ -n "$2" ] && [ -n "$3" ] || { echo "need lane and purpose" >&2; exit 2; }
  if [ -d "$L" ]; then s=$(field start); pid=$(field pid)
   if [ -n "$s" ] && [ $((now - s)) -lt $MAX ] && kill -0 "$pid" 2>/dev/null; then echo "BUSY: $(field lane) pid $pid: $(field purpose)"; exit 1; fi
   echo "stale lock from $(field lane) pid $pid, taking over"; rm -rf "$L"; fi
  mkdir "$L" 2>/dev/null || { echo "BUSY: lost race"; exit 1; }
  printf 'lane=%s\npid=%s\nstart=%s\nstart_iso=%s\npurpose=%s\n' "$2" "$PPID" "$now" "$(date -u +%FT%TZ)" "$3" > "$F"; echo "acquired by $2 (pid $PPID)";;
 release) [ "$(field lane)" = "$2" ] && rm -rf "$L" && echo released || { echo "not held by $2" >&2; exit 1; };;
 status) [ -d "$L" ] && { cat "$F"; echo "age_s=$((now - $(field start)))"; } || echo free;;
 *) echo "usage: acquire|release|status" >&2; exit 2;;
esac
