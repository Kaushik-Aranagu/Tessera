# Core lane handoff (written Oct 24, 12:57 AM PT, at 97% of the weekly limit)

Core owns `TesseraCore/` (engine, Tess, Harness, Kitchen, Weather, Measure). Repo: `Kaushik-Aranagu/Tessera`. The coordinator
is the only one who talks to Kaushik; every request comes through it. Times to Kaushik are Pacific. No secrets or key in
this file.

## Done recently (PR, branch, head)

| PR | What | State |
|---|---|---|
| #1382 | I1 query tool replaces answerQuery (`core/query-tool`, 6e191a1c) | QA passed, frozen |
| #1383 | Kitchen actions: stock, used up, got it, not now, pins, add to place, pin/plan recipe (`core/kitchen-actions`, 701584e0) | QA passed, frozen |
| #1385 | M1 Beliefs (`core/beliefs`, afd58d82) | QA passed, frozen |
| #1387 | Nutrition: USDA SR Legacy table, per100g, perServing (`core/nutrition`, 898e1cf6) | open; QA notes fixed (cooked/canned rows) |
| #1396 | `scripts/ops/mac_lanes.sh` N-slot build lanes | merged (master 4c919f37) |
| #1397 | Measure parts: `MeasureFormat.parts(of:)` (`core/measure-parts`, 8e4c9568) | open; full test green except a wall-clock flake (MosaicMomentSourceTests fail around 23:45 to 00:10 PT, not caused by it) |

Compile checks reported to the coordinator: master 26271190 all green; #1390 (3247958c) unit green; #1391 unit green. The UI
tests (`GestureStabilityUITests`, scheme `TesseraUITests`) failed 4 of 4 in navigation before reaching any gesture, on
both. They were never green, so the swipes are untested.

## In flight (branch, head, state, next step)

- **Sheet 234** `core/kitchen-234` (a8139087, based on `core/kitchen-actions` plus `core/nutrition`): place categories,
  Leftover/MealEntry/MealNutrition (local-only mirror class), PutAway/EatServing/ThrowOut/Move/SetThrowOutDay/LogOutsideMeal,
  reminders rules, MealPhotoStore, engine clock+calendar on `ActionEngine`/`Transaction`, the four #1383 lows. Built and its
  own tests pass; the last full `swift test` run failed only in PantryPlaces/Shopping tests that I then updated (they now
  pass alone). **Next: one full `swift test`, then open the PR (base master, mention it contains #1383 and #1387).**
- **Weather** `core/weather` (6e54d538): WeatherCondition (15 cases), WeatherWarning, WeatherReport (now, 48 h, 7 days, air
  quality, wind from), OpenMeteoSource (0.1 degree rounding, 30 min cache), SampleWeather, `WeatherTests`. **Never built.**
  Next: build, fix, test, PR. The Weather room screens are #1401/#1402 (cloud-written, uncompiled; their app types
  `WeatherForecast`/`WeatherKind` differ from Core's `WeatherReport`/`WeatherCondition`; the adapter maps them).
- **AI lane swift tests** (run through `mac_lanes.sh`, worktree `scratchpad/tw`): #1394 d22bfac0, #1395 7aed147f, #1398
  e601cc3f, #1399 7cea3319, #1400 d688c8e4. Send any compile or test errors to the coordinator; the harness thread's author
  fixes them. #1394's earlier head failed to compile in `EvalWorldKey+Bank.swift:169`.
- **Test-store stamp and live runner** (not started): see Next.

## Paused (resume when Builder A says the 77.1 phone install is done)

I stopped these with SIGSTOP (only my own PIDs): `gate.sh` (pid 84499, with its xcodebuild/swift-test children) and
`ai-gate.sh` (pid 4872 and children). Resume with `kill -CONT <pids>`; the PIDs are in
`scratchpad/paused.pids` (4872 4897 4918 4919 4921 9906 84499 88015 88022 88023 88604; some may have exited). A resumed test
that uses a wall-clock timeout may fail once; rerun it. If the processes are gone after a restart, rerun
`scratchpad/gate.sh` (gesture gate: #1392 then +1390, +1391, +1393 UI tests) and `scratchpad/ai-gate.sh` (swift test on the AI
PRs). Heads change; fetch `pull/<n>/head` first.

## Next, in priority order (coordinator's order)

1. Resume the paused jobs; swift test #1394, #1395, #1398, #1399, #1400 (AI lane first).
2. Compile and test #1401 (a6f28164) and #1402 (0a78f359, includes #1401): `swiftformat`, `swiftlint`, unit and UI tests through
   `mac_lanes.sh`. #1402's host wiring plugs `OpenMeteoSource` in; Open-Meteo is ON by default (also in Sample data), the sample
   is only the fallback.
3. Gesture gate: #1392 (488280ed, QA passed) then #1390/#1391/#1393 (03a5332d) UI tests, with a vertical-swipe UI test added
   (drafted in `scratchpad/m1389`, branch `gate-all`).
4. Test-store stamp (`TesseraSettings.storeKind = "test"`, Claude rungs allowed when `settingsAreReal` or stamped test, backups
   refuse a test store, own sent log/ledger/trace files) and the live runner `scripts/tess-eval.sh --world small|big --policy
   lab|strict` ($50/month guard inside the $100 cap, key read from the keychain, never printed). The seeder is the harness
   thread's (#1400).
5. Weather build and PR; sheet 234 PR; Training landing stats in `TrainingLedger` (sessions done vs planned this week,
   consecutive weeks on plan, e1RM change on the headline lift since a date, each with its sentence).
6. Mosaic face sources (Design 236): CoreLocation when-in-use at approximate accuracy, CLGeocoder on the phone, location never
   in backups/logs/widgets/notices/Claude; gallery is scenes only.
7. M3 wiring into TessRun (7 issues from the harness thread): strict drops instead of refusing, AppleBrain gets its own small
   pack, cache marks (4 max, tail mark), fragments index, 30 s round deadline measured with LatencyBench, pin the rung within
   a run (thinking replay), shown-label paths.
8. Route the old direct Claude senders (PlanWording, HomeDoneWording, RecipeLinkReader, ClaudeTessModel) through the Door.
9. Lab policy change (Kaushik, Oct 23 10:25 PM): in lab mode with asksClaude on, Claude calls may carry walled/private items
   (private notes, lists), each with a sent-log row; strict unchanged; the key, money actions and backups/logs/widgets stay
   out. Update `docs/ai/harness` to match.
10. Lows: RailPage 3 visible slots and pinned-items model field; Groceries Food unit (details unknown).

## Rules and approvals to keep

- UI carries equal weight with the backend; never stock or card-based screens.
- Accuracy first, cost is not a limit except the $100/month runaway guard. The Claude key never moves ("never logged, printed or
  copied"). Money actions always need his tap. Everything ships ON.
- Use sample data until Kaushik says the app is production ready. Free services and APIs are fine, paid ones are not.
- No quiet hours for work (his Oct 24 rule): go all out.
- Every PR body starts with the two attribution lines (`<!-- claude-projects-attribution: {"github_login":"Kaushik-Aranagu"} -->`
  and `_Requested by **Kaushik**_`), then Before/After; assign and request review from Kaushik-Aranagu. Commits end with a
  Co-Authored-By line. Run the full `swift test` before a PR; QA-passed PRs are frozen, follow-ups go in new PRs.
- Run heavy jobs only through `scripts/ops/mac_lanes.sh` (3 slots, own DerivedData and simulator, device lock for phone
  installs). Machine: 10 cores, 24 GB RAM, disk was 99% full (47 GB freed from my old `.build` folders). Never `pkill` by
  pattern; stop only your own PIDs. Keep the disk above 6 GB free.
- Privacy walls: nothing about location, weather place, nutrition, meals or leftovers goes to Claude, logs, backups or widgets
  (tests scan `TesseraTess` sources for the Core types). Test-world seeding writes through the real actions, `by: .system`.
