# Mac lead handoff notes (repo; Mac leads edit this file)

Mac sessions cannot write the project folder, so each Mac lead writes or corrects its own section here before it rotates. Ops drafted these on Oct 17 from the boards and the QA gate table; every item marked UNVERIFIED needs the lead to confirm. Read with: git show origin/master:docs/ops/handoff-notes.md.

## Core (DRAFT, lead to confirm)
- Role and scope: Core engine lead for the TesseraCore package and its app call sites; routing goes through the coordinator (ops/core-handoff.md:2).
- Open PRs (all wait only on test.sh at the head; qa/release-14-gate-table.md):
  - #871 copy phrase + starter lists, branch: ask coordinator, head 34fc9650b4e6bc62564fe3a350bee9760b9c37e7 (:81). Next: requeue the lane-lock run, which timed out.
  - #884 capture-miss lows, branch: ask coordinator, head 5665c6006adb5e094c257c600b4344316cbb4dba (:82). Next: test.sh; docs #891 merges after it.
  - #886 recipe parser, branch: ask coordinator, head 97d00ff5ff2ae8b0e5d38093399d2d8b4ba792f4 (:84). Next: requeue test.sh (run timed out).
  - #890 G105 private-title check, branch: ask coordinator, head 398090688939cdf9827b90639569253802de5954 (:85). Next: test.sh; merge BEFORE #912 and before core/g105b.
  - core/g105b, head 221d7444 (short SHA only, :85), no PR yet. Needs #890 merged first (:90).
  - #407 (v10), branch: ask coordinator, head: ask coordinator. Merges only after the riders pin is on his phone (/tmp/claude/memory/team/silo/pr-open.md:17).
  - Owner of #917 (head be05f0b6ef23475069d3648c61014353d1c3c234, gate table :97) is UNVERIFIED; confirm with the coordinator.
- Frozen PRs (no pushes once a number is sent until it lands; ops/offline-mac-playbook.md:11): #871, #884, #886, #890 (#886 "stays frozen at 97d00ff5", ops/board/core.md:409; #890 "frozen", gate table :85). Push only for a requested fix.
- Promised next work (ops/board/core.md:409-419 are the newest orders; Next list at :121-125 is Oct 16 vintage, UNVERIFIED as still open):
  1. Next PR adds size words (small, medium, large, extra-large, whole, half) to the title rule, with a test (core.md:409; gate table :95).
  2. G139/G140/G142: Pantry mask at source, sticky "Private item" (core.md:407, :411).
  3. Name the lastUsedAt accessor, written at cook finish (core.md:413, :417).
  4. Pantry v2 R1-R20: derivation, backfill and grammar first, package tests only (core.md:401; silo pr-open-app.md:21).
  5. PrivateFacts weight-unit fix ("2 pounds ground beef" never masks) and the "Dr. Pepper." fix on core/g105b (decisions.md 6:44 PM; QA review-933).
  6. Narrow the cook gate to N21-N26 (silo pr-open-app.md:12; gate table :82).
- Habits (ops/core-handoff.md:5-11, :20; silo lessons-mac.md:13, :15):
  - Package gate: `swift test` inside TesseraCore, no lock needed.
  - App gate: `scripts/ops/lane_lock.sh run <lane> "<purpose>" -- scripts/test.sh --app-only`, using master's script. Run xcodegen generate after adding or removing files.
  - Lint: swiftformat, then swiftlint on the paths; revert swiftformat changes in tools/storage-spike.
  - Push WIP to origin before any long gate or stop (a restart wiped scratchpad clones on Oct 16).
  - Stop processes by PID only, never by pattern and never another lane's pid.
  - Worktree on the old Mac: /Users/kaushikaranagu/pilot/.claude/worktrees/busy-hypatia-45c6f4 (core-handoff.md:3), UNVERIFIED for the fresh session. Do not switch branches there while a lane_lock run is queued.
  - Merge master into reviewed PRs; never rebase (core-handoff.md:11).
- Blockers: Mac screen locked since ~1:51 PM Oct 17, so simulator runs stall (silo pr-open-app.md:9; lessons-mac.md:16). Package tests still run. Check that a simulator destination exists before trusting any app result (lessons-mac.md:17).

## Builder A (DRAFT, lead to confirm)
- Role and scope: iOS Builder A. Owns Workout, Exercise, Plans, Routine, Widgets, DesignSystem (ops/board/ios-a.md:5), and runs each release's Step 0 and install (ios-a.md:3).
- Open PRs:
  - #895 mask sweep, branch: ask coordinator, head 4f2b9f5e8d7f59fb55ac22c5ceaaae1acfa20f7f (gate table :86). Next: test.sh at head.
  - #662 ios/tess-stroke2 (stroke strip, ops/builder-a-handoff.md:30). Handoff head 10282c9 is old. A fix push d17c0f9 is mentioned (ops/rotation-handoffs.md:80). Merged or open is UNVERIFIED; head: ask coordinator.
  - ios/ready-no-at at 68d05e5, no PR yet (silo pr-open.md:16).
  - ios/title-accent at 3393ecc, WIP, needs master merged in first (builder-a-handoff.md:31). UNVERIFIED if still current.
- Frozen PRs: #895 (number sent, QA PASS WITH NOTES at head; gate table :86). No pushes unless a fix is requested (offline-mac-playbook.md:11).
- Promised next work (ios-a.md:35-41 is Oct 16 vintage; newer orders at :151-177):
  1. Haptic.notSaved central hook plus raw titles in NowPage, HomePlan, ReviewWeek, TrainingPage, Intents.swift:108 (ios-a.md:151; silo pr-open-builders.md:15).
  2. Mask sweep at source via ObjectPrivacy.routineTitle/shownTitle (ios-a.md:155-161). #895 may cover part; UNVERIFIED how much.
  3. Soul fixes: Reduce Motion keeps full opacity, Sleep keeps full colour (ios-a.md:153).
  4. Pantry ochre removal is #917 (plain ink for state words; private recipes 100% ink, RecipesShelfView.swift:83, ios-a.md:177).
  5. Rotation-handoffs list: #662 strip fix, G12-G14 Week rest day, G25 Kitchen widget, KITCHEN index/Pantry peek (rotation-handoffs.md:24).
- Habits (builder-a-handoff.md:24-26, :52; lessons-mac.md:13, :15):
  - Worktree ~/pilot/.claude/worktrees/recursing-moore-c565e2. Never create or switch worktrees. Run xcodegen generate after switching branches.
  - Simulator "Tessera iOS build" 898C8801-BB35-45F3-A308-82AE37313525.
  - Use master's lane_lock for every simulator or Xcode run: `run ios-a "<purpose>" -- cmd`. Stop processes by PID only. Push WIP before long gates.
- Installed on phone: only e149e66 (release 8) (silo pr-open.md:9; builder-a-handoff.md:36). Release 13 bbadf141 is armed, NOT installed; phone unavailable since ~1:20 PM (pr-open.md:12). Release 10 f8bb516e was never installed (rotation-handoffs.md:25). Release 14 is held, not named (pr-open.md:13).
- Step 0 name format: `Before <sha7> (from <old sha7>) <HHMM>`, e.g. 'Before 56dd028 (from a36b161) 1707' (builder-a-handoff.md:38; silo pin-install.md:9). The copy sits outside the Backups folder, is read-only and integrity-checked.
- Install gates (silo pin-install-gates.md:9; builder-a-handoff.md:42): test.sh green on the exact SHA, v9 gate, Step 0 copy, install in place, never delete the app, one line to Kaushik after. Only coordinator-named SHAs install, never master. Re-arm line is at builder-a-handoff.md:39.
- Signing lapses Fri Oct 23 2:12 PM PT (builder-a-handoff.md:45; silo pin-install.md:9). Builds after Oct 22 need a fresh profile: move the cached profile aside, do not delete it, rebuild with -allowProvisioningUpdates.
- Blockers: Mac screen locked since ~1:51 PM Oct 17 and phone unreachable (silo pr-open.md:11-13). Installs and simulator runs wait for unlock.

## Builder B (DRAFT, lead to confirm)
- Role and scope: iOS Builder B. Owns Home, the Ask Tess bar, RootView, and the glue hooking Notes, Review and Kitchen into Home (ops/board/ios-b.md:9).
- Open PRs (heads from gate table; branch: ask coordinator for every row):
  - #564 question walls, head 7219247392c2e32e2e51f8f33029cd84feda296e (:79). Next: WallsUITests on the simulator, which waits on the Mac unlock (silo pr-open-builders.md:10).
  - #868 medicine titles, head b574decc1344ab889d303377f587f0e5f71bc530 (:80). Next: PasteCycleTests plus test.sh. If it needs master, merge master and QA re-verdicts (pr-open-builders.md:11).
  - #885 G102, head 339ebeb5b3cbbab4c0defb6861e7c18537899143 (:83). Next: test.sh.
  - #889 recipe-page failure line, head 5a493893626c8c96801e0cabc67af22b25e2fa8f (:95). Next: test.sh (UNVERIFIED if in the batch).
  - #912 mask at the source, head 4d7319605941e80415e9e21558377c99024e9f5f (:87). Merge after #890.
  - #913 kept links, head 9a2f4c3a77ab8c19b26a7c74e750add15baae356 (:88). Next: test.sh.
  - #917 Pantry no ochre, head be05f0b6ef23475069d3648c61014353d1c3c234 (:97); owner UNVERIFIED (may be Builder A or B).
- Frozen PRs: #564, #868, #885, #889, #912, #913 (numbers sent, heads unchanged since verdicts; gate table :90). No pushes unless a fix is requested.
- Promised next work (ios-b.md:60-67 is Oct 16 vintage; the REFILL 4 list in ios-b.md is not read, UNVERIFIED):
  1. PT58/PT59: PlanDigest.swift:96-97 and PlanData.swift:41-43 labels masked (silo pr-open-app.md:21; rotation-handoffs.md:68).
  2. Wall gap: a password link inside a longer paste is still saveable, PasteRecipe :274/:504-506 (silo pr-open-builders.md:16).
  3. #823 misses and "Tacos, taken back." in BottomChrome (pr-open-builders.md:16).
  4. Tap-to-reveal removal on 4 surfaces is #885 + #912 (ios-b.md:279); also G182/G183 and the page-turn Settings PR (decisions.md, 7:37 PM-8:00 PM Oct 17).
  5. Settings as 4 pages of 6 rows with the Page turn row (ios-b.md:277); read design/gaps-98.md first (ios-b.md:281).
- Habits: same Mac habits as Core. Lane-lock the simulator, push WIP before long gates, stop processes by PID only. A pkill by pattern from Builder B once killed another lane's run (silo lessons-mac.md:13). Use themed tokens (ios-b.md:57). Worktree and simulator name for B: UNVERIFIED, not in the repo notes read.
- Blockers: Mac screen locked since ~1:51 PM Oct 17, so #564 WallsUITests and #868 PasteCycleTests wait for unlock (silo pr-open.md:11).

## Research lead (written 2026-10-18, session_017t1kiDAoSpJVo4NVP2BpZU)
Mission: docs-only evals and fixtures in docs/research/fixtures/, mirrored to /mnt/project-files/tessera/research/ at the same relative path. Work from ops/board/research.md (REFILL items); two lanes plus a gap lane; Sonnet/Haiku helpers; batched PRs. Authors send PRs to QA only; cross-team questions go to Product; coordinator gets Mac relays, blockers, rotations, rulings, 3-hourly updates (posted in my own thread; last 7:51 PM PT Oct 17).
Binding rules: no key-using eval without Kaushik's own yes in the Research thread; no key-shaped literals; no em-dashes; FROZEN-PR RULE (after a PR number is sent, push only a requested fix; lows and answers ride the next PR); trailers Co-Authored-By + Claude-Session; PR bodies Before/After/How; commit, push, mirror copy as separate commands; branch+worktree per PR from fresh origin/master and check git diff --stat.
Addresses: Product session_01RBgnhXvCZZhM8wDwJqs5Rx; QA session_016tTiZavEry3vudhWSeD15v; Ops session_018JM7uZ2p9n5pHhe2U4JvC8; Kitchen session_01WXUguo5FzJwPMPZohELbQR; coordinator session_017NnYJ1KC3sgjujSxa7psmU.
Merged: #915 #916 #918 #920 #924 #925 #929 #930 #932 #943 #944 #947.
Open with QA: #950 (head f7cc6bcf, folds answers into cook-clock-vo-lowpower, pantry-private-export, soul-ask-claude), #952 (head f6ee23f9, gap-hunt-17 groceries/lists GL01-GL62), #953 (head 3b27c035, gap-hunt-19 money/reading/notes, 52 rows, G607-G616).
Queued ONE follow-on PR after #950 and #952 merge: (a) #947 answers: HS12 Home ask runs in Low Power; HS36 quiet hours 23:00-07:00 (SoulRouter 06:00 comment wrong); HS43 150 ms crossfade; HS35 to Design. (b) #952 answers: export follows the one check, titleWords retired; "Dr Patel" in Core's one private-text function; pick landing light 0.5; Done .done, Clear .success; named-action-only supersedes VO40. (c) Design's G229 hold-key amendment (HOLD keys only; Clear the basket is a TAP key) applied to FK rows and GL rows. (d) QA lows on #952: Q8 partly answered, Q5 open part is which Haptic case, name GL05's fourth predicate. (e) #953 answers from Product; renumber gap ids at merge.
Next lane: gap hunt 20 on Training (workout log, live workout, PRs, plans), Low Power and VoiceOver first, docs only. Tell Product if Kitchen already covers gap hunt 19's area.
Standing board items: re-trace cook-gate rows when #884 merges; re-trace #871 composition rows when it merges; reword "decisions.md ends at line 943" in release-14-walk.md after the Ops mirror merges; release 13 walk once bbadf141 is on the phone (tick R12); Sun 8 AM PT rider refresh; Thu Oct 22 9:30 AM all-riders check; R14 DST DS29/DS36 re-read before Oct 31.
Traps: decisions.md stamps run 1-2 h ahead of PT; ObjectPrivacy.label(of:) returns nil for workout/routine on master ("Private workout" comes from routineTitle/routineLabel); never let a helper guess reasons for id gaps; confirm every append with a tail read-back.


## Research lead, 3:45 AM PT Oct 18 (rotation; the next Research thread continues from this; outgoing session_016prm61LgTia7soLeQ5zxP8, which continued the 9:35 PM note above)
Mission unchanged: docs-only evals and fixtures in docs/research/fixtures/, mirrored to /mnt/project-files/tessera/research/ at the same relative path. Authors send PRs to QA only; leads never merge (the coordinator's merge workers do, after QA's verdict). Cross-team questions go to Product.
Merged since the 9:35 PM note (all QA PASS or PASS WITH NOTES): #950 #952 #953 #959 (gap hunt 20 Training, G617-G626) #965 #971 #974 #980 (Claude key Remove: two-step, plain receipt, no UNDO) #983 (key tail removed from settings-day-one) #997 (gap hunt 21 Plan my day / Day log / Speak, G627-G636, 59 rows).
Open lanes and branches: none of mine are open at QA. Last head pushed: claude/research-gaphunt-21 2ea7496315e4d16a99ae3d0a34645e063276aa70 (merged). Worktrees under /home/user/wt-* are scratch.
Carry-forward lows (ride the next PR): QA on #997 asks to re-check the four mirror-only rulings (12:20, 12:22, 12:23 AM and 1:12 AM Oct 18) against repo decisions.md once the mirror lands; #997 base a99cd18 was behind master (no overlap seen).
Waiting on others: #884 (head 5665c600, cook-gate rows) and #871 (head 34fc9650, composition rows) are still open (Mac test.sh pending). When either merges, re-trace the matching rows against master and fix drift in one PR. Product's gap-lane default (Oct 18 08:12Z): the cook-gate and #871 re-trace.
Next steps: (1) Sun Oct 18 8 AM PT rider refresh (riders.md; Haiku/Sonnet helper). (2) Thu Oct 22 9:30 AM all-riders-in check. (3) Release 13 walk once bbadf141 is on the phone (tick R12). (4) R14 DST DS29/DS36 re-read before Oct 31. (5) Ask Product for gap hunt 22 if the lane empties; hunted so far: home/settings, groceries/lists (17), money/reading/notes (19), training (20), plan/day log/speak (21). Kitchen owns Look/Settings, Habits, Shutdown.
Rules I follow: no key-using eval without Kaushik's own yes in the Research thread; never print, echo, log or store any part of the key; docs say "the Claude key prefix"; no key-shaped literals; never touch his key-check threads; no em-dashes; US English; "best" never "record"; FROZEN-PR RULE (after a PR number is sent, push only a requested fix; lows and answers ride the next PR, branched after the base merges); trailers Co-Authored-By + Claude-Session; PR bodies Before/After/How with the attribution block, requesting user assigned; commit, push, mirror copy as separate commands; branch+worktree per PR from fresh origin/master and check git diff --stat; confirm every append with a tail read-back. Helper pattern that worked: one Sonnet helper per PR in a worktree, it commits locally, I verify the diff stat, push and open the PR.
Traps: repo decisions.md lags the project mirror (/mnt/project-files/tessera/product/decisions.md); newest rulings are mirror-only for a while and fixtures must say so. decisions.md stamps run 1-2 h ahead of PT (CLOCK CORRECTION). G604 does not appear anywhere; never guess why. G4001-G4015 is a separate series. Row prefixes (PL, PD, DL, SP) can collide across files; each file says its ids are unique only inside it. ObjectPrivacy.label(of:) returns nil for workout/routine on master. Concurrent appends to this file can be lost: re-read after writing.
Addresses: Product session_01RBgnhXvCZZhM8wDwJqs5Rx; QA session_016tTiZavEry3vudhWSeD15v; Ops session_018JM7uZ2p9n5pHhe2U4JvC8; Kitchen session_01WXUguo5FzJwPMPZohELbQR; coordinator session_017NnYJ1KC3sgjujSxa7psmU.

## Builder A (written 2026-10-21 about 9:20 AM PT, outgoing thread: Mac session goofy-turing-16d626; supersedes the Oct 17 DRAFT above)
Role: training and workout, looks, widgets and Live Activities, Watch, motion, haptics, installs, exercise pictures, set marks, Measure, the Training header. Routes through the coordinator; never merge a PR myself (the coordinator's merge worker does).

Standing orders from Kaushik (the install rule is his own words, 2026-10-19 5:04 PM PT: "you have my yes for install always"): install exactly the SHA the coordinator names, never master; Step 0 copy first, named "Before <sha7> (from <prev sha7>) HHMM" in ~/Library/Developer/TesseraBuilds, never overwrite, rename or delete one; in place, never delete the app; catalog v9; confirm "App installed" in the output and report the time and the Step 0 line. Free-licence downloads are allowed without asking (tell him); paid sets wait. Never print any part of the Claude key. UI carries equal weight with the backend; no figure beside exercise names, no lines between rows, no blur in new motion, nothing cut with an ellipsis (text wraps or scales).

Releases so far (all installed with Step 0): 24 1828b80, 25 b1f1a50, 26 830e663, 27 eb4f84b, 28 c15dccb, 29 7a891a3, 30 c2cce7e, 31 a2803ce, 32 05b9e53, 33 c420a0c, 34 f154a8f, 35 463e1ce. Release 36 is batch-test-22r 7f11cd2748859b3a357a2ea6104ea92b3ab8cd92 (named by the coordinator Oct 21 9:09 AM PT); if the install line in the thread says "PHONE UNAVAILABLE", the phone was locked or off: unlock it and run `~/Library/Developer/TesseraBuilds/release-install.sh 7f11cd2 463e1ce`. The script now prints "installed" only after devicectl says "App installed" and exits 4 otherwise.

Tools (all in ~/Library/Developer/TesseraBuilds): pr-gate.sh <branch> <label> (exports origin/<branch> and runs scripts/test.sh under lane_lock3; result in result-<label>.txt, log test-<label>.log); release-gate2.sh <full sha> (Release device build stamped TESSERA_BUILD_SHA plus test.sh; do not edit it while a gate runs); release-install.sh <sha7> <from sha7>; aslots.sh <label> -- <cmd> (two-slot semaphore for any other xcodebuild or simulator job; -jobs 4). Batches: `git worktree add -B batch-test-<x> <dir> <master sha>`, merge each head with `git merge --no-edit <full sha>` and check `git merge-base --is-ancestor <head> HEAD`; stop and report on any conflict, never resolve inside a batch; push with -f; run release-gate2.sh on the batch SHA; report SHA, counts and the Release result. In zsh use an array for a list of heads (`HEADS=(...)`; `"${HEADS[@]}"`), a plain string variable will not split.

Simulator notes: my own sim "Tessera Home test" 86B20F26-630B-49D4-B9C3-A865BB5B49B1 (recorder /private/tmp/claude-501/rec.sh start|stop <name>, writes raw-<name>.mp4; compress with ffmpeg to 800-900 px). Gate sim "Tessera iOS build". The test runner often dies with "The test runner hung before establishing connection": pre-boot both sims (`xcrun simctl boot`), and if it still hangs, shutdown, `simctl erase "Tessera iOS build"` (simulator data only), boot, rerun. A hang holds the lane lock for 10 minutes. UI tests: scheme TesseraUITests (`xcodebuild test -scheme TesseraUITests -only-testing:...`); XCTest drags always start with a press, so they cannot tell a plain swipe from press-and-drag. Launch flags (simulator only): -demo -demoTime 18:10 -resetDemo, -openWorkout, -measureGallery, -openLink review. -resetDemo also resets Review picks (the page turn goes back to Today). The Review page-turn word is a tap-to-cycle value (Today, Slide, Turn, Soften, Rotate). Setting content size: `xcrun simctl ui <sim> content_size accessibility-extra-extra-extra-large` (AX5) and back to `large`.

Open PRs and branches at my rotation (frozen once a number is sent; push only requested fixes, merge master never rebase):
- Merged or merging via the coordinator: #1161 SetMark, #1164 private Lock Screen mask, #1168 activity re-adopt, #1172 and #1183 (figures off, AX5), #1173 cook clock page, #1177 pull-down index, #1188 MeasureView, #1190 kicker row. Heads in batch 22r: #1180/#1172 44168ea1 (title), #1183 a1c037e2, #1188 47044b1b, #1190 8cea7a37.
- #1140 exercise sheet: origin/ios/exercise-sheet e113a4fe still carries the GIF commit; the clean local rewrite is 9396d0dd (branch ios/exercise-sheet in the main checkout) and needs `git push --force-with-lease=ios/exercise-sheet:e113a4fe origin ios/exercise-sheet`, which the harness blocks for me: Kaushik must run it or allow it. Kaushik chose the Gym visual GIF set with Workout Guide as the fallback (2026-10-20 4:38 PM PT "yeah lts go with the gym visual thing"). GIFs live only in git-ignored folders (~/Library/Developer/TesseraBuilds/exercise-gifs, exercise-thumbs), copied into exports by the gate scripts; never commit them.
- #1189 (Builder B) conflicts with #1184 in SettingsPage.swift; Builder B is merging; not mine.
- Parked: ios/reading-layouts 233683ca (take to a PR from master after the visible features), ios/tess-motion 75685025, ios/lowpower-topbar 76305f1c, ios/clock-page was shipped as #1173.

Open lows for my next PR (from Design and QA): VoiceOver reads the kicker row once (combine its two ends into one element); put back the misplaced "about 55 min" doc comment above TrainingPage.about; the live dial's "kg" should be the same small uppercase unit word as the Training rows; round an estimate to whole units from 10 up ("about 29 USD") and keep two decimals under 10, typed amounts keep their decimals; an optional once-only hint the first time a measure shows; FlareBand.SlideBack's 4 pt blur must become the plain 24 pt slide plus opacity (no-blur rule); a Done-state still for the kicker (needs all 14 demo sets logged); the font PR waits on Kaushik's OK of the drawing (Cormorant Garamond words and Urbanist numbers per Design item 115; check glyphs for eighths and thirds; bundle in the app and widget targets, About credit, Review row "Font"); the Reduce Motion clip for the unit tap and the Soften/Rotate left-edge swipe checks were only done for Slide.

Habits that paid off: one slot per xcodebuild via aslots.sh; erase the gate sim at the first hang; explicit-path `git add` (never -A on a branch without the GIF ignores); read the product spec file before building (Design item 115: tessera/design/type-pair-unit-wheel-115.md in the project files); take stills at default size and AX5 with the demo launch and say plainly what is not fixed; verify claims on the simulator, not from code.
Addresses: coordinator session_01L8p4LGSzq58wE3aP252k83 (use send_message to @parent).
