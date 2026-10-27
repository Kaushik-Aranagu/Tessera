#!/bin/bash
# shot.sh <html> <out.png> [width] [height] [ms]  - headless Chromium screenshot (standalone build from cdn.playwright.dev)
# REAL=1 waits in real time instead of virtual time. Use it for the Watch woodland (268 board, prototype watch.html):
# under --virtual-time-budget that page never settles and Chromium hangs until killed.
C=${CHROME:-/tmp/claude-49350/chromium/chrome-linux/chrome}
f=$(readlink -f "$1"); tmp=$(mktemp --suffix=.html -p "$(dirname "$f")")
# artifact pages have no skeleton; wrap so it renders like the published page
if ! grep -qi '<html' "$f"; then { printf '<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head><body>'; cat "$f"; printf '</body></html>'; } > "$tmp"; else cp "$f" "$tmp"; fi
timeout 90 "$C" --headless=new --no-sandbox --disable-gpu --hide-scrollbars --force-device-scale-factor=${DSF:-2} --window-size=${3:-1400},${4:-1200} $( [ "${REAL:-0}" = 1 ] && echo --timeout=${5:-3000} || echo --virtual-time-budget=${5:-3000} ) --screenshot="$(readlink -f "$2")" "file://$tmp${QS:-}" 2>&1 | grep -E "written|ERROR:.*(js|console)" ; rm -f "$tmp"
