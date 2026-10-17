# House copy sweep of master (Research lab)

For: Core, Builder A, Builder B. Owner: Research lab. Date: Oct 16, 2026 (Pacific).
Master `0eca9bb` (#446). Read by hand and grep, nothing was run. Rulings from `docs/research/copy-one-voice.md`, `docs/research/one-wording-check.md` and `docs/product/decisions.md` (there is no `docs/ops/decisions.md`; the log lives under `docs/product/`), up to Product's 11:50 AM PT calls.

Scanned: 208 Swift files in `App/`, `Features/`, `DesignSystem/`, `TesseraCore/Sources/`, `Widgets/` and `Shared/` (tests skipped), about 6,050 string literals that hold a letter. Strings that only go to the model, logs or SQL are left out.

Rules: (1) "best" on screen, never "PR" or its long form; (2) receipts name the thing first, the Day log keeps "Done: ..." and "Added ..."; (3) hero times carry "am"/"pm", no 24-hour times on screen, Review hero count in words; (4) no em-dashes in shown strings, US spelling, kg; (5) secret-word refusal reads "Private note, kept. It stays out of my memory."

Note: #366 is still open, so nothing in `Features/` reads `HomeLines` yet. The HomeLines row below fixes the lens before it goes on screen.

## Misses

| # | File:line | String now | Proposed | Rule | Owner |
|---|---|---|---|---|---|
| 1 | `TesseraCore/Sources/TesseraCore/DayLog/DayStory.swift:225` | ". Bench 80 × 8, PR." | ". Bench 80 × 8, best." (3:15 AM: the Day log moves to "best") | 1 | Core |
| 2 | `Features/Home/ReviewWeek.swift:175` | "Push best" (first word of the ", PR." line) | Read ", best." and take the exercise: "Bench best" | 1 | Builder B |
| 3 | `TesseraCore/Sources/TesseraCore/Catalog/SystemCatalog.swift:162` | field name "Record" (object pages) | "Best" | 1 | Core |
| 4 | `Features/Home/NowPage.swift:196` | "Done. Next one is up." | "Call mom, done." (always `\(task.title), done.`) | 2 | Builder B |
| 5 | `Features/Home/HomeQueue.swift:473` | "Moved to tomorrow." / "Moved to next week." | "Call mom, tomorrow." / "Call mom, next week." | 2 | Builder B |
| 6 | `Features/Groceries/GroceriesView.swift:260` | "Cleared 3 from the basket." | "Basket, 3 cleared." | 2 | Builder B |
| 7 | `TesseraCore/Sources/TesseraIntents/Intents.swift:31` | "Logged bench press 3×8 at 82.5 kg." (op summary) | "Bench press 3 × 8 at 82.5 kg, logged." | 2 | Builder A (Siri) |
| 8 | `TesseraCore/Sources/TesseraIntents/Intents.swift:51` | "Logged 82.5 × 8." (`Prefill.swift:103`) | "Set 4 logged. 82.5 × 8." (as the live workout says it) | 2 | Builder A (Siri) |
| 9 | `TesseraCore/Sources/TesseraIntents/Intents.swift:114` | "Finished. 6 of 6 exercises." | "Push A done. 6 of 6 exercises." | 2 | Builder A (Siri) |
| 10 | `TesseraCore/Sources/TesseraIntents/Intents.swift:132` | "Added “Call mom”." | "Call mom, added." | 2 | Builder A (Siri) |
| 11 | `Features/Workout/SwapPanel.swift:127` | "Done. 85 for sets 2 to 4." | "Sets 2 to 4, 85 kg." | 2 | Builder A |
| 12 | `Features/Workout/WorkoutParts.swift:253` | "Logged." | "Set 3 logged." | 2 | Builder A |
| 13 | `Features/Command/CaptureParts.swift:220` | "Logged bench press 82.5 × 8 · e1RM 105." | "Bench press 82.5 × 8, logged." (the e1RM tail also breaks the no " · " rule) | 2 | Builder A |
| 14 | `Features/Plans/RoutineEditor.swift:194, 221` | op summary + ".": "Removed Bench press.", "Moved Bench press to 3.", "Swapped in Squat."; undo "Undone." | "Bench press, removed.", "Bench press, moved to 3.", "Squat, swapped in."; undo "Bench press, taken back." | 2 | Builder A |
| 15 | `TesseraCore/Sources/TesseraTess/ClaudeTessModel.swift:124`, `TessModelCapture.swift:44` | fallback receipt is the op summary: "Done: Call mom.", "Added milk.", "Cooked Chili." | Thing first: "Call mom, done.", "Milk, added.", "Chili, done." | 2 | Core |
| 16 | `TesseraCore/Sources/TesseraCore/Tess/TessMemory.swift:266` | "Kept. You rest on Sundays." | "Rest on Sundays, kept." (`{value words}, kept.`) | 2 | Core |
| 17 | `TesseraCore/Sources/TesseraCore/Tess/TessMemory.swift:324` | "Everything forgotten, 12 things." | "12 things, forgotten." | 2 | Core |
| 18 | op summaries that reach Siri and the fallbacks: `TrainingActions.swift:90, 397, 445, 481`, `Lists.swift:143`, `Cooking.swift:256`, `RoutineEditing.swift:37, 142, 171`, `PlanActions.swift:93` | verb first ("Logged ...", "Added ...", "Done: ...", "Cooked ...") | Either thing first, or keep them as log lines and stop showing them raw (rows 7 to 15) | 2 | Core |
| 19 | `TesseraCore/Sources/TesseraCore/Home/HomeLines.swift:272` | "Tacos at 7" | "Tacos at 7 pm" (use `sentenceTime`, Product 11:50 AM) | 3 | Core |
| 20 | `Features/Home/NowPage.swift:294, 348` | Plan ghost row time "18:30"; VoiceOver "Proposed: Run, 18:30" | "6:30 pm" | 3 | Builder B |
| 21 | `Features/Home/HomeQueue.swift:370, 279` | Next row time column "18:30"; VoiceOver "Call mom, 18:30" | "6:30 pm" | 3 | Builder B |
| 22 | `Features/Home/DayStrip.swift:127` | VoiceOver "Now 18:10." | "Now 6:10 pm." | 3 | Builder B |
| 23 | `Features/Workout/WorkoutFinishView.swift:97` | "Thursday, 18:02 to 19:10" | "Thursday, 6:02 to 7:10 pm" | 3 | Builder A |
| 24 | `Widgets/RestLiveActivity.swift:243` | always-on "Ready at 6:12 PM" (locale format, upper case) | "Ready at 6:12 pm" (house form, not locale) | 3 | Builder A |
| 25 | `Features/Objects/ObjectPage.swift:418` | date field "Oct 12 18:02" | "Oct 12, 6:02 pm" | 3 | Builder A |
| 26 | `Features/Settings/ClaudeSection.swift:494` | call time via `.dateTime.hour().minute()`: "18:12" on a 24-hour phone | House form, always "6:12 pm" | 3 | Builder B |
| 27 | `Features/Objects/ObjectPage.swift:172, 174` | em-dash for no best e1RM / no top set | "none yet" | 4 | Builder A |
| 28 | `Features/Objects/ObjectPage.swift:401, 409` | em-dash for an empty field | "empty" | 4 | Builder A (no clear owner) |
| 29 | `Features/Workout/SwapPanel.swift:102` | em-dash when an option has no load | "no load yet" | 4 | Builder A |
| 30 | `Features/Exercise/ExerciseViews.swift:188` | em-dash in the rep-max table | "none" | 4 | Builder A |
| 31 | `Features/Exercise/ExercisePage.swift:144, 146` | em-dash for no best e1RM / best set | "none yet" | 4 | Builder A |
| 32 | `DesignSystem/Looks.swift:98, 99` | "Colour pools only behind what matters now." / "Colour turns to light and glows." | "Color pools ..." / "Color turns ..." | 4 | Builder A (themes) |
| 33 | `Features/Backup/BackupView.swift:221` | "Cancelled. Nothing will be replaced." | "Canceled. Nothing will be replaced." | 4 | Builder B |
| 34 | `Features/Objects/ObjectPage.swift:172, 298, 416` | "105kg", "  82.5kg" (no space) | "105 kg", "82.5 kg" | 4 | Builder A |
| 35 | `TesseraCore/Sources/TesseraTess/TessCaptureEngine.swift:300` | "Private note, kept. I don't keep passwords." | "Private note, kept. It stays out of my memory." | 5 | Core |
| 36 | `TesseraCore/Sources/TesseraCore/Tess/TessMemory.swift:124` | `Refusal.secret.line` "I don't keep passwords." | "It stays out of my memory." (Core board, AI-3 small pull request) | 5 | Core |
| 37 | `TesseraCore/Sources/TesseraCore/Tess/TessMemory.swift:270-283` | `RememberFact.refusalLine` returns nil for a secret, so no line | Return "Private note, kept. It stays out of my memory." | 5 | Core |

## Counts

| Rule | Misses | | Owner | Misses |
|---|---|---|---|---|
| 1 best | 3 | | Builder A | 18 |
| 2 thing first | 15 | | Builder B | 9 |
| 3 times | 8 | | Core | 10 |
| 4 dashes, spelling, kg | 8 | | | |
| 5 secret words | 3 | | **Total** | **37** |

Clean on master: WorkoutSummary, HomeLines and ExerciseViews say "best"; the widget and Live Activity say no "PR"; task, cook and recipe receipts are thing first (`HomeQueue.swift:452`, `TessCaptureEngine.swift:372`, `Groceries.swift:362` "Tacos, 10 added."); the Day log's "Done: ..." and "Added ..." (`DayStory.swift:333, 339`) stand by the 11:50 AM ruling; the Review hero count is in words (`ReviewPage.swift:41-44`, `ReviewWeek.swift:75-77`); grocery lb and oz follow the US shop rule; plain "note: ..." with a secret keeps "Private note, kept." (R6).

## Unsure

- **The time column.** The Day log's "07:10" column was ruled fine (7:34 PM Oct 15). Rows 20 and 21 are Home's own time columns, not the Day log, so I counted them; if Design treats them as the same column, drop them. Review's tapped day (`ReviewWeek.swift:193`) reuses the Day log column and I left it alone.
- **Siri's owner.** `TesseraIntents` sits in the Core package, but 143 put Siri wording on Builder A and the summaries on Core. Rows 7 to 10 can be fixed in the dialog (Builder A) or in row 18 (Core); one of them, not both.
- **Op summaries (row 18).** They are log text, like the Day log. Product could rule they stay verb first and are never shown raw, which makes rows 7 to 15 the only fixes.
- **Context times.** `NowPage.swift:162-163` says "next, at half past six" in words. It isn't a 24-hour time or a hero, so it isn't counted; 143 W13 wants "next, at 6:30 pm" once #366 lands.
- **Review hero wording.** `ReviewWeek.swift:75` says "All six sessions"; the ruling's example is "All six sessions in" (as `ReviewPage.swift:44` has it). Words either way, so not counted.
- **Ellipses** ("Reading tacocat.com…", `RecipeLinkReader.swift:22`) break a house rule but not today's five, so they are left out.

**Product rulings (12:01 PM PT):** Siri replies belong to Core (TesseraIntents) and speak thing-first receipts; op summaries stay verb-first log text and are never read aloud raw. Home's times count as misses (Home reads "6:30 pm"; only the Day log keeps its 24-hour column), so rows 20 and 21 stay. "Half past six" in words and "All six sessions" vs "...in" go to Design (D1 already rules digits, "5:30 pm").
