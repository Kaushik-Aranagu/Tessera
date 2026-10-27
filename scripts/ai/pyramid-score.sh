#!/usr/bin/env bash
# The live P1b score for the memory pyramid (docs/ai/harness/memory-pyramid.md): Haiku writes the test world's gists,
# then answers each question three ways (flat, zoom, zoom with gists). Writes eval-runs/<date>-pyramid-<policy>.json.
#
#   scripts/ai/pyramid-score.sh [--policy strict|lab] [--months N] [--phone-spent DOLLARS] [--out DIR] [--dry]
#
# --dry answers with a scripted brain: nothing leaves the Mac and nothing is spent. Without it this SPENDS MONEY on the
# Claude API, from the key in the Mac keychain (the key is never printed or written). The allowance is the live
# runner's: the smaller of $50 and ($100 minus --phone-spent), minus what the runners spent this month in
# ~/Library/Application Support/TessEval/ledger.json, which this run adds to. Run it after a live runner run, not
# beside one.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
policy=strict
months=6
phone=""
out=""
dry=0
while [ $# -gt 0 ]; do
  case "$1" in
    --policy) policy="$2"; shift 2 ;;
    --months) months="$2"; shift 2 ;;
    --phone-spent) phone="$2"; shift 2 ;;
    --out) out="$2"; shift 2 ;;
    --dry) dry=1; shift ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
case "$policy" in lab|strict) ;; *) echo "--policy must be lab or strict" >&2; exit 2 ;; esac
case "$months" in ''|*[!0-9]*) echo "--months must be a whole number" >&2; exit 2 ;; esac
# A live run must be told what the phone spent this month: assuming 0 could take him past his $100 cap.
if [ "$dry" != 1 ] && [ -z "$phone" ]; then
  echo "a live run needs --phone-spent DOLLARS (the phone's Claude spend this month); use --dry for a free run" >&2
  exit 2
fi

# Never anywhere near the app's own data.
app="$HOME/Library/Application Support/Tessera"
if [ -n "$out" ]; then
  case "$(cd "$(dirname "$out")" 2>/dev/null && pwd)/$(basename "$out")" in
    "$app"*) echo "refusing an output folder inside the app's data folder" >&2; exit 2 ;;
  esac
fi

export TESSERA_PYRAMID_SCORE=1
export TESSERA_PYRAMID_POLICY="$policy"
export TESSERA_PYRAMID_MONTHS="$months"
export TESSERA_PYRAMID_PHONE_SPENT="$phone"
[ -n "$out" ] && export TESSERA_PYRAMID_OUT="$out"
[ "$dry" = 1 ] && export TESSERA_PYRAMID_DRY=1

cd "$root/TesseraCore"
if [ -x "$root/scripts/ops/mac_lanes.sh" ]; then
  exec "$root/scripts/ops/mac_lanes.sh" run core-ai "pyramid-score $policy" -- swift test --filter PyramidLiveScoreTests
fi
exec swift test --filter PyramidLiveScoreTests
