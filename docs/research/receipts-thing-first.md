# Receipts, thing first (Research lab, Product item S)

For: Core, Builder A, Builder B. Owner: Research lab. Date: Oct 16, 2026 (Pacific).
Master `40af0f1`. Read by hand and grep, nothing was run. Line numbers are master's (some starting points in the brief had drifted: `NowPage.swift:242` is now 196, `HomeQueue.swift:480` is now 473).

House rule: a receipt (the short line shown or spoken after create, log, add, move, done, clear, undo, delete, reset, put away, a Siri reply, a Tess capture line, an UNDO line) names the THING first: "Charger, on Packing.", "Push A done", "Bench 82.5 × 8, logged." Also checked on every receipt: no em-dashes, "best" never "record" or "PR", US spelling, times with am/pm.

Builds on `docs/research/house-copy-sweep.md` (master `0eca9bb`). Rows it already lists that still fail are marked "still open from house-copy-sweep #n". Its 12:01 PM ruling stands: op summaries are verb-first log text and are never read aloud raw. So the op-summary rows here (RC24 to RC32) fail only because RC23 (and Siri, RC13 to RC16) shows them raw.

## Receipts

| id | File:line | Line today | Pass/fail | After (thing first) | Owner |
|---|---|---|---|---|---|
| RC1 | `Features/Home/NowPage.swift:196` | "Done. Next one is up." (when another task follows) | fail, still open from house-copy-sweep #4 | "Call mom, done." | Builder B |
| RC2 | `Features/Home/HomeQueue.swift:473` | "Moved to tomorrow." / "Moved to next week." | fail, still open from house-copy-sweep #5 | "Call mom, tomorrow." / "Call mom, next week." | Builder B |
| RC3 | `Features/Groceries/GroceriesView.swift:260` | "Cleared 3 from the basket." | fail, still open from house-copy-sweep #6 | "Basket, 3 cleared." | Builder B |
| RC4 | `Features/Backup/BackupView.swift:168` | "Saved a copy there. One a day from now on." | fail | "Copy, saved there. One a day from now on." | Builder B |
| RC5 | `Features/Backup/BackupView.swift:184` | "Saved." | fail | "Backup, saved." | Builder B |
| RC6 | `Features/Backup/BackupView.swift:221` | "Cancelled. Nothing will be replaced." | fail (spelling still open from house-copy-sweep #33; verb first is new) | "Restore, canceled. Nothing will be replaced." | Builder B |
| RC7 | `Features/Plans/RoutinesPage.swift:267` | "Taken back." (UNDO line) | fail | "Push A, taken back." (title of what the undo touched) | Builder A |
| RC8 | `Features/Plans/RoutineEditor.swift:194` | op summary + ".": "Removed Bench press.", "Moved Bench press to 3.", "Swapped in Squat.", "Added bench press to the routine." | fail, still open from house-copy-sweep #14 | "Bench press, removed.", "Bench press, moved to 3.", "Squat, swapped in.", "Bench press, added." | Builder A |
| RC9 | `Features/Plans/RoutineEditor.swift:221` | "Undone." | fail, still open from house-copy-sweep #14 | "Bench press, taken back." | Builder A |
| RC10 | `Features/Workout/WorkoutParts.swift:253` | "Logged." | fail, still open from house-copy-sweep #12 | "Set 3 logged." | Builder A |
| RC11 | `Features/Workout/SwapPanel.swift:127` | "Done. 85 for sets 2 to 4." | fail, still open from house-copy-sweep #11 | "Sets 2 to 4, 85 kg." | Builder A |
| RC12 | `Features/Command/CaptureParts.swift:220` | "Logged bench press 82.5 × 8 · e1RM 105." | fail, still open from house-copy-sweep #13 | "Bench press 82.5 × 8, logged." | Builder A |
| RC13 | `TesseraCore/Sources/TesseraIntents/Intents.swift:31` | "Logged bench press 3×8 at 82.5 kg." (Siri) | fail, still open from house-copy-sweep #7 | "Bench press 3 × 8 at 82.5 kg, logged." | Core |
| RC14 | `TesseraIntents/Intents.swift:51` (`Prefill.swift:103`) | "Logged 82.5 × 8." (Siri, Lock Screen) | fail, still open from house-copy-sweep #8 | "Set 4 logged. 82.5 × 8." | Core |
| RC15 | `TesseraIntents/Intents.swift:114` | "Finished. 6 of 6 exercises." (Siri) | fail, still open from house-copy-sweep #9 | "Push A done. 6 of 6 exercises." | Core |
| RC16 | `TesseraIntents/Intents.swift:144` (`TrainingActions.swift:445`) | "Added “Call mom”." (Siri) | fail, still open from house-copy-sweep #10 | "Call mom, added." | Core |
| RC17 | `TesseraTess/TessCaptureEngine.swift:304` | "Noted for Monday." | fail | "Note, for Monday." | Core |
| RC18 | `TesseraTess/TessCaptureEngine.swift:313` | "Noted, linked." / "Noted." | fail | "Note, linked." / "Note, kept." (as "Private note, kept.") | Core |
| RC19 | `TesseraTess/TessCaptureEngine.swift:337` | "Rice, on the list." / "3 things on the list." | pass (thing first); the list goes unnamed, see Q2 | "Rice, on Groceries." / "3 things, on Groceries." | Core |
| RC20 | `TesseraTess/TessCaptureEngine.swift:346` | "Cooking chili." | fail | "Chili, cooking." | Core |
| RC21 | `TesseraTess/TessCaptureEngine.swift:355` | "New list: Films." | fail | "Films, made." (as "Push A made.") | Core |
| RC22 | `TesseraTess/TessCaptureEngine.swift:382` | "12 ingredients, 5 steps." (recipe saved from a capture) | fail (no thing at all) | "Chili, saved. 12 ingredients, 5 steps." | Core |
| RC23 | `TesseraTess/ClaudeTessModel.swift:127`, `TessModelCapture.swift:44` | fallback receipt is the raw op summary + "." | fail, still open from house-copy-sweep #15 | Speak a thing-first line per action (RC24 to RC32 give the words) | Core |
| RC24 | `TesseraCore/Lists/Lists.swift:93` | "New list: Films" | fail (raw via RC23) | "Films, made" | Core |
| RC25 | `Lists/Lists.swift:143` | "Added charger" | fail (raw via RC23) | "Charger, on Packing" | Core |
| RC26 | `Lists/Lists.swift:177` | "Got rice" / "Back on the list: rice" | fail (raw via RC23) | "Rice, got" / "Rice, back on Packing" | Core |
| RC27 | `Lists/Lists.swift:219` | "Moved charger" | fail (raw via RC23) | "Charger, moved to Cables" | Core |
| RC28 | `Lists/Lists.swift:251` | "Renamed Cables to Tech" | fail (raw via RC23) | "Cables, now Tech" | Core |
| RC29 | `Lists/Lists.swift:280` | "Cleared Packing" | fail (raw via RC23) | "Packing, done items cleared" | Core |
| RC30 | `TesseraCore/Tasks/Tasks.swift:141` | "Moved Call mom to Later" / "Moved Call mom" | fail (raw via RC23) | "Call mom, in Later" / "Call mom, tomorrow 6:30 pm" | Core |
| RC31 | `TesseraCore/Kitchen/Groceries.swift:431` | "Added milk" / "Added 3 things" | fail (raw via RC23) | "Milk, on Groceries" / "3 things, on Groceries" | Core |
| RC32 | `TesseraCore/Actions/TrainingActions.swift:481` | "Done: Call mom" / "Reopened Call mom" | fail (raw via RC23), still open from house-copy-sweep #18 | "Call mom, done" / "Call mom, back on" | Core |
| RC33 | `TesseraCore/Tess/TessMemory.swift:264` | "Kept, on this phone only." | fail | "Knee, kept on this phone only." (see Q4) | Core |
| RC34 | `Tess/TessMemory.swift:266` | "Kept. You rest on Sundays." | fail, still open from house-copy-sweep #16 | "Rest on Sundays, kept." | Core |
| RC35 | `Tess/TessMemory.swift:324` | "Everything forgotten, 12 things." | fail, still open from house-copy-sweep #17 | "12 things, forgotten." | Core |
| RC36 | `TesseraTess/ClaudeTessModel.swift:132` | "Sent “tacocat” to Claude. Turn this off in Settings: Claude." (replaces the receipt on the first miss) | fail | "“tacocat”, sent to Claude. Turn this off in Settings: Claude." | Core |

Clean (thing first, no dash, no "record" or "PR", US spelling, am/pm): `HomeQueue.swift:452` "Call mom, done."; `NowPage.swift:196` last-task branch; `TessCaptureEngine.swift` 205 to 207 "Sets 2 to 4 logged.", 270 "Bench 3 × 8 at 80. Added to today.", 288 to 290 "Set 3 logged. 80 × 8.", 296 "Call mom, tomorrow 6:30 pm.", 300 "Private note, kept.", 335, 343, 352 "Pasta, 10 min.", 359 "Shopping, 4 left.", 362, 368 "Step 2.", 372 "Chili, done."; `Intents.swift` 76 "Set 3 taken back.", 96 "Push A started. 6 exercises.", 142; `Groceries.swift:362` "Tacos, 10 added."; `RoutinesPage.swift` 151, 184, 212, 232 ("Push A made.", "... dropped."); `RoutineEditor.swift:526` days receipt; `WorkoutParts.swift` 230, 232, 236; `WorkoutSession+Edit.swift` 42, 54, 97; `WorkoutModeView.swift:115` "Push A, back on."; `ProcessTable.swift` 124, 142, 149; `RecipeLinkReader.swift` 53, 57; `PasteRecipe.swift:243`; `RecipePage.swift` "12 to buy, in Groceries"; `TessMemory.swift:302`; `ClaudeSection.swift` 377, 391; `BackupView.swift:303`. No receipt carries an em-dash, "record", "PR" or a 24-hour time; the only spelling miss is RC6.

## Counts

| Owner | Fails | Still open from house-copy-sweep | New |
|---|---|---|---|
| Builder A | 6 (RC7 to RC12) | 5 | 1 |
| Builder B | 6 (RC1 to RC6) | 3 (plus RC6's spelling) | 3 |
| Core | 23 (RC13 to RC36, less RC19) | 8 | 15 |
| **Total** | **35** (plus 1 pass with a note) | **16** | **19** |

Nine of Core's 23 (RC24 to RC32) go away in one change if RC23 stops showing summaries raw.

## Questions for Product

1. **Fix at RC23 or in the summaries?** The 12:01 PM ruling keeps op summaries verb first. Then RC23 needs its own thing-first line per action (a `receipt` beside `summary`), and RC24 to RC32 close with it. Or rewrite the summaries thing first and the Day log's "New list:" (`DayStory.swift:88`) goes with them. One of the two.
2. **Name the list?** "Rice, on the list." (RC19) is thing first, but the line above it says "already on Groceries" and the house example is "Rice, on Packing." Should every list receipt name the list?
3. **"Films, made." or "Films, new list."?** RC21 and RC24 follow RoutinesPage's "Push A made."; Product's brief listed "New list: Films." as a fail without an after.
4. **Private memory lines (RC33).** A health line ("my knee hurts") gets "Kept, on this phone only." Saying the thing first means repeating part of it. Is a short noun ("Knee, kept on this phone only.") fine, or does the R6 no-repeat rule cover health words too (then "That, kept on this phone only.")?
5. **Is "Sent ... to Claude" (RC36) a receipt?** It replaces the receipt once, on the first miss. If it's a notice, not a receipt, drop RC36.
6. **UNDO lines naming the thing.** RC7 and RC9 need the title of what was undone; RoutinesPage undoes several records at once ("Push A made." is two records). Name the first, or the routine?
