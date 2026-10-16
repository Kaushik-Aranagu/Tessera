# Time words sweep (Product item U)

For: Product, Core, Builder A, Builder B, Design. Owner: Research lab. Date: Oct 16, 2026 (Pacific).
Read by hand on master `40af0f1` (#478), nothing run; TW1 is on #366's head `46dfd4d` (`origin/ios/home-lines`), the only row not on master. Rules: his day runs 4 am to 4 am; 4 to 7 am is "early morning", then morning, afternoon, evening, night; after Shutdown (9 pm) Now reads "tomorrow, first" and picks only tasks in the current 4 am day; quiet hours 11 pm to 7 am (Product, 12:29 pm); times are 12-hour, lower case, with a space ("9:30 am", "8 pm"), heroes included; "ago" and durations agree between Tess and Home; on a trip each item stays under the day where he was. Inputs: `docs/research/fixtures/home-lines-day-one.md` (Q rows, on disk, not yet on master) and `docs/research/house-copy-sweep.md` (rows 19 to 26).

Examples are Pacific (PDT): "his Friday" runs Fri 4 am to Sat 4 am. Code-only text (logs, fixtures, model prompts, file names, the Day log's 24-hour column ruled fine on Oct 15) is not counted.

| Id | File:line | What it shows today | Rule broken | After | Owner |
|---|---|---|---|---|---|
| TW1 | `Features/Home/HomeLineHero.swift:101` (#366 only) | `DayLane(date: now)`: Sat 12:40 am reads "Saturday night" (wall date) | Day label on wall clock (Q24) | Take the date from `HomeData.lanes` / `TesseraDay().day(of: now)`: "Friday night" | Builder B |
| TW2 | `Features/Home/HomeSpatialView.swift:675-681` | `partOfDay`: 4 am is "night", 5 am already "morning" | 4 to 7 am is "early morning" (12:29) | 4..<7 "early morning", 7..<12 "morning" | Builder B |
| TW3 | `HomeSpatialView.swift:679` vs `TesseraCore/.../Tasks/NowRanker.swift:36-37`, `Home/HomeLines.swift:380-386` | Label "Friday evening" until 10 pm while lines say "tonight" from 9 pm | Label and Home line disagree | Label "night" from 9 pm (DayPart `.shutdown`); one table for both (see Q2) | Builder B |
| TW4 | `Features/Home/NowPage.swift:361` | DoneHero "trained this night" (10 pm to 5 am) | Not a phrase; 4 to 7 am word | "trained tonight"; "trained early this morning" | Builder B |
| TW5 | `Features/Home/TrainingPage.swift:316` | "done this night" | Same as TW4 | "done tonight", "done early this morning" | Builder B |
| TW6 | `HomeSpatialView.swift:684-697` | `SpokenTime.when`: a 4:30 am item reads "tonight at half past four"; "this evening at six"; no caller outside tests | 4 to 7 am word; times in words, not digits | Delete, or "early this morning at 4:30 am" through `sentenceTime` | Builder B |
| TW7 | `App/AppModel.swift:476, 493-496` | `currentTask` takes any undone task from now-14 h to now+12 h: at 9:01 pm Sunday's 9 am "Laundry" is the hero, no "tomorrow" (Q21, Q23) | Now picks only the current 4 am day | Filter to `TesseraDay().isSameDay(start, now)` | Builder B |
| TW8 | `HomeLines.swift:340-341` (no caller); no Shutdown on Now in Swift | After 9 pm Now never says "tomorrow, first" (Q1, Q21) | After Shutdown, "tomorrow, first" | Wire `HomeFacts` with `tomorrow: true` after Shutdown: "Pull A, tomorrow, first" | Builder B |
| TW9 | `App/AppClock.swift:47-50` | `Format.clock` is `%02d:%02d`: "18:30" | No 24-hour times he reads | 12-hour house form (share Core's `sentenceTime`); fixes TW10 to TW14 | Builder B |
| TW10 | `Features/Home/HomeQueue.swift:370, 279` | Next row "14:00"; VoiceOver "Pay rent, 14:00" (sweep 21, open; Q9) | 24-hour | "2 pm" | Builder B |
| TW11 | `NowPage.swift:294, 348` | Plan ghost row "18:30"; VoiceOver "Proposed: Run, 18:30" (sweep 20, open) | 24-hour | "6:30 pm" | Builder B |
| TW12 | `Features/Home/DayStrip.swift:127` | VoiceOver "Now 18:10." (sweep 22, open) | 24-hour | "Now 6:10 pm." | Builder B |
| TW13 | `Features/Workout/WorkoutFinishView.swift:96-97` | "Saturday, 23:40 to 00:50" for a Fri 11:40 pm session (sweep 23, open) | 24-hour; weekday from wall clock | "Friday, 11:40 pm to 12:50 am" (weekday of his day at start) | Builder A |
| TW14 | `Features/Objects/ObjectPage.swift:418` | date field "OCT 12 18:02" (sweep 25, open) | 24-hour | "Oct 12, 6:02 pm" | Builder A |
| TW15 | `Features/Settings/ClaudeSection.swift:493-494` | Locale time: "18:12" on a 24-hour phone, else "6:12" + narrow no-break space + "pm"; weekday of the raw instant (sweep 26, open) | House form; 4 am day | House form "Thu, Oct 16, 6:12 pm"; weekday from his day | Builder B |
| TW16 | `Widgets/RestLiveActivity.swift:243` (doc comment `:224`) | Always-On "Ready at 6:12 PM" (upper case, locale) or "18:12" (sweep 24, open) | Lower case, 12-hour | "Ready at 6:12 pm" | Builder A |
| TW17 | `TesseraCore/.../Home/HomeLines.swift:272` | Cook hero "Tacos at 7" via `shortTime` (sweep 19, open; Q18) | Hero times carry "pm" | "Tacos at 7 pm" (`sentenceTime`) | Core |
| TW18 | `NowRanker.swift:114, 281, 284, 334-336` | `Pick.why` "Running since 18:02", "at 18:30"; not drawn today | 24-hour, latent | `sentenceTime` before anything shows `why` | Core |
| TW19 | `NowPage.swift:162-163` | "next, at half past six", "now, until twenty to four" | Times in words; D1 rules digits (sweep "Unsure", sent to Design) | "next, at 6:30 pm", "now, until 3:40 pm" | Builder B |
| TW20 | `NowPage.swift:565-573` vs `HomeLines.swift:421-430` | Ledger: 1 h 50 min is "1 h ago", "just now" under 1 min; Core: "2 h ago", "just now" under 2 min | "ago" must agree | Ledger calls `HomeLines.ago` | Builder B |
| TW21 | `Features/Notes/NotesView.swift:262-267` | 1 h 50 min is "1 h"; spoken "1 hours ago" | Floors where Home rounds; plural | Round as `HomeLines.ago`; "1 hour ago" | Builder B |
| TW22 | `NotesView.swift:273` | Older note's weekday from the raw instant: Tue 1:30 am note shows "Tue" (his Monday) | 4 am day | Weekday of `TesseraDay().day(of:)` | Builder B |
| TW23 | `Features/Review/ReviewView.swift:144` | `ReviewCopy.day` for moved tasks and workouts: Fri 11:40 pm to 12:50 am session reads "Sat" | 4 am day | Weekday of his day | Builder B |
| TW24 | `Features/Backup/BackupView.swift:352` | "the last one Wednesday" for a 1:30 am Wed copy while `fileDay` (`:399`) calls it Tuesday's | 4 am day; two weekdays for one copy | Weekday of his day, as `fileDay` | Builder B |
| TW25 | `Features/Recipes/RecipePage.swift:404` | Cook line date from raw instant in the phone's zone | 4 am day; trip zone | His day in the cook's stored zone | Builder B |
| TW26 | `TesseraCore/.../Tess/TessMemory.swift:90` | "on Oct 17" for a cook at 12:30 am Oct 17 (his Oct 16) | 4 am day | Format `TesseraDay().day(of:)` | Core |
| TW27 | `TesseraCore/.../Tess/TessMemory+Turnover.swift:186-188` | "You cook most on Saturdays." counts Fri-night 12:30 am cooks as Saturday | 4 am day | Weekday of his day | Core |
| TW28 | `TesseraCore/.../TesseraTess/TessGrammar.swift:609` | "today"/"tonight" said at 1 am Sat resolve on the wall date: "tonight" is Sat 8 pm | 4 am day (see Q5) | Start from `TesseraDay().today(now)` | Core |
| TW29 | `TessGrammar.swift:740-744, 642` | `nextDate` uses the wall weekday: "thu" said Fri 1 am (his Thursday) jumps to next Thursday | 4 am day | Weekday offset from his day | Core |
| TW30 | `Features/Tess/SoulRouter.swift:67-71` | Tess rests 11 pm to 6 am | Quiet hours 11 pm to 7 am | `hour >= 23 \|\| hour < 7` | Builder B |

**Counts:** 30 rows: Core 6 (TW17, TW18, TW26 to TW29), Builder A 3 (TW13, TW14, TW16), Builder B 21. All eight time rows of `house-copy-sweep.md` (19 to 26) are still open on master; TW9 alone closes four of them.

**Clean on master:** `HomeData.lanes` and `DayLane.phrase` use his day (master, not #366); `HomeLines.weekday`, `dayWord`, `sentenceTime`; `TessCaptureEngine.when` ("Saturday 9 am", weekday named between midnight and 4 am); `TessGrammar` "tomorrow" and `pastDay`; `MoveTask` (same wall time on his next day); `RecipePage.relative`; `ExerciseDigest.historyDate` (stored zone, R34); `BackupView.fileDay`; `NotesView` "yesterday"; `TessMemory+Turnover.clock` ("6 pm to 8 pm"); `DayLoad` 7 am to 11 pm. No user notifications exist yet; the Siri dialogs (`TesseraIntents/Intents.swift`) carry no times.

## Unsure (not counted)

- `TessModelCapture.swift:60` and `PlanWording.swift:62-63, 537-538` hand the model "HH:mm"; the Plan prompt asks for "7:30 am" (`:661`), but nothing checks the model's lines for a 24-hour time before they show.
- `NowPage.swift:171` meta "IN 2 H" floors 179 min; it is a label word, not an "ago", so left out.
- `HomeLines.swift:274-275` says "Tacos tonight" from 5 pm while `dayWord` says "this evening" until 9 pm; a cook may simply be an evening thing (Kitchen lead, G8).

## Questions for Product

1. Context word for 4 to 7 am: `HomeLines.swift:392` says "this morning" for a 5:30 am finish. "early this morning", or is "early morning" only the label word?
2. 9 to 10 pm: label "Friday night" (match "tonight", TW3), or keep "evening" until 10 pm and move the lines to 10 pm?
3. Before Shutdown is built, should 9 pm itself flip Now to "tomorrow, first" (TW8), or only once Shutdown is done?
4. TW19: confirm digits ("next, at 6:30 pm") over words on Now's context line, so Design can drop `SpokenTime.clock`.
5. "tonight" said at 1 am Saturday (TW28): the rest of his Friday (next hour), or Saturday evening?
6. Backup and Settings (TW15, TW24) aren't in either builder's list; I put them with Builder B. Correct me if they belong elsewhere.
