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
  5. Narrow the cook gate to N21-N26 (silo pr-open-app.md:12; gate table :82).
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
  4. Pantry ochre removal and 100% ink for private recipes, RecipesShelfView.swift:83 (ios-a.md:177).
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
  4. Remove tap-to-reveal on 4 surfaces (ShopTrip, ListsView, GroceriesView, RecipePage) and rewrite ShopTripTests (ios-b.md:279).
  5. Settings as 4 pages of 6 rows with the Page turn row (ios-b.md:277); read design/gaps-98.md first (ios-b.md:281).
- Habits: same Mac habits as Core. Lane-lock the simulator, push WIP before long gates, stop processes by PID only. A pkill by pattern from Builder B once killed another lane's run (silo lessons-mac.md:13). Use themed tokens (ios-b.md:57). Worktree and simulator name for B: UNVERIFIED, not in the repo notes read.
- Blockers: Mac screen locked since ~1:51 PM Oct 17, so #564 WallsUITests and #868 PasteCycleTests wait for unlock (silo pr-open.md:11).
