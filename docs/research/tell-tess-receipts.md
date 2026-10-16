# Tell Tess receipts: no more bare "Saved." (Research lab, coordinator low item, 2:07 pm)

For: Core, Builder B, Core/P14. Owner: Research lab. Date: Oct 16, 2026 (Pacific). Read by hand and grep, nothing run.
Master `e1b856c`. The bare "Saved." is **not on master**: it lives on `origin/core/privacy-0j-v2` (`d8048c3`, P14, not merged).
Builds on `receipts-thing-first.md` (RC1 to RC36, decided 12:35 pm) and the P14 rulings (12:30 pm, 1:23 pm).

## Where a generic receipt comes from

| # | Source | Line | Reaches Tell Tess? |
|---|---|---|---|
| S1 | `core/privacy-0j-v2` `TesseraIntents/Intents.swift:199-201` | `hidden ? "Saved." : capture.line` | Yes, the only one. Fires when the phrase is private (`PrivateFacts.isPrivateTitle`), something was written, and the line is neither exactly "Private note, kept." nor starts "Task added" |
| S2 | master `Features/Backup/BackupView.swift:184` | "Saved." | No (RC5, decided "Copy, saved.") |
| S3 | master `TesseraTess/ClaudeTessModel.swift:92` | tool result "Done" | No, goes to Claude, never shown |
| S4 | master `TessModelCapture.swift:44`, `ClaudeTessModel.swift:129` | `receipt ?? summary` + "." (RC23) | Yes, but feeds S1's input, so it is the line S1 hides |
| S5 | master `ClaudeTessModel.swift:131` | "N things done." | Yes (Claude route), never on a walled phrase |

No "Got it" anywhere in Swift on master. The Day log's "Saved" (`DayStory.swift:88`) is log text, out of scope (11:50 am).

## Hidden writes that land on "Saved." today (branch `core/privacy-0j-v2`)

Capture lines are `TessCaptureEngine.swift` on that branch. Made-up phrases.

| Write kind | Phrase | Line before S1 | Proposed receipt (shown) | Siri / VoiceOver spoken | Privacy note |
|---|---|---|---|---|---|
| W1 Private note, "remember" form | "remember wifi is hunter2" | :312 "Private note, kept. I don't keep passwords." | "Private note, kept. I don't keep passwords." (unchanged) | same | A bug, not a design: S1 only lets the exact "Private note, kept." through, so this branch says "Saved." Never echo the value |
| W2 Private dated note (money, past tense with a day) | "paid rent 4417 fri" | :312 "Private note, kept." | "Private note, kept for Friday." | "Private note, kept for Friday." | Day only, never the sum. Today it passes S1 as "Private note, kept." (day lost) |
| W3 Lift plus a body fact | "bench 80x8 and knee hurts" | :274 + :312 joined | "Bench 80 × 8, logged. Private note, kept." on screen | Siri: "Set logged. Private note, kept." | The lift is not private; the note is. Siri drops numbers on any walled phrase |
| W4 Set in focus, body words in the phrase | "80 x 8 shoulder sore" (Push A open) | :293 "Set 3 logged. 80 × 8." | "Set 3 logged. 80 × 8." | Siri: "Set 3 logged." | If the grammar splits a note out, as W3 |
| W5 Groceries with a walled word | "buy advil 200mg" | :349 "Advil 200mg, on the list." | "Advil 200mg, on Groceries." | Siri: "Groceries, 1 added." | Medicine name is a body fact (W2); Siri says the list and count, not the item |
| W6 Reschedule of a private task | "move pay rent 4417 to fri" | :372 "Pay rent 4417, Friday 9 am." | same on screen | Siri: "Task moved to Friday 9 am." | Matches 12:30 pm "Task added for Fri." |
| W7 Kitchen timer with a walled label | "advil timer 240 min" | :364 "Advil, 240 min." | same on screen | Siri: "Timer, 240 min." | Label hidden, minutes fine |
| W8 New list or list item, walled name | "new list meds" | :367 "New list: meds." | "Meds, made." (RC21) | Siri: "List, made." | Title hidden |
| W9 Plain note that the wall catches | "note: slept 5 hours" | :325 "Noted." | "Note, kept." (RC18) | "Note, kept." | No value in it already; should become private at parse (flag for Core 0ac) |
| W10 On-device model write on a walled phrase | "coffee 6.25 tacocat" | `TessModelCapture.swift:44` model line or summary | Per action, as the rows above | Siri: kind line, from the action name, never the model's words | Model words may echo the sum; S1's guard is right to stop them |
| W11 Body weight (decided 1:23 pm, not built) | "82.4 this morning" | none yet | "Body weight logged. 82.4 kg." | Siri: "Body weight logged." | Siri never says the number |
| W12 Habit check-in (HW8, not built) | "meditated" | none yet | "Meditate, 2 of 3 this week." | same; with a body word, Siri: "Habit, checked in." | Only walled when the habit name is |

Not reachable from Tell Tess on master or the branch: memory facts (`rememberFact` is not in `TessTools.all`, and
"remember" plus a sum is refused with no write) and settings (`writeSettings` has no grammar or tool). When they are
wired: memory "Fact, kept on this phone only." (RC33 shape, no value); a setting "Setting, changed." with the
setting's name only when it is not private.

## Recommendation

1. Replace S1's string with a kind line, not a blanket word. Core adds `TessCapture.privateLine: String?`, built from
   the action names of what was written (never from the phrase or the model's text): logSet "Set N logged.", logExercise
   "Bench, logged.", createTask `privateTaskLine`, createNote (private) "Private note, kept." plus "for Friday" when
   dated, createNote "Note, kept.", addGroceries "Groceries, N added.", rescheduleTask "Task moved to Friday 9 am.",
   startKitchenTimer "Timer, N min.", createList "List, made.", addToList "List, 1 added.", and for two or more kinds
   "2 things, kept." Siri speaks `privateLine` when `hidden`; S1's string compare goes away (fixes W1 for free).
2. Ask bar keeps the full line (unlocked phone), with the private-note rule unchanged.
3. Spoken form: "×" read as "by" ("80 by 8"), am/pm as letters, no symbols. VoiceOver reads the shown line.
4. Ship with P14 on the next pin (rider 6, 1:56 pm); W11 and W12 take their lines when built.

## Swift Testing names

Core (engine strings, `TesseraCore/Tests`):
- `privateLineNamesTheKindNeverTheValue()`, `privateLineForDatedPrivateNoteSaysTheDay()`
- `privateLineForGroceriesCountsWithoutItems()`, `privateLineForMovedTaskSaysDayAndTime12Hour()`
- `privateLineForTwoKindsSaysTwoThingsKept()`, `privateLineIgnoresModelText()`
- `rememberPasswordLineKeepsPrivateNoteWording()`

Builder B (ask slot, `TesseraTests`):
- `askSlotShowsThingFirstLineForWalledLift()`, `askSlotVoiceOverReadsPrivateNoteWithoutValue()`
- `askSlotNeverShowsBareSaved()`

Core/P14 (Siri, `TellTessIntent`):
- `tellTessNeverSaysBareSaved()`, `tellTessRememberPasswordSaysPrivateNoteKept()`
- `tellTessWalledLiftDropsNumbers()`, `tellTessBodyWeightSaysLoggedWithoutNumber()`
- `tellTessMovedPrivateTaskSaysDayNotTitle()`, `tellTessModelEchoOfSumIsReplacedByKindLine()`
