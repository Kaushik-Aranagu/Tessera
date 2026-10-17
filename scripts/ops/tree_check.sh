#!/bin/sh
# Stale-tree check from the merge recipe: the trial merge of HEAD into BASE must change exactly the
# files the branch changed since the merge base (an extra file means the merge reverts something).
# Usage: scripts/ops/tree_check.sh BASE HEAD     (refs or SHAs in the current clone; never checks out)
set -eu
base=${1:?base ref}; head=${2:?head ref}
mb=$(git merge-base "$base" "$head")
merged=$(git merge-tree --write-tree "$base" "$head") || { echo "STOP: merge conflicts"; exit 1; }
want=$(git diff --name-only "$mb" "$head" | sort)
got=$(git diff --name-only "$base" "$merged" | sort)
if [ "$want" = "$got" ]; then echo "RESULT CLEAN: merged tree touches exactly the branch's files"; exit 0; fi
echo "STOP: file lists differ (diff of branch files vs merged-tree files, paths only)"
printf '%s\n' "$want" > /tmp/.tc_want.$$; printf '%s\n' "$got" > /tmp/.tc_got.$$
diff /tmp/.tc_want.$$ /tmp/.tc_got.$$ || true; rm -f /tmp/.tc_want.$$ /tmp/.tc_got.$$
exit 1
