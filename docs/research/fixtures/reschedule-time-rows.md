# Reschedule and time-form rows (RC13, RC11), widened to 40 each

For: Core engine, second half of the grammar batch (board item 16). Research lab. Date: 2026-10-15.

**Master read:** `origin/master` at `02903a0fd31010dc46b85dd98e51781454f61dff` (Merge PR #144, 2026-10-15 16:29 -0700). The grammar files last changed in `ae0d936` (Grammar hotfix, QA on #115), the same code `grammar-misfires.md` traced, so its line refs ("G:", "K:") still hold.

**Clock.** Thu 15 Oct 2026, **18:10** local (the demo default, `-demoTime 18:10`). A few rows run at **09:00** or **23:30** the same day to test passed times; the Clock column says which. Fri is 16 Oct, Sat 17, Sun 18, Mon 19, Tue 20, Wed 21, next Thu 22, next Sat 24. All times are wall clock. For the tests use `TimeZone(identifier: "America/Los_Angeles")` (PDT today, no DST change before 1 Nov).

This is a static read. The container has no Swift toolchain, so every master parse is traced by hand from `TessGrammar.swift`, `TessGrammar+Kitchen.swift`, `Tasks/Tasks.swift` (`TaskList`, `MoveTask`) and `ExerciseLibrary.swift`. Nothing was run.

Source rows: `grammar-misfires.md` rows 125 and 126 (RC13) and 73, 90 to 94, 115, 116, 119, 120 (RC11). Those rows are not repeated here except where a wider variant was needed.

## Product calls applied

From `../../product/decisions.md`, "Grammar sweep calls" (4:26 PM PT) and the entries around it:

- **Call 1, bare hours.** 1 to 6 are PM. 7 to 11 are the next reading that has not passed today. 12 is noon. I apply the same rule to a bare hour with minutes (`9:30`, `7.30`, `half 7`), since those carry no am or pm either. On a day other than today both readings are still ahead, so "the next one" is the AM one (7 to 11 AM, 1 to 6 PM).
- **Call 2, past logs.** A past log writes a note dated that day, never a task.
- **Call 4, "is" questions.** These go to the question path, never a task.
- **Call 5, passed times.** Never write a task in the past. A time today that has passed lands tomorrow at that time.
- **"paid" plus an amount belongs to Money** (4:34 PM PT). Until Money lands it must not be a task.
- **"thu" said on a Thursday means today** (18:58 UTC entry).

## How to read the tables

**Contexts.** I: idle, nothing running. W: live workout, entry in focus is Bench Press with last set 80 x 8.

**Task fixtures** (open unless said). These add to the fixtures in `grammar-misfires.md`:

| Task | When |
|---|---|
| Dentist | Sat 17 Oct 10:00 |
| Call mum | no date (Later) |
| Clean the oven | no date |
| Haircut | Thu 15 Oct 17:00 (today, already passed at 18:10) |
| Pay rent | Fri 16 Oct 09:00 |
| Bins out | Thu 15 Oct 21:00 (today, still ahead at 18:10) |
| Call dad | Fri 16 Oct 12:00 |
| Call bank | Fri 16 Oct 11:00, **done** |

**Verdict.**
- **wrong write**: master writes the wrong object, the wrong date or time, or a wrong title. The fix changes today's behaviour.
- **miss**: master writes nothing and hands to the model, but the grammar should own the phrase. The fix changes today's behaviour.
- **OK**: master already does what is expected. Guard row: the fix must keep it passing.

**Rule column** names the rule that gives the expected parse. R-codes are defined in the rules list under each table.

## Table A: reschedule (RC13), 40 rows

| # | Phrase | Clock | Ctx | Master parse | Expected | Rule | Verdict |
|---|---|---|---|---|---|---|---|
| A1 | move dentist to fri | 18:10 | I | Reschedule Dentist, Fri 16 09:00 (default 09:00, G:435) | Reschedule Dentist, Fri 16 10:00 | R13a | wrong write |
| A2 | Move the dentist to Friday. | 18:10 | I | Same as A1 (shape is case-blind; `Friday.` is trimmed; `the` dropped, G:142): Fri 16 09:00 | Reschedule Dentist, Fri 16 10:00 | R13a | wrong write |
| A3 | move my haircut to tmrw | 18:10 | I | Reschedule Haircut, Fri 16 09:00 | Reschedule Haircut, Fri 16 17:00 | R13a | wrong write |
| A4 | push dentist till monday | 18:10 | I | Reschedule Dentist, Mon 19 09:00 | Reschedule Dentist, Mon 19 10:00 | R13a | wrong write |
| A5 | shift dentist to sun | 18:10 | I | Reschedule Dentist, Sun 18 09:00 (`sun` is last, read raw by `extract`) | Reschedule Dentist, Sun 18 10:00 | R13a | wrong write |
| A6 | move dentist to 3pm | 18:10 | I | Time only, so today; 15:00 passed, so tomorrow (G:429-434): Fri 16 15:00 | Reschedule Dentist, Sat 17 15:00 (its own day) | R13b | wrong write |
| A7 | move dentist to 9:30 | 18:10 | I | `9:30` is a time (colon, G:420); today 09:30 passed: Fri 16 09:30 | Reschedule Dentist, Sat 17 09:30 (own day; both readings ahead, so AM) | R13b, call 1 | wrong write |
| A8 | move dentist to 11 | 18:10 | I | `11` has no `at`, letter or colon, so no date; `parseReschedule` nil, shape matches, nil (G:87). Model | Reschedule Dentist, Sat 17 11:00 | R13c, call 1 | miss |
| A9 | move dentist to 3 | 18:10 | I | Lift: weight 3, no reps, nil. Same path as A8. Model | Reschedule Dentist, Sat 17 15:00 | R13c, call 1 | miss |
| A10 | move dentist to sat 2pm | 18:10 | I | Reschedule Dentist, Sat 17 14:00 | Same | both said | OK |
| A11 | move dentist to fri at 4 | 18:10 | I | `at 4` is 04:00 (24-hour, G:417): Fri 16 04:00 | Reschedule Dentist, Fri 16 16:00 | call 1 (RC1) | wrong write |
| A12 | push the dentist to thu 3pm | 18:10 | I | `thu` today, 15:00 passed, weekday rule adds a week (G:444-445): Thu 22 15:00 | Reschedule Dentist, Fri 16 15:00 | "thu" is today + call 5 | wrong write (see Q1) |
| A13 | move dentist to tonight | 18:10 | I | `tonight` is today 20:00 (G:409): Thu 15 20:00 | Same (tonight carries its own time) | R13d | OK |
| A14 | move dentist to today | 18:10 | I | Today with no time, 09:00 passed, so next whole hour (G:447-452): Thu 15 19:00 | Same. Keeping 10:00 would be in the past | R13e, call 5 | OK (guard for R13a) |
| A15 | move haircut to 7 | 18:10 | I | No date (bare 7). Model | Reschedule Haircut, Thu 15 19:00 (own day is today; 07:00 passed) | R13c, call 1 | miss |
| A16 | move pay rent to 7pm | 18:10 | I | Time only, today 19:00 is ahead: Thu 15 19:00 | Reschedule Pay rent, Fri 16 19:00 (its own day) | R13b | wrong write |
| A17 | move pay rent to 5pm | 18:10 | I | Today 17:00 passed, so tomorrow: Fri 16 17:00 | Same (right by accident: its own day is tomorrow) | R13b | OK |
| A18 | move bins out to 9:30 | 18:10 | I | Today 09:30 passed: Fri 16 09:30 | Reschedule Bins out, Thu 15 21:30 (own day today; 09:30 passed, 21:30 is next) | R13b, call 1 | wrong write |
| A19 | move call mum to fri | 18:10 | I | Reschedule Call mum, Fri 16 09:00 | Same (no time of its own, so 09:00) | R13a fallback | OK |
| A20 | move call mum to 7 | 18:10 | I | No date. Model | Reschedule Call mum, Thu 15 19:00 (no day of its own, so today) | R13c, call 1 | miss |
| A21 | move call to fri | 18:10 | I | Two open matches (Call mum, Call dad), nil, shape, model | Same | one match only | OK |
| A22 | move call bank to fri | 18:10 | I | Call bank is done, filtered out (G:143). Model | Same | open tasks only | OK |
| A23 | push dentist to next week | 18:10 | I | `next week` gives no date. Model | Reschedule Dentist, Sat 24 10:00 (one week on, same time) | R13f | miss (see Q3) |
| A24 | move dentist to next fri | 18:10 | I | `next` is allowed as the rest (G:141): Fri 16 09:00 | Reschedule Dentist, Fri 16 10:00 (day per GC open question 4) | R13a | wrong write (see Q4) |
| A25 | move pay rent to sat morning | 18:10 | I | Rest is `morning`, so nil. Model | Reschedule Pay rent, Sat 17 09:00 | R11d in `extract` | miss |
| A26 | push dentist to later | 18:10 | I | `later` is not a date. Model | Move Dentist to Later (no date; `MoveTask(later: true)`) | R13g | miss |
| A27 | push to tmrw | 18:10 | I | No task named, so the shape fails. Task rule: **task "Push to", Fri 16 09:00** | Model (nothing named) | R13h | wrong write |
| A28 | push it to fri | 18:10 | I | Shape matches, name `it` matches no title. Model | Same (the model knows what "it" is, or asks) | R13h | OK |
| A29 | do it later | 18:10 | I | No date, not explicit. Model | Same | none (model) | OK |
| A30 | can you move the dentist to friday | 18:10 | I | Shape is anchored at `move`, so no. Task rule: **task "Can you move the dentist to", Fri 16 09:00** | Reschedule Dentist, Fri 16 10:00 | R13i, R13a | wrong write |
| A31 | move dentist to fri please | 18:10 | I | Rest is `please`, nil. Model | Reschedule Dentist, Fri 16 10:00 | R13i, R13a | miss |
| A32 | moved dentist to fri | 18:10 | I | `moved` is not in the shape. **Task "Moved dentist to", Fri 16 09:00** | Reschedule Dentist, Fri 16 10:00 (he is telling Tess the new day) | R13j | wrong write (see Q5) |
| A33 | is the dentist still on fri | 18:10 | I | `is` is not a question lead (G:97). **Task "Is the dentist still on", Fri 16 09:00** | Nil (question path) | call 4 | wrong write |
| A34 | push ups to failure | 18:10 | I | No numbers, no lift. Shape matches, no date, nil. Model | Same. Never a reschedule | look-alike | OK |
| A35 | move 80 to 82.5 | 18:10 | W | Relative set misses; lift reads reps 82.5 (not whole), nil; shape matches, no date. Model | Same (a weight change is the workout's, later) | look-alike | OK |
| A36 | move money to savings fri | 18:10 | I | Shape matches, `extract` leaves `savings`, nil. Model | Same (Money, never a reschedule or task) | look-alike | OK |
| A37 | shift 8 to 4 tomorrow | 18:10 | I | Lift fails (`to` is under 3 letters). Shape matches, rest `4`, nil. Model | Same. With R13c, no task is named "8", so still nil | look-alike, guard for R13c | OK |
| A38 | move haircut to 8 | **09:00** | I | No date. Model | Reschedule Haircut, Thu 15 20:00 (own day today; 08:00 passed) | R13c, call 1 | miss |
| A39 | move bins out to 11 | **23:30** | I | No date. Model | Reschedule Bins out, Fri 16 11:00 (11:00 and 23:00 both passed today, so the next is tomorrow 11:00) | R13c, call 1, call 5 | miss |
| A40 | move haircut to tonight | **23:30** | I | Today 20:00; a day was said, so no roll (G:429, G:447): **Thu 15 20:00, in the past** | Reschedule Haircut, Fri 16 20:00 | R13d, call 5 | wrong write |

**Count A:** 40 rows. 17 wrong writes (A1 to A7, A11, A12, A16, A18, A24, A27, A30, A32, A33, A40), 10 misses (A8, A9, A15, A20, A23, A25, A26, A31, A38, A39), 13 OK guards.

**Rules for table A.** R13a and R13b are RC13 as written; the rest widen it.

- **R13a, day only keeps the time.** If only a day was said and the task has a time, keep its hour and minute. A task with no time gets 09:00, as today.
- **R13b, time only keeps the day.** If only a time was said and the task has a day, keep that day. With no day of its own, use today, and call 5 rolls a passed time to tomorrow.
- **R13c, bare number after `to` is an hour.** In a reschedule, a bare 1 to 12 after `to` is an hour, read by call 1 against the task's own day. This needs `extract` to report which parts were said and whether am/pm was given.
- **R13d, `tonight` is a time.** `tonight` sets both day and time (20:00), so R13a does not keep the old time. Call 5 applies when 20:00 has passed (A40).
- **R13e, never in the past.** After R13a, if the kept time is on today and has passed, use the next whole hour (master's "today" rule). Without this, A14 becomes today 10:00, in the past.
- **R13f, `next week`.** In a reschedule, `next week` moves the task 7 days, keeping its time. New captures with `next week` are Q3.
- **R13g, `later`.** `to later` moves the task to Later. `Parse.reschedule(task:to:)` needs `to: Date?` (nil means Later), mapped to `MoveTask(later: true)`.
- **R13h, no object.** If the phrase is a reschedule verb plus `to`/`till`/`until` and a date, with no task named, or `it`/`that`/`this`, return nil, never a task.
- **R13i, polite edges.** Strip a leading `can you`, `could you`, `please`, `tess` (with an optional comma) and a trailing `please` before the shape match.
- **R13j, past verb.** Accept `moved`, `pushed`, `shifted`, `rescheduled` in the shape, with the same meaning (Q5).

## Table B: time forms (RC11), 40 rows

| # | Phrase | Clock | Ctx | Master parse | Expected | Rule | Verdict |
|---|---|---|---|---|---|---|---|
| B1 | call mum 7 pm | 18:10 | I | `7` needs `at`; `pm` alone is not a time. Model | Task "Call mum", Thu 15 19:00 | R11a | miss |
| B2 | call mum at 7 pm | 18:10 | I | `at 7` is 07:00, passed; `pm` stays. **Task "Call mum pm", Fri 16 07:00** | Task "Call mum", Thu 15 19:00 | R11a | wrong write |
| B3 | call mum at 7:30 pm | 18:10 | I | **Task "Call mum pm", Fri 16 07:30** | Task "Call mum", Thu 15 19:30 | R11a | wrong write |
| B4 | call mum 7.30pm | 18:10 | I | `7.30pm` fails the time regex (G:470). Model | Task "Call mum", Thu 15 19:30 | R11b | miss |
| B5 | call mum 7:30pm | 18:10 | I | Task "Call mum", Thu 15 19:30 | Same | | OK |
| B6 | call mum at 7.30 | 18:10 | I | `at 7.30` fails; no date. Model | Task "Call mum", Thu 15 19:30 | R11b, call 1 | miss |
| B7 | dinner at 7.30 | 18:10 | I | Model | Task "Dinner", Thu 15 19:30 | R11b, call 1 | miss |
| B8 | dinner 7.30 | 18:10 | I | Model | Same. `H.MM` with no `at` and no am/pm stays a number (money) | R11b guard | OK |
| B9 | dentist at 4.15 | 18:10 | I | Model | Task "Dentist", Fri 16 16:15 (4 is PM; 16:15 passed today, so tomorrow) | R11b, call 1, call 5 | miss |
| B10 | call mum half 7 | 18:10 | I | Model | Task "Call mum", Thu 15 19:30 | R11c, call 1 | miss |
| B11 | call mum half past 7 | 18:10 | I | Model | Task "Call mum", Thu 15 19:30 | R11c, call 1 | miss |
| B12 | call mum quarter past 7 | 18:10 | I | Model | Task "Call mum", Thu 15 19:15 | R11c (widened) | miss |
| B13 | call mum half 6 | 18:10 | I | Model | Task "Call mum", Thu 15 18:30 (6 is PM, still ahead) | R11c, call 1 | miss |
| B14 | call mum half 5 | 18:10 | I | Model | Task "Call mum", Fri 16 17:30 (5 is PM, passed, so tomorrow) | R11c, call 1, call 5 | miss |
| B15 | call mum tonight at half 8 | 18:10 | I | `tonight` gives 20:00; `at half 8` is not read. **Task "Call mum at half 8", Thu 15 20:00** | Task "Call mum", Thu 15 20:30 | R11c | wrong write |
| B16 | call mum at 7 tonight | 18:10 | I | `at 7` is 07:00; `tonight` keeps it (G:409); a day was said, no roll. **Task "Call mum", Thu 15 07:00, in the past** | Task "Call mum", Thu 15 19:00 | call 1 (RC1 + RC9) | wrong write |
| B17 | call mum tmrw morning | 18:10 | I | `morning` stays in the title. **Task "Call mum morning", Fri 16 09:00** | Task "Call mum", Fri 16 09:00 | R11d | wrong write |
| B18 | dentist sat afternoon | 18:10 | I | `hasDate` drops `sat`, but `parseCook` and the task rule read it. **Task "Dentist afternoon", Sat 17 09:00** | Task "Dentist", Sat 17 14:00 | R11d | wrong write |
| B19 | call mum this evening | 18:10 | I | No date word. Model | Task "Call mum", Thu 15 19:00 (evening is under way, so the next whole hour) | R11d, R11e | miss (see Q6) |
| B20 | gym in the morning | 18:10 | I | Model | Task "Gym", Fri 16 09:00 | R11d, call 5 | miss |
| B21 | call mum in 2 hours | 18:10 | I | Lift: weight 2, no reps. No date. Model | Task "Call mum", Thu 15 20:10 | R11f | miss |
| B22 | call mum in 20 mins | 18:10 | I | Model (`timer` absent, K:75) | Task "Call mum", Thu 15 18:30 | R11f | miss |
| B23 | remind me in 2 hours to call mum | 18:10 | I | Explicit task, `to` is not first, no date. **Task "In 2 hours to call mum", Later** | Task "Call mum", Thu 15 20:10 | R11f, R11g | wrong write |
| B24 | remind me to call mum in an hour | 18:10 | I | **Task "Call mum in an hour", Later** | Task "Call mum", Thu 15 19:10 | R11f | wrong write |
| B25 | call mum at seven | 18:10 | I | Model | Task "Call mum", Thu 15 19:00 | R11h (or the spoken normaliser) | miss |
| B26 | call mum at noon | 18:10 | I | Noon passed: Task "Call mum", Fri 16 12:00 | Same | call 5 | OK |
| B27 | plank 2:30 | 18:10 | I | `2:30` is a time. **Task "Plank", Fri 16 02:30** | Model (a plank hold, never a task) | R11i | wrong write |
| B28 | rest 2:30 | 18:10 | W | Workout rule takes `rest 2…` (G:117): ignored in workout | Same | guard | OK |
| B29 | ran 5k in 22:30 | 18:10 | I | `22:30` is a time, still ahead. **Task "Ran 5k in", Thu 15 22:30** | Note "Ran 5k in 22:30", dated today. Never a task | call 2 (RC2 past verb runs first) | wrong write |
| B30 | paid 12.50 at 12.30 | 18:10 | I | Lift: reps 12.3, nil. `at 12.30` fails. Model | Model now (Money spend later). Never a task, even after R11b reads `at 12.30` | 4:34 PM call, R11b guard | OK |
| B31 | buy 2 x 6 rolls | 18:10 | I | Lift: "buy rolls" is no exercise. Groceries ["2 x 6 rolls"] | Same | guard (GC 27) | OK |
| B32 | buy 7up | 18:10 | I | `7up` is not a time (G:470). Groceries ["7up"] | Same | guard | OK |
| B33 | half 7 | 18:10 | W | Lift: weight 7, word `half`, no reps. Model | Same (no title, so no task even after R11c) | guard | OK |
| B34 | call mum at 7.30 | **09:00** | I | Model | Task "Call mum", Thu 15 19:30 (07:30 passed, 19:30 next) | R11b, call 1 | miss |
| B35 | call mum this afternoon | **09:00** | I | Model | Task "Call mum", Thu 15 14:00 | R11d | miss |
| B36 | call mum in the morning | **09:00** | I | Model | Task "Call mum", Fri 16 09:00 (today 09:00 is now, so passed) | R11d, call 5 | miss |
| B37 | call mum half 11 | **23:30** | I | Model | Task "Call mum", Fri 16 11:30 (11:30 and 23:30 have passed; 23:30 is now) | R11c, call 1, call 5 | miss |
| B38 | call mum tonight | **23:30** | I | Today 20:00; a day was said, no roll. **Task "Call mum", Thu 15 20:00, in the past** | Task "Call mum", Fri 16 20:00 | call 5 | wrong write (see Q7) |
| B39 | call mum in 2 hours | **23:30** | I | Model | Task "Call mum", Fri 16 01:30 | R11f | miss |
| B40 | call mum midnight | **23:30** | I | `midnight` is not a word `parseTime` knows. Model | Task "Call mum", Fri 16 00:00 | R11j | miss |

**Count B:** 40 rows. 11 wrong writes (B2, B3, B15 to B18, B23, B24, B27, B29, B38), 21 misses (B1, B4, B6, B7, B9 to B14, B19 to B22, B25, B34 to B37, B39, B40), 8 OK guards (B5, B8, B26, B28, B30 to B33; B8 and B30 must stay OK after R11b).

**Rules for table B.** R11a to R11d and R11i are RC11 as written; the rest widen it.

- **R11a, am/pm as its own word.** Join a number or `H:MM` and a following `am`/`pm` word into one time.
- **R11b, `H.MM`.** Read it as a time after `at`, or when it carries `am`/`pm` (`7.30pm`). Otherwise it stays a number, so `dinner 7.30`, `lunch 12.50` and money amounts are never times.
- **R11c, half and quarter.** `half H`, `half past H` are H:30; `quarter past H` is H:15; `quarter to H` is (H-1):45. With `at` in front too. Then call 1 picks am or pm.
- **R11d, part-of-day words.** `morning` 09:00, `afternoon` 14:00, `evening` 18:00, used only when no clock time is given. Drop `this`, `in the` before them. `sat morning` must also count for the short-weekday filter (RC10's flag).
- **R11e, part of day under way.** For today, if the part's default hour has passed but the part has not ended (morning until 12:00, afternoon until 17:00, evening until 23:00), use the next whole hour, not tomorrow (Q6).
- **R11f, relative times.** `in N min|mins|minutes|hour|hours|hr|hrs`, and `in an hour`, `in half an hour`: now plus that, not rounded.
- **R11g, explicit lead.** In `parseTask`, strip a leading `to` from what is left after `extract`, not only right after `remind me` (RC7's change).
- **R11h, number words.** `one` to `twelve` after `at`, or before `pm`/`am`/`o'clock`, are hours. The spoken normaliser spec may own this instead; one of the two must.
- **R11i, colon durations.** A `H:MM` with no `at` and no day word is not a time when the rest of the title is an exercise (RC11) or `rest`, `hold`, `plank`.
- **R11j, `midnight`.** 00:00 at the start of the next day.

## Rows that change today's behaviour

- **Wrong writes, 28:** A1 to A7, A11, A12, A16, A18, A24, A27, A30, A32, A33, A40; B2, B3, B15 to B18, B23, B24, B27, B29, B38. Of these, A40, B16 and B38 write a task in the past, and A12 sends a task a week off.
- **Misses, 31:** A8, A9, A15, A20, A23, A25, A26, A31, A38, A39; B1, B4, B6, B7, B9 to B14, B19 to B22, B25, B34 to B37, B39, B40.
- **Guards, 21:** must still pass after the batch. The ones most at risk: A14 (R13a without R13e lands in the past), A37 (R13c must not invent a task), B8 and B30 (R11b must not turn money into times), B33 (no title, so no task).

Rows that lean on a fix outside RC11 and RC13: A11 and B16 need RC1 (call 1); A33 needs RC5 b (call 4); B29 needs RC2 (call 2); B38 and A40 need the call 5 roll for `tonight`, which is RC9.

## Open questions

1. **Conflict: `thu 3pm` said on a Thursday after 3 PM (A12).** Master and `grammar-misfires.md` row 112 send it to next Thursday, from the code comment at G:437-438. Call 5 says any passed time today lands tomorrow, and the 18:58 call says `thu` on a Thursday is today. Read together, that is Fri 15:00, which is what A12 expects. Product should confirm, since this flips guard row 112.
2. **Bare hour on another day (A7, A11, call 1).** Call 1 speaks only of today. I read "the next one not yet passed" against the target day, so 7 to 11 are AM there. That makes `dinner tomorrow at 7` Fri 07:00, not the 19:00 that misfires row 105 wanted from a meal cue. Should cue words (`dinner`, `drinks`) still win?
3. **`next week` for a new capture.** For a reschedule (A23) a week on is natural. For `dentist next week` (no task yet), is it Mon 19 09:00, or Later with a note?
4. **`next fri` on a Thursday (A24).** Fri 16 or Fri 23? Still GC open question 4. A24 only fixes the time.
5. **`moved dentist to fri` (A32).** I treat it as a reschedule. Call 2 is about past days; here the day is ahead. If Product prefers the model, A32 becomes nil.
6. **Part of day already under way (B19, R11e).** At 18:10 `this evening` would roll to tomorrow 18:00 under call 5. I propose the next whole hour today instead. Same for `this morning` at 09:30.
7. **`tonight` said after 20:00 (B38, A40).** Call 5 gives tomorrow 20:00. The next whole hour (00:00) may read better before midnight. I followed call 5.
8. **`push dentist to later` (A26)** needs a `Parse` change (`to: Date?`). Is that in scope for this batch, or should A26 stay with the model?

## Swift Testing stubs

Two parameterized tables in `GrammarRulesTests`, sharing one fixture builder. `kind` strings as in `grammar-misfires.md`: `reschedule <Title> <EEE d HH:mm>`, `reschedule <Title> later`, `task <Title> <EEE d HH:mm>`, `task <Title> later`, `note <body> <EEE d>`, `groceries [a]`, `ignoredInWorkout`, `nil`.

```swift
enum Clock: Sendable { case morning0900, evening1810, late2330 } // Thu 15 Oct 2026, America/Los_Angeles
// 09:00 = 1_792_080_000, 18:10 = 1_792_113_000, 23:30 = 1_792_132_200 (seconds since 1970)
struct TimeRow: Sendable { let phrase: String; let clock: Clock; let ctx: Ctx; let expect: String }

/// Dentist Sat 10:00, Call mum, Clean the oven, Haircut today 17:00, Pay rent Fri 09:00,
/// Bins out today 21:00, Call dad Fri 12:00, Call bank (done).
func makeRescheduleFixtures() throws -> (TessGrammar, ObjectStore)

static let rescheduleRows: [TimeRow] = [
    .init("move dentist to fri", .evening1810, .idle, "reschedule Dentist Fri 16 10:00"),
    .init("move dentist to 3pm", .evening1810, .idle, "reschedule Dentist Sat 17 15:00"),
    .init("move dentist to 11", .evening1810, .idle, "reschedule Dentist Sat 17 11:00"),
    .init("move dentist to today", .evening1810, .idle, "reschedule Dentist Thu 15 19:00"), // guard
    .init("push to tmrw", .evening1810, .idle, "nil"),
    .init("move haircut to tonight", .late2330, .idle, "reschedule Haircut Fri 16 20:00"),
    // ... A1 to A40
]

static let timeFormRows: [TimeRow] = [
    .init("call mum 7 pm", .evening1810, .idle, "task Call mum Thu 15 19:00"),
    .init("dinner 7.30", .evening1810, .idle, "nil"), // guard
    .init("call mum half 5", .evening1810, .idle, "task Call mum Fri 16 17:30"),
    .init("remind me in 2 hours to call mum", .evening1810, .idle, "task Call mum Thu 15 20:10"),
    .init("call mum half 11", .late2330, .idle, "task Call mum Fri 16 11:30"),
    // ... B1 to B40
]

@Test(arguments: rescheduleRows) func rescheduleKeepsWhatWasNotSaid(_ row: TimeRow)
@Test(arguments: timeFormRows) func timeFormsAreRead(_ row: TimeRow)
@Test func noTaskIsEverWrittenInThePast()        // A40, B16, B38: every .task / .reschedule date > now
@Test func moneyAndSetShapesNeverBecomeTimes()   // B8, B30, B31, B32, A35, A36
@Test func rescheduleToLaterMovesToLater()       // A26, once Parse.reschedule takes Date?
@Test func isQuestionsNeverWrite()               // A33 (call 4)
```

`noTaskIsEverWrittenInThePast` is worth keeping separate: it runs every row of both tables at all three clocks and checks only that no dated write lands at or before `now`. It would have caught A40, B16 and B38 without anyone predicting them.
