#!/usr/bin/env bash
# One command per picks PR: check-pick.sh <pick> <candidate.mp4> [out-dir]
# Runs compare.sh against recordings/picks/tess-pick-<pick>.mp4 at that pick's beat times (tess-motion-check.md),
# then prints the mean SSIM, the worst beat-frame SSIM and PASS or FIX FIRST (mean >= 0.90, no beat frame < 0.80).
set -euo pipefail
pick=$1; cand=$2; out=${3:-/tmp/check-$pick}
here=$(cd "$(dirname "$0")" && pwd)
ref="$here/../../recordings/picks/tess-pick-$pick.mp4"
case $pick in
  wander) beats="0.6 1.7 2.42 3.14 5.2 5.98" ;;
  wake) beats="1.0 1.4 1.5 2.1 3.4" ;;
  stroke) beats="1.4 1.75 1.8 3.0" ;;
  wear) beats="1.32 2.52 3.72 4.92 6.12" ;;
  mouth) beats="1.0 2.5 4.0 6.6 8.0 10.0 12.4" ;;
  sleep) beats="2.85 3.8 5.0" ;;
  held) beats="1.0 2.4 3.6 3.8" ;;
  clock) beats="1.8 4.2 4.3" ;;
  nudge) beats="1.6 2.9 3.3" ;;
  typing) beats="0.96 1.33 1.6 1.96" ;;
  peek) beats="2.2 3.6 3.9" ;;
  tilt) beats="3.1" ;;
  side) beats="1.0 1.42 2.8 4.6 6.2 6.88" ;;
  *) echo "unknown pick $pick"; exit 2 ;;
esac
crop=${CROP:-}
[ "$pick" = typing ] && crop=${crop:-"156:658:160:160"}
"$here/compare.sh" "$ref" "$cand" "$out" "$beats" ${crop:+$crop} >/dev/null
mean=$(sed 's/All://' "$out/ssim.txt")
worst=1
for b in $beats; do
  s=$(awk -v t="$b" '{for(i=1;i<=NF;i++) if($i ~ /^All:/){split($i,a,":"); f=NR-1; if (f==int(t*60+0.5)) print a[2]}}' "$out/ssim-frames.txt")
  [ -n "$s" ] && worst=$(awk -v a="$worst" -v b="$s" 'BEGIN{print (b<a)?b:a}')
done
verdict=$(awk -v m="$mean" -v w="$worst" 'BEGIN{print (m>=0.90 && w>=0.80)?"PASS":"FIX FIRST"}')
echo "$pick: mean SSIM $mean, worst beat frame $worst, beats $beats -> $verdict (look at $out/beats.png for timing)"
