#!/bin/sh
# Builds docs/handoff/INDEX.md for the Codex handoff and pushes it to the branch handoff/index.
# Usage: scripts/ops/codex_handoff.sh [--no-push]
# It collects every docs/handoff/*.md (each lane writes its own), lists open PRs with head, base and the latest QA verdict where the
# board knows one (scripts/ops/verdicts.py), and prints the mac_lanes slot state. Safe to run from cron or by hand after we stop:
# it works in a throwaway clone of origin/master, never touches your working tree, writes no secrets, and force-pushes only
# the handoff/index branch.
set -eu
PUSH=1; [ "${1:-}" = "--no-push" ] && PUSH=0
REPO=${HANDOFF_REPO:-Kaushik-Aranagu/Tessera}
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$(cd "$HERE/../.." && pwd)"
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
git -C "$SRC" fetch -q origin master 2>/dev/null || true
git clone -q --no-checkout "$SRC" "$W/repo" 2>/dev/null
cd "$W/repo"
REMOTE=$(git -C "$SRC" remote get-url origin)
git remote set-url origin "$REMOTE"
git fetch -q origin master
git checkout -q -B handoff/index origin/master
mkdir -p docs/handoff
OUT=docs/handoff/INDEX.md
now=$(date -u +%FT%TZ)
{
  echo "# Handoff index"
  echo
  echo "Generated $now by scripts/ops/codex_handoff.sh from origin/master $(git rev-parse --short=8 origin/master). Read the lane notes first, then the open PRs."
  echo
  echo "## Lane notes"
  echo
  found=0
  for f in docs/handoff/*.md; do
    [ -e "$f" ] || continue
    [ "$(basename "$f")" = INDEX.md ] && continue
    found=1
    echo "- [$(basename "$f" .md)]($(basename "$f")): $(sed -n '1s/^# *//p' "$f")"
  done
  [ $found = 1 ] || echo "(none merged yet; lane notes on open PRs are listed below)"
  echo
  echo "## Open PRs (head, base, latest QA verdict)"
  echo
  verd="$W/verdicts.txt"; : > "$verd"
  [ -f scripts/ops/verdicts.py ] && git show origin/master:docs/ops/board/qa.md > /dev/null 2>&1 && python3 scripts/ops/verdicts.py . > "$verd" 2>/dev/null || true
  if command -v gh >/dev/null 2>&1; then
    gh pr list -R "$REPO" --state open --limit 100 --json number,title,headRefName,baseRefName,headRefOid,isDraft \
      --jq '.[] | "\(.number)\t\(.headRefName)\t\(.baseRefName)\t\(.headRefOid[0:8])\t\(.title)"' 2>/dev/null | sort -n | while IFS="$(printf '\t')" read -r n head base sha title; do
      v=$(grep -E "^[# ]*$n[ \t]" "$verd" 2>/dev/null | head -1 | sed 's/[ \t][ \t]*/ /g' || true)
      echo "- #$n \`$head\` <- \`$base\` @ $sha: $title${v:+ (QA: $v)}"
    done
  else
    echo "(gh is not installed; list open PRs on GitHub)"
  fi
  echo
  echo "## Mac lanes"
  echo
  echo '```'
  if [ -x "$SRC/scripts/ops/mac_lanes.sh" ]; then "$SRC/scripts/ops/mac_lanes.sh" status 2>&1 || true; else echo "mac_lanes.sh not found"; fi
  echo '```'
} > "$OUT"
if [ $PUSH = 1 ]; then
  git add "$OUT"
  git -c user.name="handoff" -c user.email="handoff@users.noreply.github.com" commit -q -m "Handoff index $now" 2>/dev/null || { echo "index unchanged"; exit 0; }
  git push -q --force-with-lease origin handoff/index 2>/dev/null || git push -q --force origin handoff/index
  echo "pushed handoff/index at $(git rev-parse --short=8 HEAD)"
else
  cat "$OUT"
fi
