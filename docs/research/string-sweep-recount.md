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
