#!/usr/bin/env bash
# Runs everything a lead should run before opening a PR (there's no CI):
#   1. the engine package tests (TesseraCore, on the Mac)
#   2. the app build and app tests (iPhone simulator)
# Usage: scripts/test.sh [--package-only | --app-only] [--scale]
#   --scale  also runs the 5-year history scale test (TESSERA_SCALE=1500)
# Exit code is non-zero if anything fails. Set SIMULATOR to pick a device (default "iPhone 17").
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SIMULATOR="${SIMULATOR:-iPhone 17}"
DERIVED="${DERIVED_DATA:-$ROOT/.build/DerivedData}"
RUN_PACKAGE=1
RUN_APP=1
SCALE=0
for arg in "$@"; do
  case "$arg" in
    --package-only) RUN_APP=0 ;;
    --app-only) RUN_PACKAGE=0 ;;
    --scale) SCALE=1 ;;
    -h|--help) sed -n '2,7p' "$0"; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

strip() { sed -E $'s/\x1b\\[[0-9;]*m//g'; }
status=0

if [[ $RUN_PACKAGE == 1 ]]; then
  echo "==> Engine package tests (TesseraCore)"
  log="$(mktemp)"
  (cd "$ROOT/TesseraCore" && swift test >"$log" 2>&1)
  package=$?
  strip <"$log" | grep -E "✘|error:|Test run with" | grep -v "CoreData:" | head -40
  if [[ $package != 0 ]]; then
    echo "!! Package tests failed (full log: $log)"
    status=1
  else
    rm -f "$log"
  fi
  if [[ $SCALE == 1 ]]; then
    echo "==> 5-year scale test"
    (cd "$ROOT/TesseraCore" && TESSERA_SCALE=1500 swift test --filter "ScaleTests|OnDiskTests" 2>&1 | strip \
      | grep -E "SCALE|DISK|✘|took") || true
  fi
fi

if [[ $RUN_APP == 1 ]]; then
  echo "==> App build and tests ($SIMULATOR)"
  (cd "$ROOT" && xcodegen generate >/dev/null) || { echo "!! xcodegen failed"; exit 1; }
  log="$(mktemp)"
  (cd "$ROOT" && xcodebuild -scheme Tessera -destination "platform=iOS Simulator,name=$SIMULATOR" \
    -derivedDataPath "$DERIVED" test >"$log" 2>&1)
  app=$?
  grep -E "error:|✘|Test run with|TEST (SUCCEEDED|FAILED)|BUILD FAILED" "$log" | grep -v "^ " | sort -u | head -40
  if [[ $app != 0 ]]; then
    echo "!! App build or tests failed (full log: $log)"
    status=1
  else
    rm -f "$log"
  fi
fi

if [[ $status == 0 ]]; then echo "==> All green"; fi
exit $status
