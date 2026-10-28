#!/usr/bin/env bash
# The live run of the Chart room's 20-sentence eval (RoomEvalCorpus): each sentence goes through the room job, and every
# call goes through the Door and its ledger. Writes eval-runs/<date>-room-<model>.json.
#
#   scripts/ai/room-eval.sh [--model haiku|sonnet] [--phone-spent DOLLARS] [--out DIR] [--dry]
#
# --dry answers each sentence with its golden patch from a scripted brain: nothing leaves the Mac and nothing is spent.
# Without it this SPENDS MONEY on the Claude API, from the key in the Mac keychain (the key is never printed or
# written). The allowance is the smaller of $50 and ($100 minus --phone-spent minus the simulator's reserved $20),
# minus what the runners spent this month in ~/Library/Application Support/TessEval/ledger.json, which this run adds to
# under its lock.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
model=haiku
phone=""
out=""
dry=0
while [ $# -gt 0 ]; do
  case "$1" in
    --model) model="$2"; shift 2 ;;
    --phone-spent) phone="$2"; shift 2 ;;
    --out) out="$2"; shift 2 ;;
    --dry) dry=1; shift ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
case "$model" in haiku|sonnet) ;; *) echo "--model must be haiku or sonnet" >&2; exit 2 ;; esac
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

export TESSERA_ROOM_EVAL=1
export TESSERA_ROOM_MODEL="$model"
export TESSERA_ROOM_PHONE_SPENT="$phone"
[ -n "$out" ] && export TESSERA_ROOM_OUT="$out"
[ "$dry" = 1 ] && export TESSERA_ROOM_DRY=1

cd "$root/TesseraCore"
if [ -x "$root/scripts/ops/mac_lanes.sh" ]; then
  exec "$root/scripts/ops/mac_lanes.sh" run core-ai "room-eval $model" -- swift test --filter RoomLiveEvalTests
fi
exec swift test --filter RoomLiveEvalTests
