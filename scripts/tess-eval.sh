#!/usr/bin/env bash
# The live runner (docs/ai/harness/test-world.md section 3): runs the test world's questions through Tess and writes
# eval-runs/<date>-<world>-<policy>.json.
#
#   scripts/tess-eval.sh --world small|big --policy lab|strict [--kinds lookUp,count] [--phone-spent DOLLARS]
#                        [--out DIR] [--dry]
#
# --dry answers with a scripted brain: nothing leaves the Mac and nothing is spent. Without it this SPENDS MONEY on the
# Claude API, from the key in the Mac keychain (item com.kaushikaranagu.tessera.anthropic / api-key; the key is never
# printed or written). The month's allowance is the smaller of $50 and ($100 minus --phone-spent), minus what earlier
# runs spent this month (eval-runs/ledger.json); a call that would pass it is refused before it is sent.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
world=small
policy=lab
kinds=""
phone=0
out=""
dry=0
while [ $# -gt 0 ]; do
  case "$1" in
    --world) world="$2"; shift 2 ;;
    --policy) policy="$2"; shift 2 ;;
    --kinds) kinds="$2"; shift 2 ;;
    --phone-spent) phone="$2"; shift 2 ;;
    --out) out="$2"; shift 2 ;;
    --dry) dry=1; shift ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
case "$world" in small|big) ;; *) echo "--world must be small or big" >&2; exit 2 ;; esac
case "$policy" in lab|strict) ;; *) echo "--policy must be lab or strict" >&2; exit 2 ;; esac

# Never anywhere near the app's own data.
app="$HOME/Library/Application Support/Tessera"
if [ -n "$out" ]; then
  case "$(cd "$(dirname "$out")" 2>/dev/null && pwd)/$(basename "$out")" in
    "$app"*) echo "refusing an output folder inside the app's data folder" >&2; exit 2 ;;
  esac
fi

export TESSERA_LIVE_EVAL=1
export TESSERA_EVAL_WORLD="$world"
export TESSERA_EVAL_POLICY="$policy"
export TESSERA_EVAL_KINDS="$kinds"
export TESSERA_EVAL_PHONE_SPENT="$phone"
[ -n "$out" ] && export TESSERA_EVAL_OUT="$out"
[ "$dry" = 1 ] && export TESSERA_EVAL_DRY=1

# Heavy jobs go through the Mac lanes (3 slots, own build folders).
cd "$root/TesseraCore"
if [ -x "$root/scripts/ops/mac_lanes.sh" ]; then
  exec "$root/scripts/ops/mac_lanes.sh" run core-ai "tess-eval $world $policy" -- swift test --filter TessLiveEvalTests
fi
exec swift test --filter TessLiveEvalTests
