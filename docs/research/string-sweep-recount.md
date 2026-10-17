# String sweep recount (Research BS)

Scope: 55 app and engine files changed since a36b161 on origin/master (Features, TesseraCore/Sources, App, DesignSystem; tests excluded). Method: `git grep -n` for user-visible string literals per ruling. Comments, tests and docs ignored. This is a grep sweep, so it finds literals, not strings built from several pieces at run time. Widget targets had no changed files in scope.

Rulings read from decisions.md: 5:11 pm (no "at" before a day-and-time), 2:29 pm (thing-first receipts, bare "Logged." becomes "Set, logged.", no trailing e1RM on set receipts, straight apostrophes), 2:15 pm (Siri never says a bare "Saved."), 1:48 and 1:35 pm (UNDO wording), 2:44 pm and house clock rules.

## Counts per ruling

| Ruling | Misses | Note |
|---|---|---|
| No "at" before a time (5:11 pm) | 6 | 5 in HomeLines/Tasks/NowPage/HomePlan, plus the HomeLines:273 code comment still teaches "Tacos at 7 pm" |
| Thing first, no verb-first receipt (2:29 pm) | 4 | Siri dialogs and the set receipt text |
| Bare "Logged." / "Saved." fallback | 3 | WorkoutParts:245, Intents:201, BackupView:184 |
| No e1RM on set receipts (2:29 pm) | 1 | CaptureParts:243 |
| Em-dash U+2014 in user-visible text | 1 | SwapPanel:102 placeholder (EngineAction:68 is a tool description for the model, listed as a watch item) |
| 24-hour clock in user-visible text | 0 | BottomChrome:703 is a typing demo (see watch) |
| Uppercase AM/PM | 0 | |
| "best", never "record"/"PR" | 0 | ReviewWeek:133 matches on the words "record"/" pr" in input text, not shown |
| US English | 0 | "litre"/"millilitre" are enum cases, shown as "l" and "ml" |
| Private note/task/memory labels | 0 | |
| One UNDO wording | 0 | Receipts.swift:9 "Taken back." / "X, taken back." and Intents:85 "Set N taken back." are consistent |
| Money only with amount or sign | 0 found | grep for "$" literals showed nothing walled-shaped; needs a runtime check, not a grep |

Total misses: 15 (excluding watch items).

## Misses

| # | File:line | String | Ruling | Proposed replacement | Owner |
|---|---|---|---|---|---|
| 1 | TesseraCore/Sources/TesseraCore/Home/HomeLines.swift:260 | `"\(title) at \(sentenceTime)."` | 5:11 pm, no "at" | `"\(title) \(sentenceTime)."` ("Tacos 7 pm.") | Core |
| 2 | HomeLines.swift:273 | `"\(title) at \(clock)"` (comment also says "Tacos at 7 pm") | 5:11 pm | `"\(title) \(clock)"`; fix the comment | Core |
| 3 | HomeLines.swift:296 | `"\(title) at \(sentenceTime)"` | 5:11 pm | `"\(title) \(sentenceTime)"` | Core |
| 4 | TesseraCore/Sources/TesseraCore/Tasks/Tasks.swift:174 | `"\(title), \(word) at \(time)"` | 5:11 pm (this is the receipt shape) | `"\(title), \(word) \(time)"` ("Call mom, tomorrow 6:30 pm") | Core |
| 5 | Features/Home/HomePlan.swift:221 | `"\(count), \(workout.title) at \(clock)"` (comment says "Push A at 6 pm") | 5:11 pm | `"\(count), \(workout.title) \(clock)"` | Builder B |
| 6 | Features/Home/NowPage.swift:286 | `"next, at \(clock)"` | 5:11 pm | `"next, \(clock)"` | Builder B |
| 7 | TesseraCore/Sources/TesseraCore/Actions/TrainingActions.swift:90 | `"Logged \(name) \(shown) × \(count)"` | 2:29 pm thing-first | `"\(Name), \(shown) × \(count), logged"` ("Bench press 82.5 × 8, logged.") | Core |
| 8 | TrainingActions.swift:397 | `"Logged \(name) \(sets)×\(reps) at \(kg)"` | thing-first | `"\(Name) \(sets) × \(reps), \(kg), logged"` | Core |
| 9 | TesseraCore/Sources/TesseraIntents/Intents.swift:34, :57, :175 | `"\(record.summary)."` (carries the verb-first summary to Siri) | thing-first | follows from 7 and 8; no change in Intents once Core fixes summary | Core |
| 10 | TesseraCore/Sources/TesseraTess/TessCaptureEngine.swift:274 | `"\(name) \(scheme) at \(load). Added to today."` | thing-first receipts; "at" is a load not a time, so low | `"\(name) \(scheme), \(load). Added to today."` (optional) | Core |
| 11 | Features/Workout/WorkoutParts.swift:245 | `"Logged."` | 2:29 pm: bare fallback becomes "Set, logged." | `"Set, logged."` | Builder A |
| 12 | TesseraCore/Sources/TesseraIntents/Intents.swift:201 | `"Saved."` | 2:15 pm: Siri never says a bare "Saved." | `"Private note, kept."` (use TessCapture.privateLine) | Core |
| 13 | Features/Backup/BackupView.swift:184 | `say("Saved.")` | thing-first | `say("Backup folder, saved.")` (name the thing) | Builder B |
| 14 | Features/Command/CaptureParts.swift:243 | `"\(line) e1RM \(kg)."` | 2:29 pm: e1RM comes off set receipts | drop the e1RM suffix; keep it on the exercise page | Builder A |
| 15 | Features/Workout/SwapPanel.swift:102 | `"\u{2014}"` (an em-dash glyph as "no load") | no U+2014 in user-visible text | `"none"` or `"no load"` | Builder A |

## Watch items (not counted)

- TesseraCore/Sources/TesseraCore/Actions/EngineAction.swift:68 has an em-dash in a tool summary string. It goes to the model and logs, not the screen. Replace with ": " if it can ever surface.
- Features/Command/BottomChrome.swift:703 types "stretch at 21:30" as a demo phrase. It is typed input, but it shows on screen while it types. Consider "stretch 9:30 pm".
- TesseraCore/Sources/TesseraTess/TessModelCapture.swift:61 and :67 format "HH:mm" and "04:00" in the model prompt only. Not user-visible; no change.
- Features/Backup/BackupView.swift:303 "The folder is back." fits the 1:48 pm "Thing is back." rule only if it reads "Backup folder is back."; check with Builder B.

## Clean rulings (zero misses)

- Uppercase "8:30 PM" style clocks
- 24-hour clocks in shown text
- "best" vs "record" / "PR" for a lift
- US English spelling
- "Private note" / "Private task" / "Private memory" labels
- One UNDO wording (Taken back / is back)
- Money only with an amount or sign (no literal found; verify at run time)

## Recheck on master ab7d3bf

Recheck of the 15 misses above against origin/master ab7d3bf (read through a fetched worktree; no checkout or commit in the repo). Result: 0 fixed, 0 gone, 15 still open. Line numbers below are the current ones.

| # | Status | Evidence on master (file:line) |
|---|---|---|
| 1 | Still there | TesseraCore/Sources/TesseraCore/Home/HomeLines.swift:260, `"\(fact.title) at \(DayStoryClock.sentenceTime(...))."` |
| 2 | Still there | HomeLines.swift:273 `"\(fact.title) at \(HouseTime.clock(...))"`; the comment at :272 still teaches "Tacos at 7 pm" |
| 3 | Still there | HomeLines.swift:296 `"\(fact.title) at \(DayStoryClock.sentenceTime(...))"` |
| 4 | Still there | TesseraCore/Sources/TesseraCore/Tasks/Tasks.swift:174, `"\(object.title), \(word) at \(...)"` |
| 5 | Still there | Features/Home/HomePlan.swift:221, `"\(count), \(workout.title) at \(clock)"` |
| 6 | Still there | Features/Home/NowPage.swift:286, `"next, at \(SpokenTime.clock(task.start))"` |
| 7 | Still there | TesseraCore/Sources/TesseraCore/Actions/TrainingActions.swift:90, `"Logged \(name) \(shown) × \(count(reps))"` |
| 8 | Still there | TrainingActions.swift:397, `"Logged \(name) ... at \(kilograms(weight)) ..."` |
| 9 | Still there | TesseraCore/Sources/TesseraIntents/Intents.swift:34, :57, :175, `"\(record.summary)."`; these inherit the text from rows 7 and 8 |
| 10 | Still there | TesseraCore/Sources/TesseraTess/TessCaptureEngine.swift:274, `"\(name) \(scheme) at \(load). Added to today."` |
| 11 | Still there | Features/Workout/WorkoutParts.swift:245, `?? "Logged."` (the numbered case is already "Set N logged.") |
| 12 | Still there | TesseraCore/Sources/TesseraIntents/Intents.swift:201, `hidden ? "Saved." : capture.line` |
| 13 | Still there | Features/Backup/BackupView.swift:184, `say("Saved.")` |
| 14 | Still there | Features/Command/CaptureParts.swift:243, `"\(line) e1RM \(Format.kilograms($0))."` |
| 15 | Still there | Features/Workout/SwapPanel.swift:102, `return "<U+2014>"` (U+2014 as the no-load value) |

### New hits on master (not in rows 1 to 15)

Scope: Features/, App/ and TesseraCore/Sources/ on origin/master ab7d3bf. Comments, tests and docs skipped. The original recount covered only the 55 changed files, so these are new relative to it. Strings that build a time from several pieces at run time are not caught by grep.

**(a) "at" before a clock time**

| File:line | String | Owner | Note |
|---|---|---|---|
| Features/Home/HomeSpatialView.swift:691 | `"at \(clock(...))"`, used in "tonight at ...", "this \(part) at ..." | Builder B | Shown text, same ruling as rows 1 to 6 |
| TesseraCore/Sources/TesseraCore/Tasks/NowRanker.swift:281, :284 | `why.append("at \(clock(start, calendar))")` | Core | Shown only if the "why" list reaches the screen; not verified |

Not counted (not a clock time): TessSetCountAsk.swift:96 "at \(load)" (same class as row 10, Core); Intents.swift:26 Summary "at \(weight) kg" (Core); TessGrammar+Live.swift:134 "Fail at \(match.1)" (Core). Watch item BottomChrome.swift:703 unchanged.

**(b) Verb-first receipts as a whole string**

Clear receipts (should move to thing first):

| File:line | String | Owner |
|---|---|---|
| Features/Backup/BackupView.swift:168 | "Saved a copy there. One a day from now on." | Builder B |
| Features/Groceries/GroceriesView.swift:260 | "Cleared \(count) from the basket." | Builder B |
| Features/Home/NowPage.swift:319 | "Done. Next one is up." | Builder B |
| App/AppModel.swift:170 | "Started fresh; your old data is saved in Backups." | App (no owner listed) |
| TesseraCore/Sources/TesseraIntents/Intents.swift:129 | "Finished. \(n) of \(m) exercises." (Siri dialog) | Core |
| TesseraCore/Sources/TesseraCore/Training/Prefill.swift:102, :103 | "Logged a set" / "Logged \(weight) × \(reps)" | Core |
| TesseraCore/Sources/TesseraTess/ClaudeTessModel.swift:136 | "Sent “…” to Claude. Turn this off in Settings: Claude." | Core |
| TesseraCore/Sources/TesseraCore/Actions/TrainingActions.swift:196, :227, :258, :295, :445, :535 | "Added ...", "Started ...", "Finished ...", "Finished ... early", "Added “…”", "Deleted ..." | Core |
| TesseraCore/Sources/TesseraCore/Actions/PlanActions.swift:25, :93, :143, :183 | "Created ...", "Added ... to the routine", "Started ...", "Created ..." | Core |
| TesseraCore/Sources/TesseraCore/Actions/PlanEditing.swift:117 | "Moved ..." | Core |
| TesseraCore/Sources/TesseraCore/Actions/RoutineEditing.swift:37, :142 | "Moved \(name) to \(n)", "Removed \(name)" | Core |
| TesseraCore/Sources/TesseraCore/Lists/Lists.swift:147, :233, :304 | "Added \(text)", "Moved ...", "Cleared ..." | Core |
| TesseraCore/Sources/TesseraCore/Kitchen/Groceries.swift:431 | "Added \(lines[0])" / "Added N things" | Core |
| TesseraCore/Sources/TesseraCore/Kitchen/Recipes.swift:247 | "Saved \(title)" | Core |
| TesseraCore/Sources/TesseraCore/Processes/ProcessActions.swift:54, :85, :187, :188 | "Started ...", "Saved your place", "Finished ...", "Closed ..." | Core |
| TesseraCore/Sources/TesseraCore/Tasks/TaskProcesses.swift:28 | "Started ..." | Core |
| TesseraCore/Sources/TesseraCore/DayLog/DayStory.swift:338 | "Added \(...)" (day-log line) | Core |

Borderline (state labels, not receipts; confirm): Features/Home/TrainingPage.swift:257 "Done for today"; Features/Home/ReviewPage.swift:146 "Done N of the last N days"; TesseraCore/Sources/TesseraCore/Kitchen/Shopping.swift:70 "Finished shopping".

**(c) Em-dash glyph (U+2014) as a placeholder in shown text**

| File:line | String | Owner |
|---|---|---|
| Features/Exercise/ExercisePage.swift:144, :146 | `?? "<U+2014>"` (stat value) | Builder A (Training domain; confirm) |
| Features/Exercise/ExerciseViews.swift:188 | `?? "<U+2014>"` (rep max value) | Builder A (Training domain; confirm) |
| Features/Objects/ObjectPage.swift:172, :174, :410, :418 | `?? "<U+2014>"` and `Text("<U+2014>")` | Not in the A or B lists; needs an owner |

Watch item unchanged: TesseraCore/Sources/TesseraCore/Actions/EngineAction.swift:68 (model-facing, not on screen).

**(d) Uppercase AM/PM**

None in shown text. Every hit is in a comment.

### Counts on master ab7d3bf

Rows 1 to 15: 0 fixed, 0 gone, 15 still open. New hits: 2 for (a), about 35 lines for (b) (of which 4 borderline), 8 lines for (c) (2 files at Builder A to confirm, 1 file with no owner), 0 for (d).
