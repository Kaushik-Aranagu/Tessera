# Install-commit check (5 minutes, coordinator)

*Research, board item 43, Oct 15, 6:20 PM Pacific. Run it in the cloud container for every install commit,
before posting "ready to install" and before Kaushik says "install it". Read-only git only; no Swift needed.
Verified on the real range 34665f0..3f124ee (worked example at the end).*

Set once per check (repo at /home/claude/Tessera, guide at product/review-session.md):

```bash
cd /home/claude/Tessera && git fetch -q origin
LAST_INSTALL=34665f0          # the commit on the phone now (from the last build message)
CANDIDATE=origin/master       # or the branch tip / sha the Mac builder names
G=/mnt/project-files/tessera/product/review-session.md; Q=/mnt/project-files/tessera/qa
S=/tmp/claude-0/-home-claude/a21dc68c-0951-5bbf-9e1c-7675729e9a02/scratchpad   # any scratch dir
```

## Tagging convention (Product keeps it; the greps rely on it)

- Every numbered item under "## What to try" ends with its PRs in brackets: `[#116 #151]`.
  Work not merged yet: `[branch ios/now-rank]` (swap for `[#NNN]` once the PR opens). Items already on the
  last install: `[base]`.
- Every known gap ends with the PR that fixes it, inside the italics: `... Undo fixes them. [fix #172]*`.
  No fix queued: `[fix none]`. Fix on a branch: `[fix branch core/day-boundary]`.
- QA reviews stay `review-<PR>.md` (or `review-<A>-<B>.md`); a PR covered inside another review is named in it.

## 1. Resolve and confirm ancestry (30 s)

```bash
C=$(git rev-parse --short "$CANDIDATE"); echo "candidate $C"
git merge-base --is-ancestor $LAST_INSTALL $C && echo "ancestor OK" || echo "STOP: $LAST_INSTALL not in $C"
git merge-base --is-ancestor $C origin/master && echo "on master" || echo "branch build: do step 5 carefully"
TZ=America/Los_Angeles git log -1 --format='%h %ad %s' --date=format-local:'%b %-d, %-I:%M %p PT' $C
```
Look for: "ancestor OK". A branch build is allowed (rest-day hookup) but must pass step 5.

## 2. Merged PRs in range, code vs docs (45 s)

```bash
git log --first-parent --merges --format='%h %s' $LAST_INSTALL..$C | while read h _ _ _ pr _; do
  n=$(git diff --name-only $h^1 $h | grep -vcE '^docs/|\.md$')
  echo "$pr $h $([ $n -gt 0 ] && echo CODE || echo docs) $(git diff --shortstat $h^1 $h)"; done | tee $S/r.txt
grep -c CODE $S/r.txt; git log --first-parent --no-merges --oneline $LAST_INSTALL..$C   # direct pushes
```
Look for: the CODE list (only these change the phone). The newest CODE line is "last code PR"; any install
between it and master is the same app. Direct pushes should be empty; if not, read them.

## 3. Review items vs the build (60 s)

```bash
git log --first-parent --format=%s $C | grep -oE '#[0-9]+' | sort -u > $S/in.txt   # every PR in the build
echo "== Not in this build"; awk '/^## What to try/{f=1;next} /^## /{f=0} f && /^[0-9]+\. /' $G \
 | grep -oE '^[0-9]+|\[[^]]+\]$' | paste - - | while IFS=$'\t' read n tag; do case "$tag" in *base*) continue;; esac
   miss=$(echo "$tag" | grep -oE 'branch [^] ]+|#[0-9]+' | grep -vxF -f $S/in.txt | tr '\n' ' ')
   [ -n "$miss" ] && echo "item $n: $miss"; done
echo "== Code PRs with no item (ask Product)"; for pr in $(awk '$3=="CODE"{print $1}' $S/r.txt); do
  grep -qE "\[[^]]*$pr\b" $G || echo -n "$pr "; done; echo
```
Look for: every "item N" goes to the guide's "Not in this build" (or is cut). An item whose line has no tag
at all prints nothing, so also run `awk '/^## What to try/{f=1;next} /^## /{f=0} f && /^[0-9]+\. / && !/\]$/' $G`
(untagged items; Product must tag them). PRs with no item are fine when engine-only or look-and-feel; say so.
For a branch build, the branch's items are in: check its tip is `$C` (step 1).

## 4. Known gaps now fixed (30 s)

```bash
grep -E '^- \*.*\[fix ' $G | grep -oE '\[fix [^]]+\]' | while read t; do p=$(echo "$t" | grep -oE '#[0-9]+')
  [ -n "$p" ] && grep -qxF "$p" $S/in.txt && echo "DROP $t" || echo "keep $t"; done
```
Look for: DROP lines go to "Drop these known gaps" for Product. Also scan the newest QA review for new
should-fixes (G-numbers) that belong in the gaps list.

## 5. Stale-branch check (45 s)

```bash
git diff --diff-filter=D --name-only $LAST_INSTALL $C | grep -vE '^docs/|\.md$'        # files leaving the app
for h in $(awk '$3=="CODE"{print $2}' $S/r.txt); do git diff --numstat $h^1 $h | awk -v h=$h '$2-$1>50{print h,$0}'; done
# branch builds only: what master has that the build lacks
echo "behind master: $(git rev-list --count $C..origin/master)"
git diff --stat --diff-filter=D origin/master $C -- . ':!docs' ':!*.md'
```
Look for: any deleted Swift file nobody announced (the NowRanker.swift lesson), and big net deletions in one
merge. A branch "behind master" is fine only when the last diff is empty (behind on docs only). Otherwise the
builder merges master into the branch first.

## 6. QA and test runs (60 s)

```bash
for pr in $(awk '$3=="CODE"{print substr($1,2)}' $S/r.txt); do f=$(ls $Q | grep -E "review-([0-9]+-)*$pr([-.]|$)")
  [ -z "$f" ] && f=$(grep -lE "#$pr\b" $Q/*.md | xargs -r -n1 basename | tr '\n' ' ' | sed 's/^./(in) &/')
  echo "#$pr ${f:-NO QA REVIEW}"; done
git diff --name-only $LAST_INSTALL $C | grep -E '^TesseraCore/' | head -1   # non-empty: full run, not --app-only
git diff --name-only $LAST_INSTALL $C | grep -E 'UITests/' | head -3        # non-empty: manual UI scheme run
```
Look for: "NO QA REVIEW" means ask QA before install (an "(in)" hit means another review mentions it; open it
to confirm it reviewed, not just named, the PR). Then ask the Mac for, on exactly `$C`:
`git checkout $C && scripts/test.sh` (full; add `--scale` if `TesseraCore/Model` changed), reply with the
last line and `git rev-parse --short HEAD`. Accept only "All green" with the same sha. If UITests changed:
`xcodebuild -scheme TesseraUITests -destination 'platform=iOS Simulator,name=iPhone 17' test`.

## 7. Message to Product and the iOS build thread (30 s)

```
Build: <C> (<subject>), merged <time> PT; over <LAST_INSTALL>. Last code PR #<N>.
In: <code PRs>; guide items <list> (all tagged PRs in the build).
Not in this build: items <n>: <branch/PR>; move them to the guide's "Not in this build".
Gaps: drop <fix tags now merged>; keep the rest. Product to tag: <PRs with no item / untagged items>.
QA: reviews for <list>; missing <list>. Stale check: <clean / what>.
Tests: scripts/test.sh on <C>: <All green | pending | fail line>; UI scheme <run/not needed>. Install waits on Kaushik's "install it".
```

## Worked example: 34665f0..3f124ee (run Oct 15, 6:16 PM PT)

The live guide has no tags yet, so step 3/4 ran on a scratch copy tagged from review-refresh.md.

- Step 1: `ancestor OK`, `on master`, `3f124ee Oct 15, 6:06 PM PT Merge pull request #169`.
  (origin/master has since moved to 9b85986, #170, docs.)
- Step 2: 55 merges, `18` CODE, no direct pushes. Top of the CODE list:
  `#151 927608d CODE 5 files changed, 223 insertions(+), 36 deletions(-)` then #153, #146, #147, #141, #134,
  #132, #131, #128, #126, #124, #122, #121, #120, #109, #118, #117, #116.
- Step 3: `item 4: branch ios/now-rank` (the rest-day line). Code PRs with no item: `#147 #141 #132 #128`
  (UNDO colour is a look-and-feel line; the other three are engine only). Matches review-refresh.md.
- Step 4 (gaps tagged `[fix none]`, `[fix #172]`, `[fix branch core/day-boundary]`): all `keep`. A gap tagged
  `[fix #153]` prints `DROP`.
- Step 5: no deleted files in range. Big net deletions: `794981a 7 71 Features/Workout/WorkoutParts.swift`
  (#134) and `0f183ae 8 90 Features/Home/NowPage.swift` (#116), both rewrites, known. Branch build
  `origin/ios/now-rank` (eaa77f0): behind master by 38, but no code deletions and a code diff of
  `2 files changed, 59 insertions(+), 1 deletion(-)`, so it is behind on docs only.
- Step 6: QA reviews for 12 of 18; #131, #128, #126 are in review-124.md, #121 in review-107-108.md, #120 in
  review-118.md, #117 in review-109.md and review-115.md. TesseraCore changed: full run. UITests changed (#151):
  run TesseraUITests once.
