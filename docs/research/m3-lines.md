# M3 lines: body weight and habits, every Tess line and empty state

For: Core, Builder A (body weight), Builder B (habits), Design (copy). Board item 69. 2026-10-16. Research lab.
Inputs: Design `docs/design/body-weight-and-habits.md` (branch `claude/project-thread-b3tu3f`, same as the shared copy),
`m3-1-2-brief.md`, `body-weight-trend.md`, `habits.md`, `tess-voice.md` (M33 to M36), `undo-lines.md`,
`empty-states.md`, `settings-claude.md`, `../product/decisions.md` (5:14, 6:37, 7:24 PM PT). Master `eeec18c` has no
body weight or habit code; `AppClock.mass` formats "82.5 kg" and `WeightDial` speaks "82.5 kilograms".

Rules used: name it, then what happened, then one number; under 12 words; digits; the unit once per line; no "!";
none of should, must, missed, streak, great, best, only, lost, gained, down, up, good, bad. UNDO is 4 s, 10 s for a
destructive write (a delete, or replacing a value). Undo of a write says "{name} taken back."; undo of a removal says
"{name} is back." (6:37 PM PT). Times and dates follow master: "Tuesday 6:20 pm", "Sep 3". Fixture values from the brief.
"D" marks a line that differs from Design's sheet; the reason is in the last section.

## 1. Body weight: how many points each part needs

| Part | Shows from | Before that |
|---|---|---|
| Hero numeral (the trend) | 1 entry (the seed is the first weight) | the empty state, B1 |
| The stroke | 2 days with entries | one sage dab above TODAY, no stroke |
| Change line | 2 days with entries | B3 |
| Weekly rate (context line) | 7 days after the first entry, and an entry in the last 7 days | left out of the context line |
| "N above trend" note | 1 earlier day (a trend to compare with) | never on the first weigh-in |

## 2. Body weight page lines

| # | State | Exact copy |
|---|---|---|
| B1 | No entries (empty) | Context line "No weigh-ins yet." No hero, no TREND label, no stroke. Writing placeholder "bw 78.4". Tess says nothing |
| B2 | One entry | Context "78.1 this morning". Hero "78.1" kg. One dab, TODAY under it |
| B3 | Change line, one entry | "The trend starts here." |
| B4 | Context, entry today | "{w} this morning" before 12:00, "{w} today" to 22:00, "{w} tonight" after |
| B5 | Context, entry yesterday | "78.1 yesterday" |
| B6 | Context, 2 to 6 days ago | "78.1 on Tuesday" |
| B7 | Context, 7 days or more (a gap) | "78.1 on Oct 5". The rate is left out. No day count, no Tess line: the stroke simply has no dabs there |
| B8 | Rate, trend lower | "78.1 yesterday, 0.3 kg less than last week" |
| B9 | Rate, trend higher | "78.1 yesterday, 0.3 kg more than last week" |
| B10 | Rate, under 0.1 kg either way | "78.1 yesterday, about the same as last week" |
| B11 | Change line, lower | "1.2 kg less since Sep 3" (D3) |
| B12 | Change line, higher | "0.8 kg more since Sep 3" (D3) |
| B13 | Change line, rounds to 0.0 | "The same as on Sep 3" (D3) |
| B14 | Gap over 30 days (reseed) | The stroke breaks at the gap. Change line and rate count from the reseed day: "The trend starts again here." until a second day |
| B15 | Outlier dab label | "87.4" in labels beside the pinned dab. Never red |
| B16 | Axis labels | "SEP 3" left, "TODAY" right |

## 3. Body weight Tess lines

| # | Moment | Tess says | UNDO, then |
|---|---|---|---|
| T1 | "82.4" idle (30 to 250 kg): the ghost that waits | Ghost "Body weight **82.4** kg?" Tess "Tap to keep it." | none (nothing written) |
| T2 | Ghost note, more than 3 kg off trend | "4.2 KG ABOVE TREND" or "3.4 KG BELOW TREND" in labels | |
| T3 | Ghost kept (tap) | "Body weight logged. 82.4 kg." (D1) | 4 s: "Body weight taken back." |
| T4 | Kept, more than 3 kg off | "Body weight logged. 82.4 kg, 4.2 above trend." (D1, D2) | same |
| T5 | Ghost swiped away | nothing | |
| T6 | "weighed 82.4", "82.4 kg", "bw 82.4" (commit after 2 s) | as T3 or T4 | same |
| T7 | First weigh-in ever | "Body weight logged. 78.1 kg, the trend starts here." | 4 s: "Body weight taken back." (back to B1) |
| T8 | Second weigh-in ever | "Body weight logged. 78.3 kg, trend 78.1." (once, so he learns the big number is the trend) | as T3 |
| T9 | Second entry the same day (replaces) | "Body weight now 78.5 kg." | 10 s: "Body weight taken back, 78.9 kg again." |
| T10 | First entry after a gap over 30 days | "Body weight logged. 80.2 kg, the trend starts again." | as T3 |
| T11 | Fix a past entry (dial on its dab) | "Sep 16 body weight now 78.4 kg." | 10 s: "Sep 16 body weight taken back, 87.4 kg again." |
| T12 | Delete a past entry | "Sep 16 body weight deleted." | 10 s: "Sep 16 body weight is back." |
| T13 | "bw 82.4" in a workout | as T3 (Body weight only binds mid-workout with "bw") | as T3 |
| T14 | "82.4" or "82.4 kg" in a workout | set ghost "82.4 × 8"; on commit the set line "Set 4 logged. 82.4 × 8." (see D12) | the set's own |
| T15 | "bw trend" | opens the page; nothing said | |
| T16 | Number outside 30 to 250, idle | not body weight; goes to the model like any other line | |

Unit: kg is the only unit in M3 (ship list). If `AppClock.unit` is lb, every line swaps "kg" for "lb" with the value
converted to one decimal ("Body weight logged. 181.7 lb."), and the bare-number range becomes 66 to 550 (D11).

## 4. Habits page lines

| # | State | Exact copy |
|---|---|---|
| H1 | No habits (empty) | Hero "This week", context as H2, then one line "No habits yet." Writing placeholder "new habit read 5 a week". The Today foot word "Habits" still shows |
| H2 | Context line | Mon "Monday, a new week"; Tue to Sat "Thursday, 3 days to go" (D5); Sun "Sunday, the last day" |
| H3 | Count | "**2** of 5" (the target, never 7). Paused: "paused" |
| H4 | Count, target passed | "**6** of 5", nothing else. No "+1" badge, no colour change |
| H5 | 0 this week | "**0** of 5", every dab empty, today in ink, no history line, no Tess line |
| H6 | History line | "Met in 1 of the last 3 weeks." Only when at least 1 week was met and 2 or more weeks count; paused weeks and the creation week left out ("of the last 2"). One counted week: H12 |
| H7 | Rule label | "COUNTS WHEN A WORKOUT FINISHES" / "COUNTS WHEN A COOK FINISHES" |
| H8 | Paused label | "PAUSED THIS WEEK" |
| H9 | Monday reset | the count goes to 0 silently; no summary, no notification |
| H10 | Habit with no check-ins ever | as H5, and no history line until a week is met |
| H11 | Creation week (item 109, Product 9:04 PM PT) | "**0** of 5", the target he just set, as H3 and H5. The page never says "new"; only Review and the history line treat the week as new (left out of H6) |
| H12 | History line, one counted week, met (item 109) | "Met last week." If that week is not last week (the week after was paused): "Met the week of Oct 19." Not met: no line |

## 5. Habit Tess lines

| # | Moment | Tess says | UNDO, then |
|---|---|---|---|
| A1 | Habit created ("new habit read 5 a week"; target 3 if none said) | "Read added, 5 times a week." | 4 s: "Read taken back." |
| A2 | Check-in: dab tap, "habit read", "✓ read", "read", "read 20 pages" typed alone; also a note made as a note that ticks Read (`fixtures/habits-from-logs.md` rule 8, Product 9:04 PM PT) | "Read, 3 of 5 this week." | 4 s: "Read check-in taken back, 2 of 5." |
| A3 | "meditated" for a habit called Meditate | "Meditate, 1 of 3 this week." (the habit's name, not the phrase) | as A2 |
| A4 | Check-in that reaches the target | "Read done for the week." | 4 s: "Read check-in taken back, 4 of 5." |
| A5 | Check-in past the target | "Read, 6 this week." | as A2 |
| A6 | Second check-in the same day | "Read is already in for today." | none (nothing written) |
| A6b | Check-in for a past day this week that is already in ("meditated yesterday"; item 109, A6 form) | "Meditate is already in for Monday." | none (nothing written) |
| A7 | Check-in in a paused week | "Read, in for today. The week stays paused." | as A2 |
| A8 | A workout finish counts for Train | "Push A counted for Train, 2 of 3." (D7) | the finish's own |
| A8b | A rule finish that reaches the target (item 109; A4 with the source named first) | "Legs A counted for Train, done for the week." | the finish's own |
| A8c | A rule finish past the target (A5 with the source named first) | "Push A counted for Train, 4 this week." | the finish's own |
| A9 | Undo of that workout's finish | "Push A taken back. Train 1 of 3." (D6) | |
| A10 | Hold the count to pause | "Read paused this week." | 4 s: "Read pause taken back." |
| A11 | Hold again to resume | "Read back on this week, 2 of 5." | 4 s: "Read resume taken back." |
| A12 | Target changed | "Read now 4 times a week." | 4 s: "Read target taken back." |
| A13 | Habit deleted (check-ins go with it; workouts stay) | "Read deleted." | 10 s: "Read is back." (D9) |
| A14 | Rule dab tapped | "Push A, Tuesday 6:20 pm" (D4), then zooms to the workout | |
| A15 | Unknown name (amended, item 109, to match grammar row L848) | With the word "habit" ("habit sing"): nothing from habits, nothing written, the line goes to the model; never creates a habit. A bare unknown name ("meditated", "ran 5k"): nothing from habits; it goes on as today (a note or a task) | |
| A16 | Target of 1 (item 109): create, or change to 1 | "Call mum added, once a week." / "Call mum now once a week." Digits for 2 to 7 ("5 times a week") | as A1 / as A12 |
| A17 | Tap a done day to clear it (item 109; Design's "tapping a done day clears it") | "Read Monday cleared, 1 of 5." Today: "Read today cleared, 1 of 5." | 10 s (a delete): "Read Monday is back, 2 of 5." |
| A18 | "pause read" or "skip read this week" when already paused (item 109) | "Read is already paused this week." | none (nothing written) |
| A19 | "resume read" or "unpause read" when not paused (item 109) | "Read is already on this week." | none (nothing written) |
| A20 | "pause read next week" (item 109) | "Read paused next week." | 4 s: "Read pause taken back." |

No Lock Screen, widget or Live Activity surface is in Design's sheet, and `lockscreen-lines.md` and
`widget-states.md` have none for M3. Proposed: none in M3. Habits send no notifications in v1 (`habits.md`).

## 6. VoiceOver

| Element | Label | Value / hint / actions |
|---|---|---|
| Hero numeral | "Body weight trend" | "78.2 kilograms" |
| Context line | read as text, "kg" spoken "kilograms" | |
| The stroke | "Trend, last 90 days" | "From 79.4 on September 3 to 78.2 today, 1.2 kilograms less. 30 weigh-ins." Give it an `AXChartDescriptor` so the audio graph can play the entries |
| Pinned outlier | "87.4 kilograms, September 16, outside the range" | |
| Ghost | "Body weight 82.4 kilograms, not kept yet" | hint "Double-tap to keep."; actions "Keep", "Change weight", "Dismiss" (the swipe has no VoiceOver path otherwise) |
| Habit block | "Read, 2 of 5 this week" | rule habit adds ", counts when a workout finishes"; paused reads "Read, paused this week" |
| Week row | "Monday and Wednesday done" | 0: "None done yet" |
| Today's dab | "Read today, not in yet" | hint "Double-tap to check in."; done: "Read today, in" |
| Rule dab | "Tuesday, Push A, 6:20 pm" | hint "Opens the workout." |
| Count | as the block | actions "Pause this week" / "Resume this week" (the 0.7 s hold has no VoiceOver path) |
| History line | read as text | |

## 7. Where this differs from Design's sheet (defaults proposed)

- **D1** "Body weight 82.4 kg." has no verb. Principle 1 (5:14 PM PT) and "Set 3 logged. 80 × 8.": "Body weight logged. 82.4 kg."
- **D2** "82.4 kg, 4.2 kg above trend." says kg twice, against the sheet's own "kg once per line": "..., 4.2 above trend." (the brief's "87.4 kg, 8.2 kg above trend" too).
- **D3** "since 3 September" and "on 3 September": master's locale date (6:37 PM PT) gives "Sep 3", which also matches the axis "SEP 3".
- **D4** "Push day A, Tue 18:20": master's time format (6:37 PM PT): "Push A, Tuesday 6:20 pm". Use the workout's own name; master's starter routine is "Push A".
- **D5** "three days to go": digits rule: "3 days to go".
- **D6** "Train, back to 1 of 3." on undoing a finish: M36 decides that line is "Push A taken back."; the count rides after it.
- **D7** "Push day A counted for Train." has no count; `habits.md` makes the count the reward: "..., 2 of 3."
- **D8** The ship list says "x of 7"; the sheet says "of the target". The sheet wins (it says so); no line here says "of 7".
- **D9** The board asked for "taken back" on a habit delete; 6:37 PM PT makes undoing a removal "Read is back."
- **D10** Not in the sheet, proposed above: empty pages (B1, H1), first and second weigh-in (T7, T8), the gap and reseed (B7, B14, T10), past-entry fix and delete (T11, T12), habit create, resume, target change and delete (A1, A11 to A13), past-target count (H4, A5), the Sunday and Monday context lines (H2), and every VoiceOver row. Creating a habit needs a grammar row Core does not have: "new habit {name} {n} a week".
- **D11** The bare-number range 30 to 250 is in kg; with lb chosen it should be 66 to 550.
- **D12** Sheet and brief make "82.4" mid-workout the next set's weight; decision 7:24 PM PT sends bare numbers outside 1 to 50 reps to the model, and snaps spoken weights to the nearest loadable one (82.5). Core and Design to agree; default: the 7:24 rule, so the ghost reads "82.5 × 8".
- "Tap to keep it." is instruction-shaped but matches the voice guide's "Tap to retry."; kept.
