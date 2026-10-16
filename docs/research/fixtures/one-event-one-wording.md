# One event, one wording (board item 125)

For: Core (`HomeLines`, `DayStory`, `WeekFacts`, `WorkoutSummary`), Design (41, 44, 46, 54, 36, 14), Builder A (widgets, Lock Screen), Builder B (Home, Review, Day log). Owner: Research lab.
Date: Oct 16, 2026 (Pacific). Traced by hand on master e9bfef0, not run (no Swift toolchain here). Design words are from `origin/claude/project-thread-b3tu3f`; the no-repeat rule in `docs/ai/home-lines.md` §2 is on `origin/claude/project-thread-he8k25` (e99dcd8, 4904320) and is not on master yet.

**What is built on master, in short.**
- **Home** draws its own strings (`NowPage.swift`). The `HomeLines` lens exists but nothing in `Features/` reads it, so lens words are marked "lens, not on screen".
- **Day log**: `DayStory` writes the lines, but there is no `Features/DayLog/` page. The lines only show inside Review (THE WEEK'S LINES and the day read).
- **Widgets**: the extension holds only `RestLiveActivity`. There are no Home Screen widgets and no Lock Screen accessories. `HomeLines.widgetLine` does not exist.
- **Review**: `ReviewPage.swift` and `ReviewWeek.swift` draw the bands. The rules week lines (item 120) are not built.
- **Habits, weigh-ins, the "rest today" mark**: there are no classes or actions for them on master, so every surface for them is "not built".

**The day used.** Pacific time, his 4 AM day. Push A on Thu Oct 15 runs 18:10 to 19:40: 6 of 6 exercises, 22 sets, Bench 85 × 8 is a best. He checks off "Call mom" at 11:20. Tacos are planned for 18:30 with 2 to buy. He weighs in at 78.1 kg at 07:05, logs Read for the week's 4th time (target 5), cooks chili from 18:00 to 18:40, and notes "hotel ideas" at 21:15. Sun Oct 18 is a planned rest day with Pull A next. Wed Oct 14 had Push A planned (rolling) and nothing logged.

Source tags: **code** (file), **lens** (`HomeLines`, not on screen), **D-n** (Design sheet item n, not built unless marked), **R** (Research or Product text).

## 1. Each event, surface by surface

### E1. A set (Bench set 3 logged at 18:30; set 4 is next)
| Surface | Words today | Source | One wording |
|---|---|---|---|
| Home context / hero / meta | "running now, Push A" / "Bench Press, set 4 of 5" / "SET 4 / IS UP" | code `NowPage.swift:473, 506, 512` | "now" / "Push A, bench set 4" / "SET 4 / IS UP" |
| Home, lens | "now" / "Push A, bench set 4" / "3 exercises, 11 sets." (fixed: Claude never rewords) | lens | as lens |
| Tess receipt, undo | "Set 3 logged. 82.5 × 8." then "Set 3 taken back." | R `tess-voice.md` M33, M34; Siri undo in code `Intents.swift:76` | same |
| Day log | "18:10 Push A, 11 sets" (running form) | code `DayStory.swift` | same |
| Widget | "Push A, bench set 4." + Resume | D-54, not built | "Push A, bench set 4." |
| Lock Screen | Live Activity: "Rest, then set 4", "Bench", "82.5 × 8" (code `RestLiveActivity.swift:144`); accessory "Push A, bench set 4." / circular "Set 4" (D-54, not built) | code, D-54 | same |
| Review | nothing until the workout ends | code | same |

### E2. A finished workout (Push A, done 19:40, Bench best)
| Surface | Words today | Source | One wording |
|---|---|---|---|
| Home context / hero / line | "trained this evening" / "Push A" / "6 of 6 exercises, 22 sets, 1 record." After 22:00: "trained this night" | code `NowPage.swift:361, 377`; `WorkoutSummary.swift:30`; `SpokenTime.partOfDay` | "done at 7:40 pm" / "Push A done" / SO FAR "6 exercises, 22 sets, 1 new best." |
| Home, lens | row "Push A done. Bench record." / hero "Push A done" / ctx "done at 7:40 pm" / SO FAR "6 exercises, 22 sets, 1 new best." | lens | row "Push A done. Bench best." |
| Day log | "18:10 Push A, 90 min. Bench 85 × 8, PR." VoiceOver: "6:10 pm, Push A, 90 minutes. Bench 85 by 8, PR." | code `DayStory.swift`, `DayLine.spoken` | Product call (W2): ", a best." or keep ", PR." |
| Widget | "Push A done, a bench best." or "Push A done." + meta "7:40 PM" | D-54, not built | rules: "Push A done." + "7:40 PM"; "a bench best" only from Claude |
| Lock Screen | rect "Push A done, a bench best." / "7:40 pm"; circular "Done"; 60 s face "Push A, all sets in." / "ready to finish" | D-54, D-36 addendum, not built | as widget; 60 s face as D-36 |
| Siri finish | "Finished. 6 of 6 exercises." | code `Intents.swift:114` | "Push A done." |
| Review hero / band | "One session" (count) / TRAINING "1 of 6" | code `ReviewWeek.swift:72-78, 100` | hero as code; band "1 SO FAR" mid-week (D-46 addendum) |
| Review week line | "Thu  Push A, 90 min. Bench 85 × 8, PR." (Core's pick, Day log text) | code `WeekFacts.bestLines` | "Thu  Bench 85 × 8, a best." (D-46) |
| Review day read hero | "Push best" (bug, W3); fallback "Push A done, Bench Press best." | code `ReviewWeek.swift:120, 175` | "Bench best" (D-46) |
| Review rules line | "1 of 6 workouts, 1 new best." | R item 120, not built | same |

### E3. A task done ("Call mom", 11:20)
| Surface | Words today | Source | One wording |
|---|---|---|---|
| Home, Tess receipt | "Call mom, done." or, when another task follows, "Done. Next one is up." | code `NowPage.swift:196`, `HomeQueue.swift:452` | "Call mom done." then UNDO "Call mom taken back." |
| Home, Design | "Done. Call the dentist." (swipe); "Done. Next one is up." (hold) | D `today-on-home.md`, `home-v1.md` | "Call the dentist done." |
| Day log | "11:20 Done: Call mom"; 3 or more: "5 tasks done" | code `DayStory.swift` | same |
| Widget | the task leaves; no done state drawn | D-54 | none |
| Lock Screen | N1 return line "Call mom done." | D-36, not built | same |
| Review | TASKS DONE numeral "1", "·" for none; day read "1 done"; VoiceOver "Tasks done, 1. Thursday 1." | code `ReviewWeek.swift:173, 219` | same |

### E4. A planned meal (tacos at 18:30, 2 to buy, read at 09:00)
| Surface | Words today | Source | One wording |
|---|---|---|---|
| Home, app | the task's own title as a Next row with "18:30"; as Now: "next, at half past six" over "cook tacos" | code `HomeQueue.swift`, `NowPage.swift:163` | Now context "next, at 6:30 pm" |
| Home, lens | hero "Tacos today" / ctx "2 to buy" / row "Tacos today, 2 to buy." ("tonight" only after 17:00) | lens | hero "Tacos tonight" / ctx "2 to buy" |
| Tess, planning | "Added 2 for tacos." | R decisions 12:54 AM | same |
| Day log | "09:00 Added 1 task, 2 groceries" | code `DayStory.swift` | same |
| Widget | "Tacos tonight, 2 to buy." + Groceries | D-54, not built | same |
| Lock Screen | no accessory row drawn; N1 if timed ("cook tacos" / "It's 6:30 pm.") | D-54 (gap), D-36 | "Tacos tonight, 2 to buy." |
| Review | nothing | code | nothing |

### E5. A weigh-in (78.1 kg, 07:05)
| Surface | Words today | Source | One wording |
|---|---|---|---|
| Home | never (the Home pack holds no body figures) | R `home-lines.md` §2a | never |
| Tess receipt | "Body weight logged. 78.1 kg." | R decisions 7:34 PM, not built | same |
| Day log | no line form exists | R `day-log-copy.md` (gap) | "07:05 Body weight, 78.1 kg" (Design to confirm) |
| Widget, Lock Screen | never ("Health saves" is on the Never list) | D-54, D-36 | never |
| Review | band "WEIGHT, 78.1 KG"; clause "weight down 0.2 kg" from 3 weigh-ins | D-46, D-15, not built | same |

### E6. A habit (Read, 4th of 5 this week)
| Surface | Words today | Source | One wording |
|---|---|---|---|
| Home | nothing (no habit fact in `HomeFact.Kind`) | code | nothing |
| Tess receipt | "Read, 4 of 5 this week."; at 5: "Read done for the week." | R decisions 9:04 PM, D-15, not built | same |
| Day log | no line form for a check-in (a note "read 20 pages" shows as "Note: read 20 pages") | R `day-log-copy.md` (gap) | "Ticked Read" (Design to confirm) |
| Widget, Lock Screen | nothing drawn | D-54, D-36 | nothing |
| Review | band "READ · 4 OF 5" | D-46, D-15, not built | "READ · 4 OF 5" (W27) |

### E7. A rest day (Sun Oct 18, planned, Pull A next)
| Surface | Words today | Source | One wording |
|---|---|---|---|
| Home context / hero / line | "today" / "Rest day" / "Pull A is a tap away." + "Start Pull A" | code `NowPage.swift:396-410` | same |
| Home, lens | ctx "Sunday" / hero "Rest day" / row "Rest day." | lens on master | ctx "today" (he8k25 rule) |
| Home, "rest today" said | hero "Rest today" / ctx "Legs A waits for tomorrow" (fixed: "waits for Thursday") / UNDO "Legs A, back on today." | D-44 addendum, decisions 2:53 AM, not built | same |
| Day log | "Rest day" first, no time | code `DayStory.swift` (plan only) | same, and for a "rest today" mark too |
| Widget | "Rest day." + Pull A, no meta | D-54, not built | "Rest day." + meta "SUNDAY" (he8k25) |
| Lock Screen | "Rest day." / circular "Rest" / inline "Rest day" | D-54, not built | same |
| Review | rest stroke; VoiceOver "Sunday rest"; day read "Rest day"; Training eve label "Rest day tomorrow" | code `ReviewWeek.swift:185, 205`, `TrainingPage.swift:254` | same |

### E8. A missed day (Wed Oct 14, Push A planned, nothing logged; read Thursday)
| Surface | Words today | Source | One wording |
|---|---|---|---|
| Home Thursday | "today's training" / "Push A" / "6 EXERCISES / 22 SETS" | code `NowPage.swift:428-454` | "today" (or "this evening") / "Push A" |
| Home, lens | ctx "today" / hero "Push A" | lens | same |
| Day log | "WED 14" label at 45%, no lines | D-14 (page not built); code returns no lines | same |
| Widget, Lock Screen | nothing about Wednesday; Thursday reads "Push A today." | D-54, D-36 Never list | same |
| Review | faint ring; VoiceOver "Wednesday open"; day read "A quiet day"; figure "1 of 6" | code `ReviewWeek.swift:187, 206, 100` | VoiceOver "Wednesday, nothing logged"; day read "Nothing logged"; figure "1 SO FAR" |
| Review rules line | "5 of 6 workouts." (Sunday) | R item 120, not built | same |

### E9. A recipe cooked (chili, 18:00 to 18:40)
| Surface | Words today | Source | One wording |
|---|---|---|---|
| Home | the cook leaves Home at once (no done-cook fact, G1); Tess "Chili, done."; op summary "Cooked Chili" | code `HomeLines.swift`, `TessCaptureEngine.swift:367`, `Cooking.swift:256` | hero "Chili done" / ctx "at 6:40 pm"; receipt "Chili cooked." |
| Day log | "18:00 Cooked Chili, 40 min" | code `DayStory.swift` | same |
| Widget, Lock Screen | cook Live Activity ends; no done state drawn | D-36, D-54 | none |
| Review band | "Cooked" with figure "1"; VoiceOver "Cooked, 1. Thursday." | code `ReviewPage.swift:290`, `ReviewWeek.swift:224` | "COOKED, 1"; line "cooked 1 time" (D-46 addendum) |
| Review rules line | "1 recipe cooked." (counts distinct titles) | R item 120, not built | "cooked 1 time" |

### E10. A note ("hotel ideas", 21:15)
| Surface | Words today | Source | One wording |
|---|---|---|---|
| Home | Tess "Noted." / "Noted, linked." / "Noted for Saturday."; never in the Home pack | code `TessCaptureEngine.swift:299, 308` | same |
| Day log | "21:15 Note: hotel ideas"; 2 or more: "2 notes"; tail "3 notes" | code `DayStory.swift` | same |
| Widget, Lock Screen | never | D-54, D-36 | never |
| Review | can surface as a week line "Thu  Note: hotel ideas" (rank 3 in `bestLines`) | code `WeekFacts.swift` | never a week line (W24) |

## 2. Every difference

| # | Event | Surfaces that disagree | The words | Right per the sources | Owner |
|---|---|---|---|---|---|
| W1 | E2 | Home line, lens row vs lens SO FAR, D-54 | "1 record." (`WorkoutSummary.line`), "Bench record.", "2 records." vs "1 new best", "a bench best" | "best" (house rule; G3) | Core |
| W2 | E2 | Day log vs D-46 week lines | ", PR." vs ", a best." | Conflict: Product 12:17 AM keeps ", PR" on history; the house rule and D-46 say "best". Product to rule; default "a best" | Product, Core |
| W3 | E2 | Review day read vs D-46 | "Push best" (takes the first word of "Push A, 90 min. Bench 85 × 8, PR."); fallback "Bench Press best" | "Bench best" (short name) | Builder B |
| W4 | E2 | Home app vs lens | "trained this evening" / "Push A" / "6 of 6 exercises, 22 sets, 1 record." vs "done at 7:40 pm" / "Push A done" / "6 exercises, 22 sets, 1 new best." | lens (`home-lines.md`; Kaushik 11:58 PM: one line, detail one tap down) | Builder B |
| W5 | E2 | Home app vs lens | "trained this night" after 22:00 vs "tonight" | "tonight" | Builder B |
| W6 | E2 | D-54 widget vs lens | "Push A done, a bench best." needs a context the rules never write | rules widget: "Push A done." + "7:40 PM"; the best rides only on a checked Claude line | Core (`widgetLine`), Design |
| W7 | E2 | `home-lines.md` §2 table vs its own no-repeat rule | ctx "done at 7:40 pm" under "Push A done"; "paused 21 min ago" under "Push A, paused at bench" | the rule bans "done" and "paused" in the context; D-54 already drops it. Propose "at 7:40 pm", "21 min ago" | Core, Design |
| W8 | E1 | Home app vs lens and D-54 | "running now, Push A" / "Bench Press, set 4 of 5" vs "now" / "Push A, bench set 4" | lens | Builder B |
| W9 | E2 | Live Activity 60 s face: D-10 vs D-36 vs lens | "All 22 sets in." vs "Push A, all sets in." vs lens "Push A, under way." (G5) | "Push A, all sets in." | Builder A, Core |
| W10 | E2 | Siri finish vs D-10 vs D-54 | "Finished. 6 of 6 exercises." vs "Finished. " + summary line vs no counts | "Push A done." | Builder A |
| W11 | E3 | Home code vs tess-voice and D-36 vs Design Home | "Call mom, done." vs "Call mom done." vs "Done. Call the dentist." | "Call mom done." (M33, M55) | Builder B, Design |
| W12 | E3 | Home hold-finish | "Done. Next one is up." names nothing | "Call mom done." (undo names the thing) | Builder B, Design |
| W13 | E4 | Now context vs house rule and lens | "next, at half past six", "now, until twenty to four" vs "6:30 pm"; D-54 "Call landlord at six." | digits: "next, at 6:30 pm", "Call landlord at 6 pm." | Builder B, Builder A, Design |
| W14 | E4 | lens vs D-54, `home-lines.md`, decisions 12:17 AM | "Tacos today" before 17:00 vs "Tacos tonight" | "tonight" from the task's due time (G8) | Core |
| W15 | E4 | D-54 Lock Screen table | no planned-cook row; widget has one | add "Tacos tonight, 2 to buy." | Design |
| W16 | E8 | Home app vs lens | "today's training" vs "today" / "this evening" | lens | Builder B |
| W17 | E7 | lens on master vs app and he8k25 | ctx "Sunday" under the day label "Sunday morning" vs "today" | "today" (no-repeat rule; merge he8k25, then the lens) | Core |
| W18 | E7 | D-54 vs `home-lines.md` (4904320) | widget "Rest day." with no meta vs weekday kept as meta | meta "SUNDAY": a widget has no day label | Design, Builder A |
| W19 | E7 | "rest today" mark vs Day log | the hero says "Rest today" but `DayStory` takes `isRestDay` from the plan only, so the Day log shows no "Rest day" row | the Day log shows "Rest day" for a marked day too (WeekFacts counts it as rest) | Core |
| W20 | E8 | Review day read and VoiceOver vs Day log | "A quiet day", "Wednesday open" vs "nothing logged" | "Nothing logged" (plain, no grading) | Builder B, Design |
| W21 | E2, E8 | Review figure vs D-46 addendum vs item 120 | "1 of 6" all week vs "1 SO FAR" until the week is whole vs "3 of 6 workouts." mid-week | "N SO FAR", then "N OF 6" | Builder B |
| W22 | E9 | Review band vs D-46 addendum vs item 120 | "Cooked 1" vs "cooked 3 times" vs "1 recipe cooked." (chili twice is still "1 recipe") | "cooked N times" (counts cooks; R3) | Core, Design |
| W23 | E9 | Tess vs op summary vs Day log | "Chili, done." vs "Cooked Chili" vs "Cooked Chili, 40 min" | receipt "Chili cooked."; Day log keeps its form | Core |
| W24 | E9 | Home: workout vs cook | a done workout stays until 04:00; a done cook vanishes | done-cook fact: "Chili done", "at 6:40 pm" (G1) | Core |
| W25 | E10 | Review week lines vs `WeekFacts` doc and D-46 | `bestLines` can pick "Note: hotel ideas" (also "Done: Call mom") | lines are "a best, a first, a record count"; never a note | Core |
| W26 | E5 | Day log vs every other surface | a weigh-in has a receipt and a band, but no Day log line | "Body weight, 78.1 kg" | Design, Core |
| W27 | E6 | Day log; Review figure | no check-in line; "READ · 4 OF 5" vs the D-46 addendum "SO FAR" rule | "Ticked Read"; habits keep "of 5" (target, decisions 7:34 PM); Design to say that "SO FAR" is training only | Design, Core |
| W28 | E2 | lens SO FAR | "0 exercises, 0 sets.", "1 exercise, 0 sets." | no SO FAR while sets are 0 (G4) | Core |

## 3. What matters most

1. **"best" vs "record" (W1, W2, W3).** A Bench best reads four ways on one evening: "1 record", "Bench record", ", PR." and "Push best". Core's `WorkoutSummary.line` and the lens row are a two-word fix. W2 needs Product's ruling.
2. **Home doesn't speak the lens (W4, W5, W8, W16).** Every Home string differs from `HomeLines`. Builder B's AI-1 wiring closes four rows at once.
3. **Task receipts (W11, W12).** There are three shapes now. Use "Call mom done." everywhere.

Everything else waits on surfaces that are not built yet (widgets, Lock Screen accessories, habits, weigh-ins, the Day log page, the rules week lines). Build them from the "One wording" column so they agree from day one.
