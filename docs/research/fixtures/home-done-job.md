# Home done-job fixtures (Core 0al)

Research worker BG, Oct 16, 2026. Written only: nothing here was run, and no call was made.

These are the finish moments Core 0al's `homeLines` done job is tested against. Each fixture stands alone (its own
store, its own month spend, its own cache) unless it says it follows another one.

**The decision** (Product, 2:42 pm PT Oct 16, `product/decisions.md`): only a finished workout with a best, or one
after a gap of 4 or more days on the same routine, gets Sonnet 5.5 with `SYSTEM_DONE`
(`scripts/ai/home_lines_eval.py`). Every other Home moment stays rules-only. Behind "Tess asks Claude" and the $50
cap. The rules line shows first; Claude's differing words land after it. A 6 s timeout falls back to the rules
silently. The phone checks each line (caps, C1 to C15 with the C15 weekday slip); a failing line keeps the rules
line. One call per finish, cached on the workout, no retries. Money and body facts are never packed.

**Sources:** `docs/ai/home-lines-job.md` (master and the shared copy, which adds section 2b), `scripts/ai/home_lines_eval.py`
(`worth_asking`, `DONE_RULES`, `check_line`, `pack_for`, `guard_pack`), `docs/ai/first-features.md` section 1a,
`TesseraCore/Sources/TesseraCore/Home/HomeLines.swift` (`HomeFact`, `HomeLine`, `HomeLines.line`, `HomeFacts.fact(done:)`,
`daysSinceLastRun`), `HomeLinesTests.swift`, `ai/home-lines-eval-results.md`.

## 1. How the fixtures read

### The gate

A request is built only when all of these hold, in this order. The first one that fails ends it with no request,
no `TessCall` row and the rules line.

| # | Gate | Where |
|---|------|-------|
| G1 | Not demo (`-demo`, `-resetDemo`, `-theme`) | job doc section 5 |
| G2 | "Tess asks Claude" is on and a key is saved | job doc section 5, `ClaudeClient` |
| G3 | The month's spend is under the cap ($50), and `.lines` is under its 80% step-aside ($40) | job doc section 5 |
| G4 | The item is a workout, state `done`, not `fixed` (a done workout with 0 sets is fixed) | `HomeLines.line`, `worth_asking` |
| G5 | It has at least one best, or `sinceLastDays` (same routine, counted in his days) is 4 or more | `worth_asking`, decision |
| G6 | No call has been made for this finish yet (the workout's cache holds no verdict) | decision |

Only the item that passes G4 and G5 goes in the pack. Nothing else on Home is ever packed, even when it sits on the
same screen at the same moment.

### The pack shape (fields only)

One `<facts>` block, one item. Field names follow the job doc section 2 and the script's `pack_for`, with two changes
this file asks for (see section 4, M2 and M8): no `now` and no `partOfDay`, and the best names under `bests`.

```
{"dayLabel": "<his weekday> <part of day>",
 "items": [{"item": "h1", "kind": "workout", "state": "done", "title": "<routine>", "hero": "<routine> done",
            "exercisesDone": n, "exercisesPlanned": n, "sets": n, "bests": ["<short exercise name>", ...],
            "sinceLastDays": n or null,
            "rules": {"context": "<clock words>", "detail": "<SO FAR sentence>"},
            "numbers": [...], "names": ["<routine>", "<best names>"]}]}
```

`numbers` is `HomeLine.numbers` exactly: the fact's numbers (`sinceLastDays`, then exercises done, exercises planned,
sets, then the count of bests when there are 2 or more), then the digits of the rules context, then the digits of the
rules detail, each kept once, in that order (`HomeLinesTests.workoutDone`: `[6, 22, 8, 5, 1]`).

**What is never in it:** weights, reps, volume, units, notes, places, people, health, body weight, steps, money,
other Home items, memory (AI-4 ships `memory: []`), the item's UUID, and any ticking value.

**The leak proof, per fixture.** "Guard clean" below means: the pack's bytes, lowercased and split into whole words,
share no word with the script's `HEALTH` or `MONEY` sets (`guard_pack`: weigh, weighed, weight, kg, lb, body, steps,
sleep, heart, calories, rent, paid, spent, cost, price, money, dollars, and the rest), hold no `$`, `£` or `€`, hold
no `SecretWords` word (code, pin, password, passcode, combo) and no `wifi`, and every digit group in the pack is
either a field value listed for that fixture or a member of its `numbers`. The fixtures that put a money, body or
secret fact on the phone that day list the exact strings that must not appear.

### Rules lines

The rules line is what `HomeLines.line(for: facts.fact(done:))` builds on master today, and it is what Home keeps
whenever Claude's words don't arrive or don't pass:

- hero: "{Routine} done" (rules only; Claude never words it)
- context: the finish clock, `HouseTime.clock`: "8:05 pm", "12:30 am"; a done workout with 0 sets says only the part
  of day ("this afternoon")
- detail: "{n} exercises, {n} sets." plus ", 1 new best." or ", {n} new bests."

Every rules context and detail below is within the caps: context at most 6 words and 32 characters with no stop,
detail one sentence of at most 14 words and 80 characters ending in a stop (`HomeLines.fitsContext`, `fitsDetail`).

### Day labels

His day runs from 4 am to 4 am (`TesseraDay`). Part of day from `DayPart`: morning 7 to 12, midday 12 to 2 pm
(labeled "afternoon"), afternoon 2 to 5 pm, evening 5 to 9 pm, night 9 pm to 4 am. A finish at 12:30 am Friday is
"Thursday night". The week used: Mon Oct 12 to Sun Oct 18, 2026.

## 2. The fixtures

### HD1. A best

- **Moment:** Thu Oct 15. Push A started 6:50 pm, finished 8:05 pm. 6 of 6 exercises, 22 sets. Best: Bench. Last
  Push A Tue Oct 13 (`sinceLastDays` 2). Label "Thursday evening".
- **Calls Claude:** yes. G5 by the best (the gap of 2 alone would not).
- **Pack:** title "Push A", hero "Push A done", exercisesDone 6, exercisesPlanned 6, sets 22, bests ["Bench"],
  sinceLastDays 2, rules {context "8:05 pm", detail "6 exercises, 22 sets, 1 new best."}, numbers [2, 6, 22, 8, 5, 1],
  names ["Push A", "Bench"]. Guard clean.
- **Rules line:** context "8:05 pm" (2 words, 7 chars). Detail "6 exercises, 22 sets, 1 new best." (7 words, 33 chars).
- **Claude returns:** context "8:05 pm, a bench best" (5 words, 21 chars); detail unchanged.
- **Pass:** "8:05 pm" draws at once. Exactly one request (model `claude-sonnet-5-5`, system text byte-equal to
  `SYSTEM_DONE`, one item). The context passes every check (C6: "05" is the digit 5, licensed), redraws wet in
  `tess` and dries; the detail is identical, so it never redraws. The verdict and words are cached on this workout.

### HD2. Two bests, a context over the caps

- **Moment:** Fri Oct 16. Push A finished 7:50 pm. 6 of 6, 20 sets. Bests: Bench, Press. `sinceLastDays` 3. Label
  "Friday evening".
- **Calls Claude:** yes, by the bests.
- **Pack:** title "Push A", exercisesDone 6, exercisesPlanned 6, sets 20, bests ["Bench", "Press"], sinceLastDays 3,
  rules {context "7:50 pm", detail "6 exercises, 20 sets, 2 new bests."}, numbers [3, 6, 20, 2, 7, 50], names
  ["Push A", "Bench", "Press"]. Guard clean.
- **Rules line:** context "7:50 pm" (2 words, 7 chars). Detail "6 exercises, 20 sets, 2 new bests." (7 words, 34 chars).
- **Claude returns:** context "7:50 pm, bench and overhead press bests" (7 words, 39 chars); detail "6 exercises, 20
  sets, 2 new bests: bench and press." (10 words, 51 chars).
- **Pass:** the context fails C2 and C3 and keeps "7:50 pm"; it is refused, never cut. The detail passes and swaps
  alone. The row reads "rejected C2, C3" for the context. Nothing on Home says a line was refused.

### HD3. A gap of exactly 4 days, same routine

- **Moment:** Sat Oct 17. Pull A finished 10:15 am. 5 of 5, 17 sets. No best. Last Pull A Tue Oct 13 (`sinceLastDays`
  4). Label "Saturday morning".
- **Calls Claude:** yes. G5 by the gap: 4 is the threshold, inclusive (`GAP_DAYS = 4`, `>=`).
- **Pack:** title "Pull A", exercisesDone 5, exercisesPlanned 5, sets 17, bests [], sinceLastDays 4, rules {context
  "10:15 am", detail "5 exercises, 17 sets."}, numbers [4, 5, 17, 10, 15], names ["Pull A"]. Guard clean.
- **Rules line:** context "10:15 am" (2 words, 8 chars). Detail "5 exercises, 17 sets." (4 words, 21 chars).
- **Claude returns:** context "10:15 am, first in 4 days" (6 words, 25 chars).
- **Pass:** one request; the context passes and lands after the rules line.

### HD4. A gap of 9 days, the clock dropped

- **Moment:** Thu Oct 15. Legs finished 7:40 pm. 5 of 5, 16 sets. No best. Last Legs Tue Oct 6 (`sinceLastDays` 9).
  Label "Thursday evening".
- **Calls Claude:** yes, by the gap.
- **Pack:** title "Legs", exercisesDone 5, exercisesPlanned 5, sets 16, bests [], sinceLastDays 9, rules {context
  "7:40 pm", detail "5 exercises, 16 sets."}, numbers [9, 5, 16, 7, 40], names ["Legs"]. Guard clean.
- **Rules line:** context "7:40 pm". Detail "5 exercises, 16 sets." (4 words, 21 chars).
- **Claude returns:** context "first in 9 days" (4 words, 15 chars).
- **Pass:** passes. D2 lets a done item drop its whole clock (C7); 9 is licensed (C6). Had Claude written "first in
  nine days", C8 refuses it and "7:40 pm" stays.

### HD5. A gap of 3 days: no call

- **Moment:** Thu Oct 15. Push A finished 6:55 pm. 6 of 6, 21 sets. No best. Last Push A Mon Oct 12 (`sinceLastDays`
  3). Label "Thursday evening".
- **Calls Claude:** no. No best and 3 is under 4.
- **Pack:** none built.
- **Rules line:** context "6:55 pm". Detail "6 exercises, 21 sets." (4 words, 21 chars).
- **Pass:** no request, no `TessCall` row, no cache entry, nothing redraws.

### HD6. A gap on a different routine: no call

- **Moment:** Wed Oct 14. Push A finished 7:20 pm. 6 of 6, 20 sets. No best. Last Push A Mon Oct 12 (`sinceLastDays`
  2). Home also shows "Legs tomorrow" (planned), and Legs last ran Wed Oct 7, 7 days ago. Label "Wednesday evening".
- **Calls Claude:** no. The gap counts only for the routine just finished (`daysSinceLastRun(of: routine)`); Push A's
  is 2. The planned Legs item is not a done workout, so its 7 never reaches the gate.
- **Pack:** none built. The Legs item would never be packed on any Home.
- **Rules line:** context "7:20 pm". Detail "6 exercises, 20 sets."
- **Pass:** no request. A test that hands the gate the largest `sinceLastDays` on Home, or days since any workout,
  instead of the finished routine's own, fails here.

### HD7. No best and no gap: no call

- **Moment:** Fri Oct 16. Pull A finished 8:20 pm. 5 of 5, 18 sets. No best. Last Pull A Wed Oct 14 (`sinceLastDays`
  2). Label "Friday evening".
- **Calls Claude:** no.
- **Pack:** none built.
- **Rules line:** context "8:20 pm". Detail "5 exercises, 18 sets."
- **Pass:** no request, no row.

### HD8. A first run of a routine, no best: no call

- **Moment:** Sun Oct 18. Legs B, a routine he made Saturday, finished 11:05 am for the first time. 5 of 5, 15 sets.
  No best (each exercise has older sets from other routines). `sinceLastDays` nil. Label "Sunday morning".
- **Calls Claude:** no. Nil is not 4 or more (the script reads it as 0), and there is no best.
- **Pack:** none built.
- **Rules line:** context "11:05 am". Detail "5 exercises, 15 sets."
- **Pass:** no request. A "first time" is not a gap.

### HD9. The gap counted in his days across 4 am

- **Moment:** Thu Oct 15. Pull A finished 7:10 pm. 5 of 5, 15 sets. No best. The last Pull A ended Mon Oct 12 at
  1:10 am, which is his Sunday Oct 11. By the wall calendar that is 3 days; by his day it is 4 (`sinceLastDays` 4).
  Label "Thursday evening".
- **Calls Claude:** yes, by the gap of 4, as `daysSinceLastRun` counts it (`TesseraDay.day(of:)` on both ends).
- **Pack:** title "Pull A", exercisesDone 5, exercisesPlanned 5, sets 15, bests [], sinceLastDays 4, rules {context
  "7:10 pm", detail "5 exercises, 15 sets."}, numbers [4, 5, 15, 7, 10], names ["Pull A"]. Guard clean.
- **Rules line:** context "7:10 pm". Detail "5 exercises, 15 sets."
- **Claude returns:** context "7:10 pm, first in 4 days" (6 words, 24 chars).
- **Pass:** one request. The gate and the pack use the same number; a gate that counts wall-clock days makes no call
  here and fails the fixture. Claude's "4" is licensed; a "3" would fail C6.

### HD10. A finish at 12:30 am

- **Moment:** Legs started Thu Oct 15 at 11:30 pm, finished Fri Oct 16 at 12:30 am. 5 of 5, 15 sets. Best: Squat.
  Last Legs Tue Oct 13 (`sinceLastDays` 2). His day is still Thursday: label "Thursday night".
- **Calls Claude:** yes, by the best.
- **Pack:** dayLabel "Thursday night", title "Legs", exercisesDone 5, exercisesPlanned 5, sets 15, bests ["Squat"],
  sinceLastDays 2, rules {context "12:30 am", detail "5 exercises, 15 sets, 1 new best."}, numbers [2, 5, 15, 12, 30,
  1], names ["Legs", "Squat"]. Guard clean. No "Friday" anywhere in it.
- **Rules line:** context "12:30 am" (2 words, 8 chars). Detail "5 exercises, 15 sets, 1 new best." (7 words, 33 chars).
- **Claude returns:** context "12:30 am, a squat best" (5 words, 22 chars).
- **Pass:** passes and lands. The workout counts on Thursday; the cache entry lives on the workout, so the 4 am
  turnover does not make a second call (see HD18).

### HD11. C15 trap: a weekday Claude made up

- **Moment:** Thu Oct 15. Push A finished 7:30 pm. 6 of 6, 20 sets. No best. Last Push A Fri Oct 9 (`sinceLastDays`
  6). Label "Thursday evening".
- **Calls Claude:** yes, by the gap.
- **Pack:** title "Push A", exercisesDone 6, exercisesPlanned 6, sets 20, bests [], sinceLastDays 6, rules {context
  "7:30 pm", detail "6 exercises, 20 sets."}, numbers [6, 20, 7, 30], names ["Push A"]. Guard clean. The pack holds
  no weekday but the label's own.
- **Rules line:** context "7:30 pm". Detail "6 exercises, 20 sets."
- **Claude returns:** context "7:30 pm, first since Saturday" (5 words, 29 chars). Wrong: the last Push A was a Friday.
- **Pass:** refused as C15 (a weekday the pack doesn't hold); "7:30 pm" stays; the row says "rejected C15". The true
  "7:30 pm, first since Friday" is refused the same way, since no weekday but the label's is in the facts. "7:30 pm,
  first in 6 days" passes. **The script lets the wrong line through today** (C9 exempts weekdays, the no-repeat check
  looks only at the label's weekday, C15 only at "usual"): section 4, M4.

### HD12. C15 trap: "yesterday" across the 4 am boundary

- **Moment:** Push A started Thu Oct 15 at 11:55 pm, finished Fri Oct 16 at 1:40 am. 6 of 6, 19 sets. Best: Bench.
  `sinceLastDays` 2. Label "Thursday night".
- **Calls Claude:** yes, by the best.
- **Pack:** dayLabel "Thursday night", title "Push A", exercisesDone 6, exercisesPlanned 6, sets 19, bests ["Bench"],
  sinceLastDays 2, rules {context "1:40 am", detail "6 exercises, 19 sets, 1 new best."}, numbers [2, 6, 19, 1, 40],
  names ["Push A", "Bench"]. Guard clean. No wall-clock "now" ("Fri 1:40 am"), which is what invites the slip.
- **Rules line:** context "1:40 am" (2 words, 7 chars). Detail "6 exercises, 19 sets, 1 new best." (7 words, 33 chars).
- **Claude returns:** detail "Started yesterday, 6 exercises, 19 sets, 1 new best." (9 words, 52 chars); context
  "early Friday, a bench best" (5 words, 26 chars).
- **Pass:** both refused as C15. In his day the workout started and ended on Thursday, so "yesterday" is false, and
  "Friday" is not his day. Rules context and detail both stay. A relative day word ("yesterday", "last night",
  "tomorrow", "this morning") that the rules line doesn't hold fails on a done line. The script passes both today
  (M4).

### HD13. C15 trap: "after work" on a Saturday, with no memory

- **Moment:** Sat Oct 17. Push A finished 10:20 am. 6 of 6, 21 sets. Best: Bench. `sinceLastDays` 2. Label
  "Saturday morning". AI-4 ships `memory: []`, so no habit line is in the request.
- **Calls Claude:** yes, by the best.
- **Pack:** title "Push A", exercisesDone 6, exercisesPlanned 6, sets 21, bests ["Bench"], sinceLastDays 2, rules
  {context "10:20 am", detail "6 exercises, 21 sets, 1 new best."}, numbers [2, 6, 21, 10, 20, 1], names ["Push A",
  "Bench"]. Guard clean.
- **Rules line:** context "10:20 am". Detail "6 exercises, 21 sets, 1 new best." (7 words, 33 chars).
- **Claude returns:** context "after work, a bench best" (5 words, 24 chars).
- **Pass:** refused as C15; "10:20 am" stays. On a done line, "usual", "usually", "after work" and "before work" fail
  with or without memory, because `DONE_RULES` bans them and the facts can't support them. The script's
  `weekday_slip` returns false here because memory is empty (M4).

### HD14. A money fact the same day: never packed

- **Moment:** Thu Oct 15. At 9:10 am he said "rent paid"; the task "Pay rent" is done and a Money entry of $1,850 is
  saved. Push B finished 6:40 pm. 5 of 5, 18 sets. Best: Press. `sinceLastDays` 3. Label "Thursday evening".
- **Calls Claude:** yes, by the best. The rent task is not a done workout and is never packed.
- **Pack:** title "Push B", exercisesDone 5, exercisesPlanned 5, sets 18, bests ["Press"], sinceLastDays 3, rules
  {context "6:40 pm", detail "5 exercises, 18 sets, 1 new best."}, numbers [3, 5, 18, 6, 40, 1], names ["Push B",
  "Press"].
- **Leak proof:** the body (system, `<facts>`, and the empty memory) holds none of "rent", "paid", "Pay rent",
  "1,850", "1850", "850", "$", "money", "9:10". Guard clean. The task's handle is never assigned.
- **Rules line:** context "6:40 pm". Detail "5 exercises, 18 sets, 1 new best."
- **Pass:** one request with the single workout item; the captured body passes the leak proof byte for byte.

### HD15. A body fact the same day: never packed

- **Moment:** Fri Oct 16. He weighed in at 7:05 am: 81.4 kg (the Weight habit, a Health sample). Legs finished
  6:15 pm. 5 of 5, 16 sets. No best. Last Legs Sat Oct 10 (`sinceLastDays` 6). Label "Friday evening".
- **Calls Claude:** yes, by the gap.
- **Pack:** title "Legs", exercisesDone 5, exercisesPlanned 5, sets 16, bests [], sinceLastDays 6, rules {context
  "6:15 pm", detail "5 exercises, 16 sets."}, numbers [6, 5, 16, 15], names ["Legs"].
- **Leak proof:** the body holds none of "81.4", "81", "kg", "weigh", "weighed", "weight", "body", "7:05". Guard
  clean. No weight, rep or unit from the sets is packed either.
- **Rules line:** context "6:15 pm". Detail "5 exercises, 16 sets."
- **Claude returns:** context "6:15 pm, first in 6 days" (6 words, 24 chars).
- **Pass:** one request, leak proof holds, the context passes and lands. A returned line with "kg" or "weight" would
  fail C12 and keep the rules line, but it can only appear if the pack leaked.

### HD16. A secret word in the workout note: never packed

- **Moment:** Wed Oct 14. Pull A finished 6:30 pm. 5 of 5, 18 sets. Best: Deadlift. `sinceLastDays` 2. The
  workout's note reads "locker code 4417, gym wifi is tacocat, door hunter2". Label "Wednesday evening".
- **Calls Claude:** yes, by the best.
- **Pack:** title "Pull A", exercisesDone 5, exercisesPlanned 5, sets 18, bests ["Deadlift"], sinceLastDays 2, rules
  {context "6:30 pm", detail "5 exercises, 18 sets, 1 new best."}, numbers [2, 5, 18, 6, 30, 1], names ["Pull A",
  "Deadlift"]. No note field exists in the pack shape.
- **Leak proof:** the body holds none of "locker", "code", "4417", "wifi", "tacocat", "door", "hunter2". Guard clean.
  If a note ever reached the body, `ClaudeClient`'s SecretWords wall refuses the send and Home keeps the rules line.
- **Rules line:** context "6:30 pm". Detail "5 exercises, 18 sets, 1 new best."
- **Pass:** one request; the leak proof holds.

### HD17. Timeout at 6 s: the rules, silently

- **Moment:** Fri Oct 16. Push A finished 8:10 pm. 6 of 6, 22 sets. Best: Bench. `sinceLastDays` 1. Label "Friday
  evening". The reply comes back at 7.3 s.
- **Calls Claude:** yes, by the best.
- **Pack:** title "Push A", exercisesDone 6, exercisesPlanned 6, sets 22, bests ["Bench"], sinceLastDays 1, rules
  {context "8:10 pm", detail "6 exercises, 22 sets, 1 new best."}, numbers [1, 6, 22, 8, 10], names ["Push A",
  "Bench"]. Guard clean.
- **Rules line:** context "8:10 pm". Detail "6 exercises, 22 sets, 1 new best."
- **Pass:** at 6.0 s the call ends as a timeout. "8:10 pm" never moves; no message, mark or Failure line on Home. The
  7.3 s reply is dropped and never drawn. No retry. The timeout is cached on the workout, so reopening Home makes
  no second call; this finish keeps the rules line for good. The row says "timeout" and counts toward the month.

### HD18. A cached second open: no second call

- **Moment:** follows HD1. He closes the app at 8:07 pm and opens Home again at 9:30 pm (the part of day turns from
  evening to night), at 11:15 pm, and on a widget timeline reload at 11:40 pm. Same workout, same counts.
- **Calls Claude:** no. G6: this finish already has its verdict.
- **Pack:** none built.
- **Rules line:** "8:05 pm" / "6 exercises, 22 sets, 1 new best." (as HD1).
- **Pass:** zero requests after HD1's one. The cached "8:05 pm, a bench best" is re-checked by `TessLineCheck` on load
  and draws at rest with no drying (not news). The part-of-day turn, the clock and the widget reload change nothing.
  If he edits the workout so the counts change (a set added after finishing), that is still the same finish; Product
  to confirm whether it re-asks (section 4, M1).

### HD19. "Tess asks Claude" off

- **Moment:** Sat Oct 17. Pull A finished 5:20 pm. 5 of 5, 18 sets. Best: Row. `sinceLastDays` 3. The switch is off.
- **Calls Claude:** no. G2.
- **Pack:** none built.
- **Rules line:** context "5:20 pm". Detail "5 exercises, 18 sets, 1 new best."
- **Pass:** no request, no row. The cache is ignored and cleared. Turning the switch on later the same evening does
  not ask for this finish: the call belongs to the moment of finishing (Product to confirm, M1).

### HD20. Cap reached

- **Moment:** Thu Oct 15. Push A finished 8:05 pm with a Bench best (as HD1). The month's spend is $50.00 of $50.
- **Calls Claude:** no. G3: `ClaudeClient` returns `.refused(.cap)` before any bytes leave.
- **Pack:** built in memory at most; never sent.
- **Rules line:** "8:05 pm" / "6 exercises, 22 sets, 1 new best."
- **Pass:** no request; rules lines; nothing visible changes and no "capped" line shows on Home. Variant HD20b: spend
  $40.10, under the cap but past the `.lines` 80% step-aside; also no request per the job doc (M6).

### HD21. Claude adds nothing: no redraw

- **Moment:** Sun Oct 18. Legs finished 11:05 am. 5 of 5, 15 sets. No best. Last Legs Tue Oct 13 (`sinceLastDays` 5). Label "Sunday morning".
- **Calls Claude:** yes, by the gap.
- **Pack:** title "Legs", exercisesDone 5, exercisesPlanned 5, sets 15, bests [], sinceLastDays 5, rules {context
  "11:05 am", detail "5 exercises, 15 sets."}, numbers [5, 15, 11], names ["Legs"]. Guard clean.
- **Rules line:** context "11:05 am". Detail "5 exercises, 15 sets."
- **Claude returns:** no tool call (Sonnet runs with auto), or both slots byte-equal to the rules words.
- **Pass:** `.noLine` (or identical words): no redraw, no drying; the call is counted and cached on the workout.

### HD22. Done with 0 sets: fixed, no call

- **Moment:** Fri Oct 16. Pull A started 2:40 pm and finished 3:10 pm with no sets logged. Last Pull A Sat Oct 10
  (`sinceLastDays` 6).
- **Calls Claude:** no. G4: a done workout with 0 sets is `fixed`, even with a gap of 6.
- **Pack:** none built.
- **Rules line:** hero "Pull A, no sets", context "this afternoon" (2 words, 14 chars), detail none.
- **Pass:** no request. A pack built for a fixed item, or a line for it, fails C14.

### HD23. A done cook: rules only

- **Moment:** Thu Oct 15. Chili cooked, done 7:30 pm. Last chili 12 days ago.
- **Calls Claude:** no. Not a workout; every other Home moment stays rules-only, gap or not.
- **Pack:** none built.
- **Rules line:** hero "Chili done", context "7:30 pm", detail none.
- **Pass:** no request, no row.

### HD24. Demo with a best

- **Moment:** simulator, `-demoTime 18:10 -resetDemo`. The demo history finishes Push A at 6:05 pm with a Bench best.
- **Calls Claude:** no. G1.
- **Pack:** none built.
- **Rules line:** context "6:05 pm". Detail as the demo counts give it.
- **Pass:** no request; the cache is never read or written.

## 3. Counts

| | Fixtures | Count |
|---|---|---|
| Calls Claude (one request each) | HD1, HD2, HD3, HD4, HD9, HD10, HD11, HD12, HD13, HD14, HD15, HD16, HD17, HD21 | 14 |
| No call | HD5, HD6, HD7, HD8, HD18, HD19, HD20, HD22, HD23, HD24 | 10 |
| Total | | 24 |

Of the 14 calls: Claude's words land in 6 (HD1, HD3, HD4, HD9, HD10, HD15), one slot of two lands in 1 (HD2), the
rules line stays in 7 (refused: HD11, HD12, HD13; timeout: HD17; no new words: HD21; HD14 and HD16 test the pack, not
the reply). Of the 10 no-calls: 4 by the gate's best-or-gap rule (HD5 to HD8), 1 by the cache (HD18), 3 by the walls
(HD19 switch, HD20 cap, HD24 demo), 2 because they aren't done workouts with sets (HD22, HD23).

## 4. Where the decision, the job doc and the script differ

- **M1. One call per finish vs a day-and-hash cache.** The decision caches on the workout with one call per finish.
  `home-lines-job.md` keys the cache by his day plus a facts hash (master lines 62 to 68) and asks again on a
  part-of-day turn, the 4 am turnover, a FORGET, or the switch turned on (lines 72 to 75); a changed hash also drops
  a reply as stale (line 85). Under the doc, HD18 and HD10 would call twice. Open for Product: does a set added after
  finishing count as a new finish?
- **M2. The script packs ticking values.** `pack_for` puts `now` and `partOfDay` in every pack
  (`scripts/ai/home_lines_eval.py:604`), against the doc's "Ticking values never enter the pack" (job doc line 36).
  They change the hash (more calls, M1), and "now": "Fri 1:40 am" is what invites HD12's "yesterday".
- **M3. Retries.** The decision says no retries. The script retries up to 5 times with backoff
  (`home_lines_eval.py:647`, `648`, `668`) on a 30 s socket timeout (`:674`); its 6 s is only a latency score (`:50`,
  `:870`). Fine for an eval harness; Core must not copy it.
- **M4. C15 is narrower than "the weekday slip".** `weekday_slip` (`home_lines_eval.py:211` to `219`) fires only on
  "usual", "usually", "after work" or "before work", only on a Saturday or Sunday label, and only when memory says
  "weekdays". AI-4 ships `memory: []` (job doc line 17), so `if not memory` (`:214`) returns false on every done call
  and C15 never fires. A made-up weekday (HD11) passes, because C9 exempts weekdays (`:277`) and the no-repeat rule
  checks only the label's own weekday (`:307` to `310`). "yesterday" across 4 am (HD12) has no check at all. HD11 to
  HD13 assume the phone's C15 covers all three.
- **M5. Output shape.** The job doc says `{"item": "h1", ...}` with `context` and `detail` optional (lines 22 to 23);
  the script's `proposeLines` uses `id` and requires both (`home_lines_eval.py:116`, `:123`). Max tokens: 512 in the
  doc (line 14), 1500 in the script (`:638`).
- **M6. The cap.** The decision names the $50 cap; the job doc also steps `.lines` aside at 80%, $40 (line 93), so
  done lines stop at $40. Not a contradiction, but Product should know HD20b makes no call.
- **M7. Digits as text vs numbers.** `HomeLine.numbers` holds Ints, so "8:05" licenses 8 and 5
  (`HomeLines.swift:106` to `108`, `:171`). The script's C6 compares digit strings (`home_lines_eval.py:257` to `258`)
  and its fixture licenses "05" by hand. A literal port refuses HD1's "8:05 pm, a bench best" as C6.
- **M8. Field names.** The gap is `HomeFact.sinceLastDays` (`HomeLines.swift:36`), counted in his days
  (`daysSinceLastRun`, `:593` to `603`); the script and first-features call it `lastSameRoutineDaysAgo`
  (`home_lines_eval.py:114`, `first-features.md:56`). The bests list carries the old word as its key in both
  (`HomeLines.swift:32`, `home_lines_eval.py:114`); this file writes `bests`. `HomeLine.text`'s doc comment still says
  the old word (`HomeLines.swift:91`), as the job doc already notes.
- **M9. Master's job doc predates the decision.** Master's section 2a still ends "Claude Home wording stays off"
  (line 58) and has no section 2b; only the shared copy (`ai/home-lines-job.md` lines 60 to 68) carries Kaushik's
  2:41 pm pick.
- **M10. A stale note.** "Home doesn't use the lens" (job doc line 130) is out of date: `NowPage.swift:252` draws the
  done workout from `HomeLines.line(for: facts.fact(done:))`.

## Rulings (AI architecture, Oct 16, home-lines-job.md section 2c)

All ten mismatches are settled the way this file reads:
1. The cache is keyed by workout id only, one call per finish ever (HD10, HD18). Product 2:42 amended: a set added after finish only redraws the rules line, with no second call.
2. `now` and `partOfDay` never ride in a done pack.
3. Core uses a 6 s timeout and no retries. The script's 30 s timeout and retries are eval-only.
4. The phone's C15 refuses any weekday word, or yesterday, today, tonight or this morning, that doesn't match the finish's house day. "usual" stays banned (HD11 to HD13).
5. The doc's shape wins: `item`, both slots optional, 512 tokens.
6. The $40 step-aside (80% of the $50 cap) is intended for done lines too (HD20b).
7. C6 compares numeric values, so "8:05" allows 8 and 5.
8. The gap field is `sinceLastDays`.
9 and 10. The job doc is updated.
