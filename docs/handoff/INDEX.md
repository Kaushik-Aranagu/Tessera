# Handoff index

Generated 2026-10-24T09:32:39Z by scripts/ops/codex_handoff.sh from origin/master f8803d66. Read the lane notes first, then the open PRs.

## Lane notes

- [CODEX](CODEX.md): Codex handoff for Tessera
- [builder-a](builder-a.md): Builder A handoff (iOS UI lane and integrated builds)
- [builder-b-specs](builder-b-specs.md): Builder B: design specs received and not built (verbatim from the coordinator)
- [builder-b](builder-b.md): Builder B handoff (iOS screens: Home, Settings, Kitchen rooms, Notes, Lists, Routines)
- [core](core.md): Core lane handoff (written Oct 24, 12:57 AM PT, at 97% of the weekly limit)
- [design](design.md): Design handoff (Design lead, Oct 24, 1 AM PT)
- [gestures](gestures.md): Gestures handoff (Oct 24, 7:57 AM PT)
- [qa](qa.md): QA handoff (Oct 24, 2026, 1:00 AM PT)
- [weather](weather.md): Weather room handoff (Codex checkpoint, Oct 24)

## Open PRs (head, base, latest QA verdict)

- #407 `core/tess-eyes` <- `master` @ 8f9b6cb8: Settings: tessEyes (Tess's eyes, off by default) (QA:  #407 PASS 8f9b6cb qa.md)
- #564 `ios/question-walls` <- `master` @ 018a7d45: Questions go through Tess's walls; WallsUITests types the made-up phrases itself (QA:  #564 PASS bf0ba93 qa.md)
- #895 `ios/private-title-more` <- `master` @ 4f2b9f5e: Mask private workout, routine and list titles at the source; failure haptic hook
- #1215 `core/run-plane` <- `master` @ 44028c1b: R1: run-mode control plane (engine only)
- #1216 `core/run-plane-lows` <- `core/run-plane` @ e38cf9bf: Run plane lows from QA on #1215
- #1249 `core/pool-lows` <- `core/router-lows` @ 7a44101c: Pool, router and Log lows from QA
- #1262 `core/explain` <- `core/pool-lows` @ c957db68: Explain: why this number
- #1265 `core/explain-private` <- `core/explain` @ f438a248: Explain: private routine session length returns nil
- #1268 `core/pool-words` <- `core/pool-lows` @ c0ac7ef6: Private words split on punctuation too
- #1269 `core/private-words-helper` <- `core/pool-words` @ df23f207: One helper for private words in a phrase
- #1270 `core/away` <- `core/make-a-kind` @ 6d2ede8c: Away: a trip Home is quiet for
- #1271 `core/away-lows` <- `core/away` @ 022e9819: Away lows: reseed test, no duplicate registry entries
- #1272 `core/twins` <- `core/away-lows` @ 5db4ae37: Twins: join two things that look the same
- #1274 `core/undo-log` <- `core/twins` @ 1c09e255: Undo from the op log
- #1276 `core/privacy-page` <- `core/undo-log` @ b021bb43: Privacy page and backup words
- #1277 `core/undo-lows` <- `core/undo-log` @ a51216b9: UndoLog lows: generic wording for retitled, money and body receipts
- #1278 `core/undo-lows2` <- `core/undo-lows` @ b5573c3f: UndoLog lows 2: real rollback test, calendar and calorie receipts
- #1280 `core/privacy-page-lows` <- `core/privacy-page` @ 5cd702e8: Privacy page lows
- #1284 `core/twins-fix` <- `core/twins` @ a10ab87a: Fix Thing field list test for notTwins
- #1285 `core/privacy-page-lows2` <- `core/privacy-page-lows` @ 852dec27: Privacy page: test for kinds made from Note or Task
- #1287 `core/finish-shop` <- `core/twins-fix` @ 0cf8247c: FinishShop(putAway:) sets places and finishes in one change
- #1289 `core/money-month` <- `release/56` @ a5fc511d: Money month: sentence, pool lines, levels
- #1290 `core/mosaic` <- `core/money-month` @ 81852338: MosaicFacts: sun, sky, captions, finished today
- #1291 `core/mosaic-lows` <- `core/mosaic` @ 0c6ec578: Mosaic and month lows
- #1296 `core/hands-source-lows` <- `core/mosaic-lows` @ 0a8acc95: Lows: three-collision test, source note line
- #1297 `core/units-page` <- `core/hands-source-lows` @ 02832524: Units page: three rows, a sample, nothing stored changes
- #1303 `core/mosaic-moods` <- `core/hands-source-lows` @ b831038f: MosaicMoodPicker: Tess picks the mood on the phone
- #1305 `core/mosaic-moods-lows` <- `core/mosaic-moods` @ 9a2554ed: Mood picker low: the app's own private label
- #1312 `core/mosaic-moments` <- `release/65` @ 694cf01c: MosaicMomentSource: when a moment plays and what it says
- #1315 `core/mosaic-moments-lows` <- `core/mosaic-moments` @ 0ea59ceb: Moment lows: three clauses, hashed keys
- #1316 `core/feature-flags` <- `release/68` @ 98897290: FeatureFlags: everything ships On, conflicts as one choice
- #1318 `core/feature-flags-lows` <- `core/feature-flags` @ db9fdfda: FeatureFlags lows: Claude set matches ReviewChoices
- #1321 `core/day-quiet` <- `release/68` @ 7a9df1f7: Settings: quiet hours and the day's turnover
- #1322 `core/day-quiet-lows` <- `core/day-quiet` @ 7dca80d8: Day and quiet lows
- #1323 `core/app-lines` <- `release/68` @ f7b00a61: AppSummaryLines: one line per app for Home
- #1324 `core/soul-quiet` <- `core/day-quiet-lows` @ f5a2c1d7: Tess rests in his quiet hours
- #1325 `core/app-lines-lows` <- `core/app-lines` @ 2ddff4da: App lines lows: mask the running routine and the opener
- #1328 `core/home-loaders` <- `core/app-lines-lows` @ 5a2dd654: Home loaders for the apps list
- #1333 `core/mosaic-page-facts` <- `release/68` @ fa76d381: Mosaic open cue and page facts
- #1336 `core/today-lines` <- `release/73` @ 72618df5: Today lines, ranked notices, short why
- #1340 `core/one-things` <- `core/today-lines` @ 5feba0d8: OneThings: the ranked things for Home's one-thing space
- #1343 `core/grocery-scale-budget` <- `release/74` @ a783cf39: GroceryScaleTests: budgets scale with how busy the Mac is
- #1344 `core/test-hygiene` <- `core/grocery-scale-budget` @ 1e4365f7: Test hygiene: a shared load factor, no wall-clock limits that fail by queueing
- #1345 `core/scenes` <- `core/test-hygiene` @ aa5ca57b: Mosaic scenes: the picker and the place kind
- #1346 `core/tess-conversation` <- `core/scenes` @ 69e83403: Tess interface: conversation, ask router, room log, opener, on-device speech (sheet 215)
- #1348 `core/switchboard` <- `core/tess-conversation` @ 93ac999d: Mosaic switchboard: cues, wires, priority and quiet rules (sheet 204)
- #1350 `core/tess-director` <- `core/switchboard` @ 3d669dec: TessDirector: one decision seam for plays and looks
- #1353 `ios/fit-216` <- `ios/home-216` @ 10115495: Home board: measured fit, band timer, Today room (216 follow-up)
- #1355 `core/birthday-ids` <- `core/one-things` @ 87d38921: Birthday ids: month, day and index, no name hash
- #1356 `core/bests-lows` <- `core/bests` @ 5754a50f: Weekly bests lows: his day boundary and a warm-up test
- #1357 `ios/fit-216b` <- `ios/fit-216` @ 5ab7ab81: Today room: no ellipsis (216 follow-up 2)
- #1358 `core/unit-lows` <- `master` @ e09adb4c: Units lows: rounded raises, unit-aware Tess asks
- #1359 `ios/stop-216` <- `ios/fit-216b` @ 40c07407: Cuts never end on a stop word (216 follow-up 3)
- #1360 `core/birthday-order` <- `core/birthday-ids` @ 5e5eb368: Birthday ids count within their own date
- #1361 `core/repeats` <- `master` @ 1c71c1d4: Repeats: one recurrence rule for tasks, routines and occasions (sheet 173)
- #1363 `ios/gestures-220` <- `ios/stop-216` @ a37a716c: Home gestures: apps list hold-and-scroll, one thing four-way (220)
- #1364 `core/harness-brain` <- `master` @ 6454b00c: Harness H1a + H0: Brain seam, ClaudeBrain (SSE), AppleBrain, RunTrace, latency bench
- #1365 `core/harness-door` <- `core/harness-brain` @ 6d34d574: Harness H1b: Door, router, lab/strict policy, hedge
- #1366 `ios/qa-77` <- `integ/77` @ 409666be: integ/77 QA list and gestures review
- #1367 `core/playbook` <- `core/harness-door` @ 11b2834e: Harness H2: PlaybookDirector, PlaybookStore, PlaybookJob
- #1368 `core/playbook-lows` <- `core/playbook` @ e59a3920: Playbook lows: file protection, checked why lines
- #1369 `core/repeats-lows` <- `core/repeats` @ 110b2796: Repeats lows: Sunday test, skip past today, real day stamps
- #1370 `core/snap-lb` <- `core/unit-lows` @ 59c5604b: snap(): pounds range-checked like kilograms
- #1374 `ios/lows-77` <- `ios/qa-77` @ 2dfbe195: Lows after QA on #1366
- #1375 `core/harness-m0` <- `core/playbook-lows` @ 9ac77a57: Harness M0: verbatim assistant blocks, search cost, Haiku step, cache TTL, count_tokens
- #1377 `ios/tess-units` <- `core/unit-lows` @ 3302f706: Tess follows his weight unit (on #1358)
- #1378 `claude/project-thread-1kliwl` <- `core/harness-m0` @ 01439d49: Harness M3 + M2 core: context packer, budgets, meter, tuner, recall score
- #1379 `core/harness-accuracy` <- `core/harness-m0` @ 01f8b50a: Accuracy first: $100 guard, Opus rung, adaptive thinking; #1375 lows
- #1380 `core/tess-run` <- `core/harness-accuracy` @ e0524baf: Harness H3: TessRun streaming loop
- #1381 `ios/quiet-167` <- `ios/lows-77` @ 1df7f9ae: Quiet hours page and the day-turnover line (167, 203)
- #1382 `core/query-tool` <- `core/tess-run` @ 6e191a1c: I1: the query tool replaces answerQuery
- #1383 `core/kitchen-actions` <- `master` @ 701584e0: Kitchen actions: Pantry stock, used up, got it, not now, pins, add to place, recipe pin and plan
- #1384 `ios/kitchen-parts` <- `ios/quiet-167` @ 7b0980e1: Kitchen pieces and the Pantry room (231, 232)
- #1385 `core/beliefs` <- `core/query-tool` @ afd58d82: M1: Beliefs with evidence, closing on change, forgetting by deleting
- #1386 `ios/recipes-233` <- `ios/kitchen-parts` @ 4f63bbf5: Recipes room (233)
- #1387 `core/nutrition` <- `master` @ 898e1cf6: Nutrition: USDA food table per 100 g, per100g and perServing
- #1390 `claude/project-thread-c4gbv9` <- `master` @ 3247958c: Gesture policy follow-ups from QA
- #1391 `claude/project-thread-c4gbv9-home-regions` <- `master` @ abd7f065: Home: a swipe across the mosaic no longer moves the one thing
- #1393 `claude/project-thread-c4gbv9-element-swipe` <- `claude/project-thread-c4gbv9-home-regions` @ 3a4708cd: Gesture policy: a single swiped element turns on either axis
- #1394 `claude/project-thread-1kliwl-ai` <- `core/beliefs` @ ff3bed4e: Harness checks: AnswerCheck (C6), nightly memory eval (Mem4), test world with ~160 questions, M3 wiring notes
- #1395 `claude/project-thread-1kliwl-ai-m4` <- `claude/project-thread-1kliwl-ai` @ f4095868: Harness M4: AgentSpec for the shipped agents, Training and Kitchen expertise packs
- #1397 `core/measure-parts` <- `master` @ 8e4c9568: Measure: number and unit as separate parts
- #1398 `claude/project-thread-1kliwl-ai-m5` <- `claude/project-thread-1kliwl-ai-m4` @ dd5ce34c: Harness M5: the night pass rules as a pure planner
- #1399 `claude/project-thread-1kliwl-ai-m6` <- `claude/project-thread-1kliwl-ai-m5` @ 9a9c81fe: Harness M5 to M6: the 4 am run, MergeBelief, and the eval's store adapter
- #1400 `claude/project-thread-1kliwl-ai-seed` <- `claude/project-thread-1kliwl-ai` @ 6d1c999c: Test world seeder: the made-up year through the app's own actions
- #1401 `claude/project-thread-kyu5l0` <- `master` @ a6f28164: Add the Weather room screens (sheet 243)
- #1402 `claude/weather-adapter` <- `core/weather` @ 0a78f359: Weather room: adapter from Core's WeatherReport (stacked on core/weather and #1401)
- #1417 `ios/pantry-columns` <- `ios/kitchen-parts` @ 50d41c7e: Pantry columns (234) and Recipes review fixes

## Mac lanes

```
slot 1: core-ai pid 66189 held 192s: swift test #1398 2377e39e
slot 2: ios-a pid 62519 held 547s: 78 Release device build
slot 3: ios-b pid 65818 held 194s: pantry qa unit tests
busy 3 of 3, free disk 24 GB
device lock: free
```
