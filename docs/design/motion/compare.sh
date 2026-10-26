#!/usr/bin/env bash
# Frame-by-frame compare of a simulator recording against the lab's reference clip (motion item 10).
#   compare.sh <reference.mp4> <candidate.mp4> <out-dir> [beats "t1 t2 t3"] [crop x:y:w:h in points]
# Both clips are brought to 393 × 852 pt at 60 fps (the candidate's caption strip, if any, is cut), then:
#   1. ssim.txt: the per-frame SSIM of the soul crop (default: the bottom-right 160 × 160 pt), and the mean.
#   2. beats.png: at each beat time, the reference frame beside the candidate frame, one row per beat.
#   3. worst.txt: the ten frames with the lowest SSIM, as times, to look at first.
# Pass: mean SSIM >= 0.90 and no beat frame under 0.80. Timing is read from beats.png by eye: a beat that
# lands in the other clip's frame row more than 2 frames (33 ms) away is a timing miss.
set -euo pipefail
ref=$1; cand=$2; out=$3; beats=${4:-"1 2 3 4 5"}; crop=${5:-"233:692:160:160"}
mkdir -p "$out"
IFS=: read -r cx cy cw ch <<<"$crop"
norm="scale=786:-1:flags=lanczos,crop=786:1704:0:0,fps=60"
soul="crop=$((cw*2)):$((ch*2)):$((cx*2)):$((cy*2))"
ffmpeg -v error -y -i "$ref" -vf "$norm,$soul" -pix_fmt yuv420p "$out/ref-soul.mp4"
ffmpeg -v error -y -i "$cand" -vf "$norm,$soul" -pix_fmt yuv420p "$out/cand-soul.mp4"
ffmpeg -nostats -y -i "$out/ref-soul.mp4" -i "$out/cand-soul.mp4" -lavfi "ssim=stats_file=$out/ssim-frames.txt" -f null - 2>&1 | grep -o "All:[0-9.]*" | tail -1 > "$out/ssim.txt" || true
awk '{for(i=1;i<=NF;i++) if($i ~ /^All:/){split($i,a,":"); print (NR-1)/60, a[2]}}' "$out/ssim-frames.txt" | sort -k2 -n | head -10 > "$out/worst.txt"
rows=()
for b in $beats; do
  ffmpeg -v error -y -ss "$b" -i "$ref" -frames:v 1 -vf "$norm" "$out/ref-$b.png"
  ffmpeg -v error -y -ss "$b" -i "$cand" -frames:v 1 -vf "$norm" "$out/cand-$b.png"
  ffmpeg -v error -y -i "$out/ref-$b.png" -i "$out/cand-$b.png" -filter_complex "[0][1]hstack,scale=786:-1,drawtext=text='t=$b s':x=12:y=12:fontsize=28:fontcolor=white:box=1:boxcolor=black@0.5" "$out/row-$b.png"
  rows+=("$out/row-$b.png")
done
args=(); for r in "${rows[@]}"; do args+=(-i "$r"); done
if [ ${#rows[@]} -gt 1 ]; then
  ffmpeg -v error -y "${args[@]}" -filter_complex "$(printf '[%d]' $(seq 0 $((${#rows[@]}-1))))vstack=inputs=${#rows[@]}" "$out/beats.png"
else cp "${rows[0]}" "$out/beats.png"; fi
echo "mean SSIM of the soul crop: $(cat "$out/ssim.txt")"; echo "worst frames (time, ssim):"; cat "$out/worst.txt"
