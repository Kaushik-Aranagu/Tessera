#!/bin/sh
# Self-test for mac_lanes.sh: slot limit, queue order, env, stale takeover, disk refusal, device lock. No xcodebuild, no simulator.
set -eu
H="$(cd "$(dirname "$0")" && pwd)/mac_lanes.sh"
T=$(mktemp -d); export MAC_LANES_DIR="$T/slots" MAC_LANES_LOG="$T/log" MAC_LANES_ROOT="$T/lanes" MAC_LANES_DEVICE_LOCK="$T/dev.d" MAC_LANES_SLOTS=2 MAC_LANES_POLL=1 MAC_LANES_BEAT=1 MAC_LANES_MIN_GB=0
fail=0; ok() { echo "ok   $1"; }; bad() { echo "FAIL $1"; fail=1; }
# Two jobs run at once, the third waits for a slot.
"$H" run a "one" -- sh -c 'echo "$LANE_SLOT $LANE_DERIVED" > "$0/a.out"; sleep 5' "$T" & p1=$!
"$H" run b "two" -- sh -c 'echo "$LANE_SLOT $LANE_DERIVED" > "$0/b.out"; sleep 5' "$T" & p2=$!
sleep 3
"$H" run c "three" -- sh -c 'date +%s > "$0/c.out"' "$T" & p3=$!
sleep 1
[ -f "$T/a.out" ] && [ -f "$T/b.out" ] && ok "two jobs started together" || bad "two jobs started together"
[ ! -f "$T/c.out" ] && ok "third waits while both slots are busy" || bad "third waits"
[ "$(cut -d' ' -f1 "$T/a.out")" != "$(cut -d' ' -f1 "$T/b.out")" ] && ok "different slots" || bad "different slots"
[ "$(cut -d' ' -f2 "$T/a.out")" != "$(cut -d' ' -f2 "$T/b.out")" ] && ok "private DerivedData per slot" || bad "private DerivedData"
"$H" status | grep -q "busy 2 of 2" && ok "status shows both busy" || bad "status"
wait $p1 $p2 $p3 || true
[ -f "$T/c.out" ] && ok "third ran after a slot freed" || bad "third ran"
"$H" status | grep -q "busy 0 of 2" && ok "all slots released" || bad "slots released"
# A dead holder is freed.
mkdir -p "$T/slots/slot-1"; printf 'lane=ghost\npid=999999\nstart=%s\npurpose=dead\n' "$(date +%s)" > "$T/slots/slot-1/info"; date +%s > "$T/slots/slot-1/beat"
"$H" run d "after ghost" -- true && grep -q "freed stale slot 1" "$T/log" && ok "dead holder freed" || bad "dead holder freed"
# Exit codes pass through.
rc=0; "$H" run e "rc" -- sh -c 'exit 7' || rc=$?; [ "$rc" = 7 ] && ok "exit code passes through" || bad "exit code ($rc)"
# Disk guard.
rc=0; MAC_LANES_MIN_GB=99999999 "$H" run f "disk" -- true >/dev/null 2>&1 || rc=$?; [ "$rc" = 3 ] && ok "refuses when the disk is nearly full" || bad "disk guard ($rc)"
# Device lock: one at a time.
"$H" device x -- sh -c 'sleep 3' & d1=$!; sleep 1
s=$(date +%s); "$H" device y -- true; e=$(date +%s)
[ $((e - s)) -ge 1 ] && ok "second phone install waited" || bad "device lock"
wait $d1 || true
rm -rf "$T"; [ $fail = 0 ] && echo "All green" || { echo "FAILED"; exit 1; }
