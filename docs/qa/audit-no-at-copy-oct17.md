# Audit: no "at" before a clock time (Oct 17)

Base: origin/master 6fa3146, detached. Static only (ripgrep plus context reads). Nothing built or edited.

## Offending user-visible strings (11)
1. Features/Home/HomePlan.swift:222 "\(count), \(workout.title) at \(clock)" -> "\(count), \(workout.title), \(clock)"
2. Features/Home/NowPage.swift:286 "next, at \(SpokenTime.clock(task.start))" -> "next, \(SpokenTime.clock(task.start))"
3. Features/Home/HomeSpatialView.swift:691 atTime = "at \(clock)" feeds "this evening at six", "tomorrow at half past seven", "Friday at nine" -> drop atTime's "at" and use ", \(clock)" in the three returns
4. TesseraCore/Sources/TesseraCore/Home/HomeLines.swift:260 "\(fact.title) at \(DayStoryClock.sentenceTime(...))." -> "\(fact.title), \(...)."
5. TesseraCore/Sources/TesseraCore/Home/HomeLines.swift:273 "\(fact.title) at \(HouseTime.clock(...))" -> "\(fact.title), \(HouseTime.clock(...))"
6. TesseraCore/Sources/TesseraCore/Home/HomeLines.swift:296 "\(fact.title) at \(DayStoryClock.sentenceTime(...))" -> "\(fact.title), \(...)"
7. TesseraCore/Sources/TesseraCore/Tasks/Tasks.swift:213 "\(object.title), \(word) at \(...)" -> "\(object.title), \(word) \(...)" (gives "Call mom, tomorrow 6:30 pm")
8. TesseraCore/Sources/TesseraCore/Tasks/NowRanker.swift:281 why.append("at \(clock(start, calendar))") -> "starts \(clock(...))"
9. TesseraCore/Sources/TesseraCore/Tasks/NowRanker.swift:284 why.append("at \(clock(start, calendar))") -> "since \(clock(...))" (matches the "since 6:02 pm" wording in the comment at NowRanker.swift:334)
10. Widgets/RestLiveActivity.swift:240 Text("Ready at") followed by Text(HouseClock.time(...)) -> Text("Ready") (reads "Ready 6:30 pm")
11. Features/Command/BottomChrome.swift:703 typing demo "stretch at 21:30" -> "stretch, 9:30 pm" (also fixes the 24-hour time, which breaks the house-time rule)

Note: NowRanker "why" strings reach the Now page via NowPicker.rank (Features/Home/NowPage.swift:137), so treat items 8 and 9 as user-visible.

## Checked and excluded (not a time, or not user-visible)
- Weight, load, rep or shop "at": Intents.swift:26, TessSetCountAsk.swift:96, TessCaptureEngine.swift:274, TrainingActions.swift:397, TessGrammar+Live.swift:134, TesseraRuntime.swift:62, HomeLines.swift:257, 292, 353 ("paused at set 3", "at the store")
- Parser or model-facing text: TessGrammar.swift:635, PrivateFacts.swift:63, TessTools.swift:111, Tasks.swift:98, PlanEditing.swift:55, RoutineEditing.swift:13
- Comments only: HomePlan.swift:221, Tasks.swift:196, HomeSpatialView.swift:689, TessDates+FallBack.swift:19

## Checked and clean
- Features/ (all), App/, DesignSystem/, Shared/HouseClock.swift
- TesseraCore/Sources: Model, Engine, Catalog, Training, Tess, Tasks (except items 7-9), Home (except 4-6), DayLog, Kitchen, Format, TesseraTess, TesseraIntents
- Widgets/ (other files), Resources string catalogs (no "at" hits)
- TessCaptureEngine.when returns "day time" with no "at"; HomeQueue uses it cleanly
- Two-piece strings ("at " + x): none found

## Limits
ripgrep and reading only; no Swift compile. Keys built dynamically or from enum raw values were not traced. Tests were excluded per the brief.
