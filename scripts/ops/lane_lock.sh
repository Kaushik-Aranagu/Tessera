#!/bin/sh
# Usage: lane_lock.sh acquire <lane> <purpose> | wait <lane> <purpose> [max_s] | beat <lane> | run <lane> <purpose> -- cmd... (waits while the Mac screen is locked) | release <lane> | status   (see docs/ops/lane-lock.md)
# The lock is always the directory /tmp/tessera-mac-lock.d (no override, so nothing else can be removed). A hold is abandoned (freed with a log line) when its pid is dead, it is older than 2h, or it has had no heartbeat for 10 min.
set -eu
L=/tmp/tessera-mac-lock.d; F="$L/info"; MAX=7200; BEAT=600; LEGACY=2700; LOG=/tmp/tessera-mac-lock.log; now=$(date +%s); Q=/tmp/tessera-mac-lock.q
field() { sed -n "s/^$1=//p" "$F" 2>/dev/null || true; }
drop() { rm -f "$L/info" "$L/beat"; rmdir "$L"; }
lastbeat() { b=$(cat "$L/beat" 2>/dev/null || true); echo "${b:-$(field start)}"; }
beat() { date +%s > "$L/beat"; }
# True when the Mac screen is locked (simulator UI runs stall then). Reads ioreg only (no python, so no developer-tools prompt). Unknown or non-macOS counts as unlocked.
# LANE_LOCK_SCREEN=locked|unlocked forces the answer, LANE_LOCK_SCREEN=file:<path> means locked while that file exists (tests); LANE_LOCK_SCREEN_OK=1 skips the check (package-only jobs).
screen_locked() {
  [ "${LANE_LOCK_SCREEN_OK:-}" = 1 ] && return 1
  case "${LANE_LOCK_SCREEN:-}" in locked) return 0;; unlocked) return 1;; file:*) [ -e "${LANE_LOCK_SCREEN#file:}" ]; return;; esac
  [ "$(uname)" = Darwin ] || return 1
  ioreg -n Root -d1 -a 2>/dev/null | grep -A1 -E 'CGSSessionScreenIsLocked|IOConsoleLocked' | grep -q '<true/>' && return 0
  return 1
}
case "${1:-}" in
 acquire) [ -n "${2:-}" ] && [ -n "${3:-}" ] || { echo "need lane and purpose" >&2; exit 2; }
  if [ -d "$L" ]; then s=$(field start); pid=$(field pid)
   # A hold with no beat file came from the old script (never beats): only a dead pid or the 45 min cap frees it.
   if [ -f "$L/beat" ]; then lb=$(lastbeat); cap=$BEAT; else lb=${s:-$now}; cap=$LEGACY; fi
   if [ -n "$s" ] && [ $((now - s)) -lt $MAX ] && [ $((now - lb)) -lt $cap ] && kill -0 "$pid" 2>/dev/null; then echo "BUSY: $(field lane) pid $pid held $((now - s))s, last beat $((now - lb))s ago: $(field purpose)"; exit 1; fi
   why="pid $pid"; kill -0 "$pid" 2>/dev/null && why="no heartbeat for $((now - lb))s (cap ${cap}s)"
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
  lane=$2; purpose=$3; shift 4; limit=$(( $(date +%s) + 3600 ))
  # Never start (or keep a fresh hold) while the screen is locked: UI runs stall and would sit on the lock.
  while :; do
   while screen_locked; do echo "$(date -u +%FT%TZ) screen locked, waiting ($lane)" | tee -a "$LOG"; [ "$(date +%s)" -lt "$limit" ] || { echo "TIMEOUT: screen still locked" >&2; exit 1; }; sleep 60; done
   "$0" wait "$lane" "$purpose" 3600 || exit 1
   screen_locked || break
   # Known limit: the hand-back drops our queue ticket, so after the screen unlocks this job rejoins at the back of the line.
   echo "$(date -u +%FT%TZ) screen locked after queueing, giving the lock back ($lane)" | tee -a "$LOG"; "$0" release "$lane" || true
  done
  # Watchdog: a job that is still running when the screen has been locked for LANE_LOCK_STALL ticks in a row (default 5 min), or that runs longer than
  # LANE_LOCK_JOB_MAX s (default 7200, the same cap that frees a stale hold), is stopped so it cannot sit on the lock. A tick is LANE_LOCK_TICK s (default 60).
  tick=${LANE_LOCK_TICK:-60}; stall=${LANE_LOCK_STALL:-5}; jobmax=${LANE_LOCK_JOB_MAX:-7200}; killed="/tmp/tessera-mac-lock.killed.$lane.$$"; rm -f "$killed"
  # Every descendant of a pid (test.sh -> subshell -> xcodebuild -> xctest), so none is left driving the simulator after the lock is released.
  kids() { for c in $(pgrep -P "$1" 2>/dev/null); do kids "$c"; echo "$c"; done; }
  "$@" & job=$!
  ( n=0; t=0
    while sleep "$tick"; do
     "$0" beat "$lane" || break
     t=$((t + tick)); if screen_locked; then n=$((n + 1)); else n=0; fi
     if [ "$n" -ge "$stall" ]; then r="screen locked for $((n * tick))s"; elif [ "$t" -ge "$jobmax" ]; then r="ran longer than ${jobmax}s"; else continue; fi
     echo "$(date -u +%FT%TZ) stopping job ($lane): $r" | tee -a "$LOG"; echo "$r" > "$killed"
     l="$(kids "$job") $job"; kill -TERM $l 2>/dev/null || true; sleep 10; kill -KILL $l 2>/dev/null || true; break
    done ) & hb=$!
  # Ctrl-C, TERM or HUP on this script stops the job tree and the watchdog and gives the lock back (async jobs ignore SIGINT, so they need this).
  trap 'l="$(kids "$job") $job"; kill -TERM $l 2>/dev/null || true; kill "$hb" 2>/dev/null || true; "$0" release "$lane" || true; exit 130' INT TERM HUP
  trap 'rm -f "$killed"' EXIT
  rc=0; wait "$job" || rc=$?
  # If the watchdog fired it is still in its 10 s grace before KILL: let it finish, then report.
  if [ -f "$killed" ]; then wait "$hb" || true; echo "STOPPED: $(cat "$killed")" >&2; rc=75; else kill "$hb" 2>/dev/null || true; fi
  "$0" release "$lane" || true; exit $rc;;
 release) if [ "$(field lane)" = "${2:-}" ]; then drop; echo released; else echo "not held by ${2:-}" >&2; exit 1; fi;;
 status) if [ -d "$L" ]; then cat "$F"; echo "age_s=$((now - $(field start))) beat_age_s=$((now - $(lastbeat)))"; else echo free; fi;;
 *) echo "usage: acquire|wait|beat|run|release|status" >&2; exit 2;;
esac
