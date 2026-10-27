#!/usr/bin/env bash
# Records that the targeted suites for a small change passed, in the build folder's gate.log, for an installer made
# with the "targeted" tier. Usage: scripts/ops/targeted_green.sh <build-folder> "<suite or test names that ran>" <log-file>...
# It refuses unless every log shows a passing run and none shows a failure. It never records a full gate.
set -euo pipefail
DIR="${1:?build folder}"; WHAT="${2:?what ran}"; shift 2
[[ $# -ge 1 ]] || { echo 'give at least one test log' >&2; exit 2; }
for log in "$@"; do
    grep -qE '\*\* TEST SUCCEEDED \*\*|Test run with [0-9]+ tests .* passed' "$log" || { echo "no passing run in $log" >&2; exit 1; }
    if grep -qE '✘|\*\* TEST FAILED \*\*|BUILD FAILED' "$log"; then echo "a failure is recorded in $log" >&2; exit 1; fi
done
{ echo "==> Targeted tests: $WHAT"; echo "==> Targeted green"; echo "(not the full gate: engine and app suites that cover the changed files only)"; } > "$DIR/gate.log"
echo 0 > "$DIR/gate.exit"
echo "recorded Targeted green in $DIR/gate.log"
