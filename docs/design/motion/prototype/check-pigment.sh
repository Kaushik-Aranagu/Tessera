#!/usr/bin/env bash
# Never-diffused check (tess-motion-check.md section 6, item 2): the soul's average colour in a sleep clip must match
# the Idle clip within 2% per channel. Usage: check-pigment.sh <idle.mp4> <sleep.mp4> [crop=W:H:X:Y] [time-seconds]
# The crop defaults to the soul box of the 390 x 844 scene at dpr 2 (centre of the dock); pass the real box if it moves.
set -euo pipefail
idle=${1:?idle clip}; sleep_clip=${2:?sleep clip}
crop=${3:-crop=240:240:270:1300}; at=${4:-1.0}
rgb() { ffmpeg -v error -ss "$at" -i "$1" -frames:v 1 -vf "$crop,scale=1:1" -f rawvideo -pix_fmt rgb24 - | od -An -tu1 | tr -s ' ' | sed 's/^ //'; }
a=$(rgb "$idle"); b=$(rgb "$sleep_clip")
read -r ar ag ab <<<"$a"; read -r br bg bb <<<"$b"
fail=0
for pair in "R $ar $br" "G $ag $bg" "B $ab $bb"; do
  set -- $pair
  diff=$(( $2 > $3 ? $2 - $3 : $3 - $2 ))
  pct=$(( diff * 100 / 255 ))
  echo "$1: idle $2, sleep $3, diff ${pct}%"
  [ "$pct" -gt 2 ] && fail=1
done
if [ "$fail" -eq 0 ]; then echo "PASS: sleep keeps full pigment"; else echo "FIX FIRST: sleep pigment differs by more than 2%"; exit 1; fi
