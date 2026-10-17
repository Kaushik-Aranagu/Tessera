# One event, one wording on master: a check against 125 and 126 (board item 143)

For: Core, Builder A, Builder B, QA. Owner: Research lab. Date: Oct 16, 2026 (Pacific).
Master `fed2a0e` (#431). Traced by hand, nothing was run. Sheets read from Design's `copy-pass.md` (item 62) on `claude/project-thread-b3tu3f`. QA's reviews of #352, #366, #369 and #381 are not redone here.

**The one fact that changes the picture: #366 (AI-1 Home lines) is still open, not merged.** QA passed its re-check (d9d4de5), but on master `NowPage.swift` still draws its own strings and nothing in `Features/` reads `HomeLines`. #369 (the lens), #352 (Review week) and #381 (live workout) are merged. So every Home row below is still split until #366 lands.

Product rules used: "best", never "record" or "PR"; receipts thing first ("Call mom, done.", "Tacos, 2 added."); digits and lower-case "pm"; heroes keep a bare hour ("Push A at 6"); Settings in the third person.

## 1. W1 to W28 on master
| W | Event | Expected wording | Agree / disagree (file:line) | Verdict |
|---|---|---|---|---|
| W1 | Finished workout | "1 best", "Bench best." | Agree: `WorkoutSummary.swift:33`, `HomeLines.swift:248, 365` | ✓ |
| W2 | Day log best | ", a best." | Disagree: `DayStory.swift:225` ", PR" (Product's rule now settles it for "best") | still split |
| W3 | Review day read | "Bench best" | Disagree: `ReviewWeek.swift:175` takes the first word of the ", PR." line, so "Push best" | still split |
| W4 | Done workout on Home | "Push A done" / "7:40 pm" | Lens agrees; app disagrees: `NowPage.swift:361, 377` ("trained this evening", "6 of 6 exercises, 22 sets, 1 best.") | still split (#366) |
| W5 | After 22:00 | "tonight" | `NowPage.swift:361` "trained this night" via `SpokenTime.partOfDay` | still split (#366) |
| W6 | Widget, done | lens `widgetLine` | Core settled "Push A done. Bench best." (`HomeLines.swift:129`); no widget built | ✓ (lens) |
| W7 | Context repeats hero | "7:40 pm" alone | Agree: `HomeLines.swift:329`, `widgetMeta` drops "paused"/"done" (:145) | ✓ |
| W8 | A set on Home | "Push A, bench set 4" | Lens agrees (:287); app `NowPage.swift:473` "running now, Push A" | still split (#366) |
| W9 | All sets in, 60 s face | "Push A, all sets in." | Lens agrees (:253, 289); Live Activity face not built | still split (not built) |
| W10 | Siri finish | "Push A done." | `Intents.swift:114` "Finished. 6 of 6 exercises." | still split |
| W11 | Task done | "Call mom, done." (Product) | Agree: `NowPage.swift:196`, `HomeQueue.swift:452` | ✓ |
| W12 | Hold-finish, next task | names the thing | `NowPage.swift:196` "Done. Next one is up." | still split |
| W13 | Timed task context | "next, at 6:30 pm" | `NowPage.swift:162-163` "half past six" | still split (#366) |
| W14 | Planned cook | "Tacos at 7" / "Tacos tonight" | Agree: `HomeLines.swift:267-276` | ✓ |
| W15 | Lock Screen cook row | "Tacos tonight, 2 to buy." | Not in `lockscreen.md`; nothing built | still split (Design) |
| W16 | Planned workout context | "today" | `NowPage.swift:428` "today's training" | still split (#366) |
| W17 | Rest day context | "today" | Agree: `HomeLines.swift:327` | ✓ |
| W18 | Rest widget meta | weekday | Agree: `HomeLines.swift:142-143` | ✓ |
| W19 | "Rest today" mark in Day log | "Rest day" row | Mark not built; `DayStory.swift:391` takes the plan only | still split (not built) |
| W20 | Missed day | "Nothing logged" | `ReviewWeek.swift:187` "A quiet day", `:206` "Wednesday open" | still split |
| W21 | Review figure mid-week | "1 SO FAR" | `ReviewWeek.swift:100` "1 of 6", `:210` VoiceOver | still split |
| W22 | Cooked count | "cooked N times" | Band counts cooks (`ReviewPage.swift:290`); VoiceOver counts days (`ReviewWeek.swift:224`) | still split |
| W23 | Cook receipt | "Chili, done." | Tess agrees (`TessCaptureEngine.swift:372`); op summary `Cooking.swift:256` "Cooked Chili" | still split |
| W24 | Done cook on Home | "Chili done" | Lens agrees (`HomeLines.swift:301`); app waits on #366 | ✓ (lens) |
| W25 | Week lines | never a note | `WeekFacts.swift:167-184` ranks notes and "Done:" lines 3, so they can still fill a slot | still split |
| W26 | Weigh-in | "Body weight, 78.1 kg" | No class on master | still split (not built) |
| W27 | Habit | "Ticked Read" / "READ, 4 OF 5" | No class on master | still split (not built) |
| W28 | SO FAR at 0 sets | no line | Agree: `HomeLines.swift:245` (QA #369) | ✓ |

**Count: 9 ✓, 19 still split (5 wait on #366, 5 on surfaces not built yet), 0 regressed.**

## 2. Research 126's 43 fixes
Design's copy pass took all 43 into the sheets, except "Pull A tomorrow, first." which Design kept (Core #369 built it so).
| Status on master | Count | Fixes |
|---|---|---|
| Landed (code or sheet prose) | 7 | 1, 8, 13 (`Groceries.swift:362`), 14, 22 (`TessMemory.swift:302`), 28, 42 |
| Closed by Design's ruling | 1 | 39 |
| Not built yet (build from the copy pass "Now" column) | 24 | 2, 7, 10-12, 15, 18, 19, 21, 23-25, 29-38, 40, 43 |
| Still open in code | 11 | below |

| Fix | Code now (file:line) | Owner |
|---|---|---|
| 3 | " · " in the routine row: `Plans/RoutinesPage.swift:346` | Builder A |
| 4 | "Thursday was Pull A's. Push A has it now.": `PlanEditing.swift:191`, shown by `RoutineEditor.swift:522` | Core, Builder A |
| 5 | "the week so far": `Home/ReviewPage.swift:237` (and `Review/ReviewView.swift:159`) | Builder B |
| 6 | "·" for an empty day: `Home/ReviewWeek.swift:311` | Builder B |
| 9 | VoiceOver "Training, 3 of 6": `ReviewWeek.swift:210` | Builder B |
| 16 | "Kept. You rest on Sundays.": `TessMemory.swift:266` | Core |
| 17 | "Everything forgotten, 12 things.": `TessMemory.swift:324` | Core |
| 20 | "Forget one and say it again.": `TessMemory.swift:38` | Core |
| 26, 27 | "Tess asks Claude when she's unsure, and for Plan my day.": `Settings/ClaudeSection.swift:286` | Builder B |
| 41 | "Drag right +15 · Fling left to go": `Workout/Instruments/RestHorizon.swift:60` | Builder A |

## 3. Grep sweep of user-facing strings
| Hit | File:line | Owner |
|---|---|---|
| ", PR" in Day log lines (also read aloud as "PR") | `DayStory.swift:225` | Core |
| "Push best" built from the ", PR." line | `ReviewWeek.swift:175` | Builder B |
| Field name "Record" on the set class (shown on object pages) | `SystemCatalog.swift:162` | Core |
| Stale doc comment "Bench record." | `HomeLines.swift:91` | Core |
| Em-dash as the empty value | `Objects/ObjectPage.swift:172, 174, 401, 409`; `Workout/SwapPanel.swift:102`; `Exercise/ExerciseViews.swift:188`; `Exercise/ExercisePage.swift:144, 146` | Builder A (ObjectPage :401, :409 has no owner) |
| Upper-case "PM": "Ready at 6:12 PM" on the always-on face | `Widgets/RestLiveActivity.swift:243` | Builder A |
| Spelled counts in heroes: "Three sessions", "All six sessions" | `ReviewWeek.swift:75-77`, `ReviewPage.swift:41-44`, `Review/ReviewView.swift:109` | Builder B |
| Spelled count in a context: "Thursday, three planned" | `Home/DayStrip.swift:68` | Builder B |
| Verb first: "Moved to tomorrow." / "Moved to next week." | `Home/HomeQueue.swift:473` | Builder B |
| Verb first: "Done. Next one is up." | `Home/NowPage.swift:196` | Builder B |
| Siri reads op summaries: "Logged bench press 82.5 kg × 8.", "Added “Call mom”." | `Intents.swift:31, 51, 132` from `TrainingActions.swift:91, 445` | Core (summaries), Builder A (Siri) |
| Claude's fallback receipt is the op summary: "Done: Call mom.", "Added milk.", "Cooked Chili." | `ClaudeTessModel.swift:124` from `TrainingActions.swift:481`, `Lists.swift:143`, `Cooking.swift:256` | Core |
| Day log lines "Added 1 task, 2 groceries", "Done: Call mom" | `DayStory.swift:333, 339` | Core (125 kept this form; Product to confirm) |

Clean: no "personal record", no " PRs" and no upper-case "AM"/"PM" in any hero. Settings is third person ("Tess asks Claude: yes.", `ClaudeSection.swift:160`). Not UI: `TessModelCapture.swift:151` "Done: " and `EngineAction.swift:58` go to the model only.

## 4. Unsure
- **Bare hour.** The lens hero for a planned workout is "Push A at 7 pm" (`HomeLines.swift:295`), while a cook is "Tacos at 7" (:272). Product's rule keeps the bare hour, but Design's copy pass rule 6 drops it ("Push A at 6 pm"). Product and Design need to pick one before Core changes either line.
- `NotesView.swift:263` and `ClaudeSection.swift:29` print "Oct 12" and "Nov 1" only in a US locale.
- I read #366's status from the GitHub API (open, not merged). If it merges tonight, re-check W4, W5, W8, W13, W16 and W24.

**Ruled (Product, decisions.md 11:50 AM PT Oct 16):** hero times carry "pm" ("Push A at 6 pm", "Tacos at 7 pm"), so HomeLines.swift:272 changes. The Day log keeps its own grammar ("Done: …", "Added …"); thing-first covers receipts, Siri replies and memory lines. The Review hero count stays in words ("All six sessions in", Design 12). Core has items 1, 2, 4 and 5; Builder B has "1 so far"; the other Review words go through Design's copy pass.
