# UI-bar audit of master bb7f082

Kaushik's principle, in one line: one screen packed for the moment, one plain line per thing, and every receipt names the thing first.

This audit was read from the SwiftUI and Core strings on master bb7f082 (Oct 16), and from #366's Home walk clip, which is not merged yet. Each screen on his phone path was checked against `ui-bar.md` and the house rules:
- one plain line per thing;
- receipts name the thing first;
- digits with a lower-case "pm" in heroes;
- label words on keys;
- " · " only as a pack size;
- Settings in the third person.

Each finding has one line: where it is, the fix, and who owns it.

## What passes
- **Keys are label words.** Every titled button on the phone path uses `.labelWord`, `InkLabelWordStyle` or a `.label` role, which uppercases it. The only exceptions are accessibility actions, which no one sees.
- **Settings stays in the third person.** There is no first person in `ClaudeSection` or `BackupView`. "Tess asks Claude when she's unsure, and for Plan my day." is right for now, because Today's Claude wording stays off until AI-5 passes.
- **Heroes use digits and a lower-case "pm".** `HomeLines.shortTime` and `TessCaptureEngine` both lower-case am and pm. The one exception is D1 below.
- **"best", never "record".** No on-screen string says "record".
- **Doors keep their "→".** "Look back at the week →", "Browse exercises →" and "Add an exercise →" are doors (`HandleButtonStyle`, as `ObjectHandle` draws them), not keys, so they stay.
- **The Day log keeps its own grammar.** "Done: call the bank" and "Added 2 tasks" are drawn that way in `day-log-v1.md`; they are a log, not receipts.

## Receipts: name the thing first
| # | Where | Now | Fix | Owner |
|---|---|---|---|---|
| R1 | `Features/Home/NowPage.swift:196` | "Done. Next one is up." | "\(task.title), done. Next one is up." The no-next branch already does this. | Builder B |
| R2 | `Features/Home/HomeQueue.swift:473` | "Moved to tomorrow." / "Moved to next week." | "\(entry.title), moved to tomorrow." / "\(entry.title), moved to next week." | Builder B |
| R3 | `Features/Groceries/GroceriesView.swift:260` | "Cleared 3 from the basket." | "Basket, 3 cleared." | Builder B |
| R4 | `Features/Backup/BackupView.swift:168` | "Saved a copy there. One a day from now on." | "Today's copy, saved there. One a day from now on." | Builder B |
| R5 | `Features/Backup/BackupView.swift:184` | "Saved." | "Copy, saved." | Builder B |
| R6 | `Features/Command/CaptureParts.swift:220` | "Logged bench 82.5 × 7 · e1RM 96." | "Bench, 82.5 × 7 logged. e1RM 96." The name is capitalised as the workout page writes it, and there is no " · ". | Builder A |
| R7 | `TesseraCore/Sources/TesseraTess/ClaudeTessModel.swift:124` | Falls back to `records[0].summary + "."`, or "3 things done." | Name the things: one record reads "<thing>, <what happened>."; two read "Milk and eggs, added."; more read "Milk, eggs and 2 more, added." The summaries below need the same form. | Core |
| R8 | `TesseraCore/Sources/TesseraCore/Lists/Lists.swift:143, 177, 219, 251, 280` | "Added X", "Got X", "Back on the list: X", "Moved X", "Renamed A to B", "Cleared <list>" | "X, added", "X, got", "X, back on the list", "X, moved", "A, now B", "<list>, cleared" | Core |
| R9 | `TesseraCore/Sources/TesseraCore/Processes/ProcessActions.swift:54, 85, 187, 189` | "Started X", "Saved your place", "Finished X", "Put X away" | "X, started", "<title>, paused", "X, done", "X, put away" | Core |
| R10 | `TesseraCore/Sources/TesseraCore/Kitchen/Shopping.swift:70` | "Finished shopping" | "Shopping, done" | Core |
| R11 | `TesseraCore/Sources/TesseraCore/Actions/TrainingActions.swift:90, 149-150` | "Logged bench 82.5 × 7", "Changed the set to 85 × 5" | "Bench, 82.5 × 7 logged", "Set 2, now 85 × 5" (the receipt in `WorkoutSession+Edit.swift:42` already reads this way) | Core |
| R12 | `TesseraCore/Sources/TesseraIntents/Intents.swift:114` | Siri says "Finished. 3 of 5 exercises." | "\(workout.title), done. 3 of 5 exercises." | Core |

The summaries in R8 to R11 matter because they reach his screen in two ways: as Tess's line when Claude's own line fails the voice check (R7), and as Siri's dialog (`Intents.swift:31, 51, 132`).

## Digits in heroes
| # | Where | Now | Fix | Owner |
|---|---|---|---|---|
| D1 | `Features/Home/NowPage.swift:162-163` | The context above a timed block reads "now, until twenty to four" or "next, at half past five". | "now, until 3:40 pm" and "next, at 5:30 pm", using `HomeLines.shortTime`. The prefix checks in `HomeDataTests.swift:87, 90` still hold. This replaces the spelled-out times in Design's older ink-line study (`day-seams.md` S8), which came before his Oct 15 call for digits. | Builder B |

## " · " on Home and the tab pages
The rule comes from sheet 41 §3 and the 47 addendum: no separators inside Home's lines, except the recipe line's pack size. This audit applies it to Home and the tab pages in the rail. Pages one tap down keep the dots their sheets drew, so they don't need changing:
- the Claude key line and the receipts in `claude-settings.md` and `settings-place.md`;
- TEST · REPLACE · REMOVE;
- Routines' days line;
- the Notes link line.

| # | Where | Now | Fix | Owner |
|---|---|---|---|---|
| S1 | `Features/Home/NowPage.swift:119` | "HOLD · 24 MIN LEFT" | Two label words, "HOLD" and "24 MIN LEFT", spaced like FINISH and HOLD. This replaces `home-labels.md:19`'s "HOLD · 30 MIN LEFT". | Builder B |
| S2 | `Features/Home/HomeSpatialView.swift:395` | The foot line "The week · Notes" | The words alone, 22 pt apart like the label words, with no dot. | Builder B |
| S3 | `Features/Home/TrainingPage.swift:652` | "4 × 8 · 82.5" | "4 × 8 at 82.5" | Builder A |

## No "…"
| # | Where | Now | Fix | Owner |
|---|---|---|---|---|
| E1 | `TesseraCore/Sources/TesseraTess/RecipeLinkReader.swift:22` | "Reading nytimes.com…" | "Reading nytimes.com." This replaces `kitchen/kitchen-v2.md:30`; the dabs pulsing already say she's at it. | Core |
| E2 | `TesseraCore/Sources/TesseraCore/Notes/Notes.swift:124` and `Features/Notes/NoteEditor.swift:186` | A note title is cut at 59 characters plus "…". | Cut at the last whole word at or before 60 characters, with no glyph. The row wraps. | Core (Notes.swift), Builder B (NoteEditor) |
| E3 | `Features/Objects/ObjectPage.swift:314` | A long lineage shows "… / parent / parent". | Show every step. `FlowLayout` already wraps. | Core |

## Stock UI on a live page
| # | Where | Now | Fix | Owner |
|---|---|---|---|---|
| X1 | `Features/Workout/WorkoutParts.swift:57` | A system context menu with an SF Symbol, "Swap within the movement", on the live exercise name. | Open the `SwapPanel` the page already has, with no menu and no symbol. Live things own their surface. | Builder A |

## From #366's clip (lands with #366)
| # | Where | Now | Fix | Owner |
|---|---|---|---|---|
| H1 | HomeLines, a paused workout | Context "now" (clip 0:18) | "paused" | Core |
| H2 | HomeLines, a running flight | Context "5:45 pm" reads like a time that has passed. | "since 5:45 pm" | Core |
| H3 | `Features/Workout/WorkoutFinishView.swift:70` | "It drops into today on Home.", but after FINISH HERE, Home shows no trace of Push Day A because the flight takes the hero. | Either Home shows it (the Day strip or a done line), or the line names where it really goes. | Builder B |
