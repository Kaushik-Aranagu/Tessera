#!/bin/sh
# Parallel build and test lanes for the shared Mac (extends lane_lock.sh; see docs/ops/mac-lanes.md).
# Usage: mac_lanes.sh run <lane> <purpose> [--sim] -- cmd...   wait for a free slot, run cmd with that slot's private build folders (and its own cloned simulator with --sim), always release
#        mac_lanes.sh device <lane> -- cmd...                  one phone install at a time (waits for the device lock)
#        mac_lanes.sh status | slots | sim <slot>              who holds what; print (and create) a slot's simulator id
# A slot is a directory /tmp/tessera-mac-slots.d/slot-N (mkdir is atomic). At most MAC_LANES_SLOTS (default 3) heavy jobs run at once.
# A hold is abandoned (freed, logged) when its pid is dead, it is older than 2 h, or it has had no heartbeat for 10 min.
# Each slot has its own DerivedData ($LANE_DERIVED), SwiftPM clone folder ($LANE_SPM), and, with --sim, its own simulator ($LANE_SIM, a clone named "Tessera Lane N").
# Never pkill by pattern: this script stops only the process tree of the job it started.
set -eu
D=${MAC_LANES_DIR:-/tmp/tessera-mac-slots.d}; Q="$D/q"; LOG=${MAC_LANES_LOG:-/tmp/tessera-mac-slots.log}
N=${MAC_LANES_SLOTS:-3}; MAX=7200; BEAT=600; MINGB=${MAC_LANES_MIN_GB:-6}; BASE_SIM=${MAC_LANES_BASE_SIM:-iPhone 17}
ROOT=${MAC_LANES_ROOT:-/tmp/tessera-lanes}
DEV=${MAC_LANES_DEVICE_LOCK:-/tmp/tessera-device-lock.d}
now=$(date +%s)
mkdir -p "$D" "$Q"
field() { sed -n "s/^$2=//p" "$D/slot-$1/info" 2>/dev/null || true; }
lastbeat() { b=$(cat "$D/slot-$1/beat" 2>/dev/null || true); echo "${b:-$(field "$1" start)}"; }
drop() { rm -f "$D/slot-$1/info" "$D/slot-$1/beat"; rmdir "$D/slot-$1" 2>/dev/null || true; }
# True when the Mac screen is locked (simulator UI runs stall then). Same rules as lane_lock.sh.
screen_locked() {
  case "${LANE_LOCK_SCREEN:-}" in locked) return 0;; unlocked) return 1;; file:*) [ -e "${LANE_LOCK_SCREEN#file:}" ]; return;; esac
  [ "$(uname)" = Darwin ] || return 1
  ioreg -n Root -d1 -a 2>/dev/null | grep -A1 -E 'CGSSessionScreenIsLocked|IOConsoleLocked' | grep -q '<true/>' && return 0
  return 1
}
free_gb() { df -k "${MAC_LANES_DISK:-/System/Volumes/Data}" 2>/dev/null | awk 'NR==2 {printf "%d", $4/1048576}' || echo 999; }
# Frees a slot whose hold is stale (dead pid, too old, or no heartbeat).
sweep() {
  i=1; while [ "$i" -le "$N" ]; do
    if [ -d "$D/slot-$i" ]; then s=$(field "$i" start); pid=$(field "$i" pid); lb=$(lastbeat "$i")
      if [ -z "$s" ] || [ $((now - s)) -ge $MAX ] || [ $((now - lb)) -ge $BEAT ] || ! kill -0 "$pid" 2>/dev/null; then
        echo "$(date -u +%FT%TZ) freed stale slot $i from $(field "$i" lane) (pid $pid, held $((now - ${s:-$now}))s): $(field "$i" purpose)" >> "$LOG"; drop "$i"; fi
    fi; i=$((i + 1)); done
}
# Takes the first free slot; prints its number. Returns 1 if all are busy.
take() {
  i=1; while [ "$i" -le "$N" ]; do
    if mkdir "$D/slot-$i" 2>/dev/null; then
      printf 'lane=%s\npid=%s\nstart=%s\nstart_iso=%s\npurpose=%s\n' "$1" "$2" "$now" "$(date -u +%FT%TZ)" "$3" > "$D/slot-$i/info"; date +%s > "$D/slot-$i/beat"; echo "$i"; return 0; fi
    i=$((i + 1)); done
  return 1
}
# The simulator id for a slot, cloned from the base device the first time. Prints the UDID.
sim_for() {
  name="Tessera Lane $1"
  udid=$(xcrun simctl list devices available 2>/dev/null | grep -F "$name (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/' || true)
  if [ -z "$udid" ]; then
    base=$(xcrun simctl list devices available 2>/dev/null | grep -F "$BASE_SIM (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/' || true)
    [ -n "$base" ] || { echo "no simulator named $BASE_SIM to clone" >&2; return 1; }
    udid=$(xcrun simctl clone "$base" "$name")
  fi
  echo "$udid"
}
kids() { for c in $(pgrep -P "$1" 2>/dev/null); do kids "$c"; echo "$c"; done; }
case "${1:-}" in
 run) [ -n "${2:-}" ] && [ -n "${3:-}" ] || { echo "usage: run <lane> <purpose> [--sim] -- cmd..." >&2; exit 2; }
  lane=$2; purpose=$3; shift 3; sim=0; [ "${1:-}" = "--sim" ] && { sim=1; shift; }
  [ "${1:-}" = "--" ] && [ -n "${2:-}" ] || { echo "usage: run <lane> <purpose> [--sim] -- cmd..." >&2; exit 2; }
  shift
  gb=$(free_gb); [ "$gb" -ge "$MINGB" ] || { echo "REFUSED: only ${gb} GB free on the data disk (need $MINGB). Free build folders first." >&2; exit 3; }
  # FIFO queue: a ticket is "<epoch>-<lane>" holding the waiter's pid; dead tickets are skipped. Polls every 15 s.
  T="$Q/$(date +%s)-$lane-$$"; echo "$$" > "$T"; end=$((now + ${MAC_LANES_WAIT:-7200})); slot=""
  while :; do
   now=$(date +%s); sweep
   head=""; for t in $(ls "$Q" 2>/dev/null); do kill -0 "$(cat "$Q/$t" 2>/dev/null)" 2>/dev/null && { head=$t; break; } || rm -f "$Q/$t"; done
   if [ "$head" = "$(basename "$T")" ]; then
     if [ "$sim" = 1 ] && screen_locked; then :; else slot=$(take "$lane" "$$" "$purpose") && break; fi
   fi
   [ "$(date +%s)" -lt "$end" ] || { rm -f "$T"; echo "TIMEOUT waiting for a slot" >&2; exit 1; }
   sleep "${MAC_LANES_POLL:-15}"; done
  rm -f "$T"
  export LANE_SLOT=$slot LANE_NAME=$lane LANE_DERIVED="$ROOT/slot-$slot/DerivedData" LANE_SPM="$ROOT/slot-$slot/SourcePackages"
  mkdir -p "$LANE_DERIVED" "$LANE_SPM"
  if [ "$sim" = 1 ]; then LANE_SIM=$(sim_for "$slot") || { drop "$slot"; exit 1; }; export LANE_SIM; fi
  echo "$(date -u +%FT%TZ) slot $slot taken by $lane: $purpose" >> "$LOG"
  "$@" & job=$!
  ( while sleep "${MAC_LANES_BEAT:-60}"; do date +%s > "$D/slot-$slot/beat" 2>/dev/null || break; done ) & hb=$!
  trap 'l="$(kids "$job") $job"; kill -TERM $l 2>/dev/null || true; kill "$hb" 2>/dev/null || true; drop "$slot"; exit 130' INT TERM HUP
  rc=0; wait "$job" || rc=$?
  kill "$hb" 2>/dev/null || true; drop "$slot"; echo "$(date -u +%FT%TZ) slot $slot released by $lane (rc $rc)" >> "$LOG"; exit $rc;;
 device) [ -n "${2:-}" ] && [ "${3:-}" = "--" ] && [ -n "${4:-}" ] || { echo "usage: device <lane> -- cmd..." >&2; exit 2; }
  lane=$2; shift 3
  # One phone install at a time. A hold is stale when its pid is dead or it is older than 30 min.
  end=$((now + ${MAC_LANES_WAIT:-3600}))
  while ! mkdir "$DEV" 2>/dev/null; do
   p=$(sed -n 's/^pid=//p' "$DEV/info" 2>/dev/null || true); s=$(sed -n 's/^start=//p' "$DEV/info" 2>/dev/null || true)
   if [ -z "$p" ] || ! kill -0 "$p" 2>/dev/null || [ $(( $(date +%s) - ${s:-0} )) -ge 1800 ]; then rm -f "$DEV/info"; rmdir "$DEV" 2>/dev/null || true; continue; fi
   [ "$(date +%s)" -lt "$end" ] || { echo "TIMEOUT waiting for the device lock" >&2; exit 1; }
   sleep "${MAC_LANES_POLL:-15}"; done
  printf 'lane=%s\npid=%s\nstart=%s\n' "$lane" "$$" "$(date +%s)" > "$DEV/info"
  trap 'rm -f "$DEV/info"; rmdir "$DEV" 2>/dev/null || true' EXIT INT TERM HUP
  "$@";;
 sim) [ -n "${2:-}" ] || { echo "usage: sim <slot>" >&2; exit 2; }; sim_for "$2";;
 slots) echo "$N";;
 status) sweep; i=1; busy=0
  while [ "$i" -le "$N" ]; do
   if [ -d "$D/slot-$i" ]; then busy=$((busy + 1)); echo "slot $i: $(field "$i" lane) pid $(field "$i" pid) held $((now - $(field "$i" start)))s: $(field "$i" purpose)"; else echo "slot $i: free"; fi
   i=$((i + 1)); done
  echo "busy $busy of $N, free disk $(free_gb) GB"
  [ -d "$DEV" ] && echo "device lock: $(sed -n 's/^lane=//p' "$DEV/info" 2>/dev/null)" || echo "device lock: free";;
 *) echo "usage: run|device|status|slots|sim" >&2; exit 2;;
esac
