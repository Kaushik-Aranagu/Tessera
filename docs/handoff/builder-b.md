# Builder B handoff (iOS screens: Home, Settings, Kitchen rooms, Notes, Lists, Routines)

Written Oct 24, 2026 (about 01:00 AM PT) for Codex, at 97% of the weekly limit. Where this file and Kaushik's words differ,
his words win; where it and the code differ, the code wins. Read `docs/handoff/CODEX.md` first (repo, build, rules).
The full specs I received and have not built are in `docs/handoff/builder-b-specs.md` (copied from my notes, with every
board link). Mac builds and tests go through `scripts/ops/mac_lanes.sh` (`docs/ops/mac-lanes.md`); the Mac was at load
700+, so run one job at a time.

## Standing rules (Kaushik)

- UI weighs as much as the backend; no stock or card-based screens; build screens exactly as the design sheets and check
  the phone against the board side by side. Approved features ship **On**.
- Fake Claude keys only, built at run time from pieces, never in logs, previews or fixtures. Never run UI tests with his
  iPhone as the destination. Never edit `TesseraCore` (Core's lane) from a screen PR. Times to Kaushik are Pacific.
- Types: Figtree words, Outfit numbers, Newsreader for Tess. A measured number always shows its unit at about half the
  numeral size (min 10 pt, Figtree 400). Title fit: big titles step down 1 pt at a time to 0.75x, then cut at whole
  words, never an ellipsis. No glass lens anywhere (he dropped it). No counters on swipers. No underlines on Home.
- Colour: 3 to 4 colours a page, each with a meaning (spec "COLOR ROLES 241" and the "BIG TYPE RULE" in the specs file).
- Gestures: follow `docs/design/gesture-policy.md` (GestureTuning, `.rowSwipe`, `.pageSwipe`, `.pullGesture`). Never a
  `DragGesture(minimumDistance: 0)` on a body or a high-priority gesture over buttons (that is what swallowed the apps
  list taps). Every list with a hold or drag gets a G13 UI tap test.
- Every PR body starts with the two attribution lines and ends with the Claude Code line; assign the PR to
  Kaushik-Aranagu; commits end with a Co-Authored-By line. Never rebase or force-push an opened PR; merge master in.

## Completed recently (all through QA, most still open waiting for the integrated build)

| PR | What | State |
| --- | --- | --- |
| #1352 | Sheet 216 Home board (fixed rows, fit, sky date, flips) | open, QA passed |
| #1353 | 216 follow-up: measured-width fit, band timer, Today room | open, QA passed |
| #1357 | Today room names never end in an ellipsis | open, QA passed |
| #1359 | Cuts never end on a stop word | open, QA passed |
| #1363 | Home gestures (apps list hold-and-scroll, one thing four-way) | open |
| #1366 | integ/77 QA list and gestures review (head 409666be) | open, QA passed |
| #1374 | Lows after QA on #1366 (head 2dfbe195) | open, QA passed |
| #1377 | Tess follows his weight unit (on Core #1358, head 7828b9d7) | open, QA passed |
| #1381 | Quiet hours page and the day-turnover line (head 9b6b9d43) | open, QA passed, frozen |
| #1384 | Kitchen pieces (PlaceDial, FocusWheel, ReceiptLine) and the Pantry room (head 077d10f1) | open, QA passed, frozen |
| #1386 | Recipes room (233) | open, FIX FIRST fixes pushed on `ios/recipes-233` (4f63bbf5), not re-tested |
| #1392 | Apps list: plain taps reach their rows again (head 488280ed) | open, QA passed; unit 1057 and UI 3 of 3 passed |

## In flight (branch, head at writing, test state)

- `ios/home-236` (worktree `home236`): Home 236 v2. Replaces the ScrollView with five fixed slots (`HomeSlots`), drops the
  Tess band, gives the one thing a single 92 pt hard clip edge and the v2 type (`HomeFit`, `HomeOneThing`), removes the
  mosaic-to-thing swipe and the "N of M" counter. **Untested** (a test run never finished: Mac overloaded). To do: the
  vertical swipe (build on Gesture policy PR #1393 `GestureTuning.elementTurn` when it lands), translateY depths
  .9/.72/.54, clip insets (-57 top, -29 bottom, 92 right); the foot (Undo line left, Tess right); the Home type spec
  (date 600, rows 2-3 plain 500 + highlighted 700, Outfit 400 numerals, app names 600, no ink3 on Home); the date colour
  rules; the highlighted-part doors and their targets; the 7 +/- 3 s flip timing. Weather word effects are Builder A's
  (236 v2.4 to 2.8); a cloud thread builds the Weather room (#1401, #1402).
- `ios/pantry-columns` (worktree `pcols`): Pantry columns (234 v4 to v9) on top of #1384 and Core #1383: packing engine
  `PantryPacker` (real row heights 28/34, 18 pt gaps, stack-only-while-sections-outnumber-columns rule), `PantryColumnsView`
  (value beside or below by fit, low shown in the name, section small caps, 44 pt touch reach), "Add to To get" nudge,
  Depth on wheels blur (`FocusWheel.blurRadius`, Settings > Look). **Untested** (the first compile never ran). Open items
  from QA: the used-up name arc; `PantryRefusal.line(error)` is internal to Core (ask Core to make it public) instead of
  the string match; Pantry/Recipes bodies should move onto `.rowSwipe` (gesture policy) and get G13 UI tap tests; the
  hit-area-vs-swipe conflict for 28 pt rows (guard: rows under 44 pt take no swipes if the extended target overlaps a
  neighbour, their actions move to VoiceOver and an item sheet that does not exist yet).
- `ios/recipes-233` (worktree `kwire`): Recipes room fixes for #1386 (real ingredient names go to To get; focus slot 80 pt,
  band 232 / page 422; private recipe real name in the room; one detail line at AX3). Needs a clean test run.
- `ios/kitchen-parts`, `ios/quiet-167`, `ios/receipt-215`, `ios/qa-77`, `ios/lows-77`: frozen QA branches above.
- Routines 238 levels 2 and 3 (kind page wheel, Today page, routine page, maker, From another room): **not started**.
  The landing (level 1) was rejected twice by Kaushik; do not build any room landing until the app-wide landing round
  arrives (see below).

## Specs received and not built (details and board links in `builder-b-specs.md`)

1. Home 236 v2.3 vertical swipe on the one thing; the Home type and top-lines spec (236 v2).
2. COLOR ROLES 241 (tokens go, gold, slate, wine, teal, clay) and the BIG TYPE RULE; Lists v9 kind colours.
3. Lists 237 v2/v3 (kinds row one at a time, right-aligned, no lens; tighter dial; review rulings) after Notes.
4. Notes 235 (depth wheel with blur, note page, action word gestures, delete with 7-day recover, privacy picks: under lab
   mode private text may go to Claude with a sent-log row, never in backups).
5. Routines 238 v3 levels 2-3, maker, From another room, privacy; landing HELD.
6. Pantry/Recipes follow-ups above; Recipes page "Keep at the top" and "Plan for" lines (not built); calories line wired
   to Core `Nutrition.perServing` (#1387) with the source line "Food facts: USDA FoodData Central" when it lands.
7. Landing round (every room): Kaushik wants landings that look like other apps' landing pages, not lists of summaries.
   Design is redrawing; nothing to build until it arrives.
8. Cleanup the permission check refused: delete two finished DerivedData folders and remove three finished checkouts
   (see the specs file, last section).

## Next steps, in order

1. Wait for the Mac to calm down, then run through `mac_lanes.sh` (slot `ios-b`, `--sim`): Home 236, Pantry columns,
   Recipes fixes, each one job at a time; fix compile errors (all three are unbuilt since the last green runs).
2. Ship #1392 first (it is the phone-blocking fix); then #1352..#1386 land through the integrated build (Builder A).
3. Home 236 vertical swipe on top of #1393, then the foot and type work; compare with board
   https://claude.ai/artifact/DygjFLo442RxyE1kmn4rJM at 390 and 402 wide, Paper and Black.
4. Pantry columns PR (with QA's four lows), Recipes fixes, G13 tap tests for Pantry and Recipes.
5. Notes 235, then Lists 237 v3, then Routines 238 levels 2-3, each its own PR from master; one PR per piece.
6. Gesture-policy migration of the apps list and the Kitchen bodies once #1393 and #1389 follow-ups are on master.
