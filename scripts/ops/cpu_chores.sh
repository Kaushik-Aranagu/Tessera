#!/bin/sh
# Zero-token chores: checks that need a CPU, not a model (see docs/ops/cpu-chores.md).
# Usage: scripts/ops/cpu_chores.sh [--docs] [--package] [--scale]      (no flag = --docs --package)
#   --docs     docs index check + board/memory staleness (stdlib python, seconds)
#   --package  TesseraCore `swift test` (macOS with swift only; no simulator, so no lane lock needed)
#   --scale    with --package, also the 5-year history test
# Writes the report to /tmp/tessera-chores/last.txt and prints one summary line per step.
# Exit 1 only when the package tests fail; docs/staleness findings are counted, not failed.
set -u
ROOT=$(cd "$(dirname "$0")/../.." && pwd); OUT=/tmp/tessera-chores; mkdir -p "$OUT"; R="$OUT/last.txt"
docs=0; pkg=0; scale=0
for a in "$@"; do case "$a" in --docs) docs=1;; --package) pkg=1;; --scale) scale=1; pkg=1;; *) echo "usage: $0 [--docs] [--package] [--scale]" >&2; exit 2;; esac; done
[ $((docs + pkg)) -gt 0 ] || { docs=1; pkg=1; }
: > "$R"; status=0
step() { # name, command...
  n=$1; shift; t=$(date +%s); "$@" >> "$R" 2>&1; rc=$?; echo "$n rc=$rc $(( $(date +%s) - t ))s"; return $rc; }
cd "$ROOT" || exit 2
if [ $docs = 1 ]; then
  echo "== docs index" >> "$R"; python3 -B -I scripts/ops/docs_index_check.py . >> "$R" 2>&1
  echo "docs-index: $(grep -E '^summary:' "$R" | tail -1)"
  echo "== staleness" >> "$R"; git log --oneline | python3 -B -I scripts/ops/staleness.py >> "$R" 2>&1
  echo "staleness: $(grep -cE '^STALE' "$R") stale lines"
fi
if [ $pkg = 1 ]; then
  if [ "$(uname)" = Darwin ] && command -v swift >/dev/null 2>&1; then
    echo "== package tests" >> "$R"
    step "package-tests" sh -c 'cd TesseraCore && swift test' || status=1
    if [ $scale = 1 ]; then step "scale-test" sh -c 'cd TesseraCore && TESSERA_SCALE=1500 swift test --filter "ScaleTests|OnDiskTests"' || status=1; fi
  else
    echo "package-tests: skipped (needs macOS with swift)"
  fi
fi
echo "report: $R"
exit $status
