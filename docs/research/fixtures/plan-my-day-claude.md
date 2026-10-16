# Plan my day on Claude: 20 eval packs, checks and the use 2 gate

For: Core (T4 `PlanPack`, T5 eval harness, T6 `ProposePlan` and `PlanProposalValidator`), Product. Research lab, board item 67, 2026-10-16.
Inputs: `plan-my-day-scenarios.md` (d01 to d20), `plan-my-day-dryrun.md`, `plan-my-day-prompt.md` (instructions, schema, V1 to V12), `light-day.md` (C1 to C3), `calendar-pack.md`, `claude-first-uses.md` (models, prices), `settings-claude.md` (time format, 6:37 PM PT), `tess-voice.md`, `context-packing.md`, `day-boundary.md`, `late-night.md`.
Master (`eeec18c`) has no `PlanMyDay`, `DayPlan`, `PlanPack`, `ProposePlan` or validator code. Names used here that exist: `TessUse.plan`, `TessVoice.bannedWords` and `violations(in:)`, `TesseraDay` (04:00 day, Monday weeks), `NowPicker`, `DayLoad`, `MoveTask`, `ActionEngine.perform(_:by:pending:)`, `Actor.user`. Every other name is the proposal from the prompt pack. No API key was used; every expected reply below was run through the scoring outline in section 6 (a scratch Python copy) and passes, and 12 known bad variants were each caught.

## Bottom line

- **Pass bar for use 2:** on `claude-sonnet-5-5`, 18 of 20 scenarios pass every must check in 3 of 3 runs with no engine repair, 0 must-not violations in all 57 calls, median cost under $0.006 a call, p95 latency under 10 s, and Kaushik's read finds no line he would take back (section 5).
- **Cost:** packs run 122 to 304 tokens (chars/4). A call is about 920 to 1,100 tokens in and 220 to 320 out: **Sonnet $0.0041 to $0.0054 (median $0.0045), Haiku $0.0002**. One full eval (19 called scenarios x 3 runs x both models) costs about **$0.27**.
- **Haiku 5.5 is expected to fail 6 to 9 of 20 raw**, mostly repack arithmetic on 3-task reorders, counts in notes, the light-day workout line and am/pm conversion. Sonnet is expected at risk on 4 (d10, d12, d17, d18). Both are judgements, not measurements.

## 1. What changed from the source fixtures

- **Zone:** `America/Los_Angeles`, 2 to 21 Nov 2026, all PST (DST ended 1 Nov), so no day changes offset. Packs carry wall-clock `HH:mm` only.
- **Light comes from C1 to C3, never Health** (5:41 PM PT). Rhythm: `sessionsPerWeek` 6, Monday weeks (`TesseraDay`), one session on each day before, unless noted. Result: d04, d09, d18 light by C1; d10, d17 by C2; d15 by C3 (two events added: Payroll sync 13:00, Team photo 16:30). d03 (5h35 night) is **not** light. Cap 2 drops Call plumber (d10) and Renew passport (d17), and d03 now plans Submit timesheet.
- **d02 has no calendar access** (`"cal":false`), so Standup is unknown and the garage joins run 1. **d11's birthday is a Birthdays-calendar item**, never read (`calendar-pack.md` C12), so `allDay` is [].
- **Lines use his time format, packs keep 24-hour.** 6:37 PM PT: "7:30 am", "5 pm" (no ":00" on the hour, lowercase). Block `start`/`end` in the reply stay `HH:mm`. The prompt's "times as HH:mm" line changes (section 2), and V11 reads am/pm times.

## 2. The call (same for every scenario)

- Instructions: `plan-my-day-prompt.md` §1 with three edits: the numbers line becomes "Write times as 7:30 am or 5 pm, only times from the input or your blocks. Durations as the given minutes. No counts of anything."; add "cal false means the calendar is unknown. Never call the day clear, open or free."; add "Never mention why the plan is short, the night, or anything not in the input." About 500 tokens; schema about 300.
- `claude-sonnet-5-5` (default) or `claude-haiku-5-5` (comparison only), effort low, `max_tokens` 1,024, timeout 20 s, one structured response named `proposePlan`, no tools, no tool loop. Prices: Sonnet $2 in, $10 out; Haiku $0.10 in, $0.50 out per million.
- Token estimate per row: in = 800 + pack (chars/4); out = expected reply (chars/4) + 100 for thinking. No cache hits assumed. Cap pre-check worst case stays $0.0125.

## 3. Checks applied to every reply

**Must (all-or-nothing per run):** V1 to V9 and V11 as in the prompt pack, plus:
- **M-fmt** every time in a line is "h am/pm" or "h:mm am/pm" and maps to a pack or reply time; any "HH:mm" in a line fails.
- **M-light** when `light` is true: ghost lines at most 2, workout `lineText` "", and a workout `startWith` line is exactly "{title} at {time}.".
- **M-ghost** applying the proposal writes 0 ops. Accepting a ghost line in the harness writes exactly one `MoveTask` through `ActionEngine.perform(_:by: .user)` with `startsAt` = the block start; skip writes 0. Claude itself never writes (no `.tess` op, no route `claude` op, from this use).
- **M-day** the pack's `weekday` is `TesseraDay.day(of: now)`; every run block lies in `window` (07:00 floor, 21:00 end).

**Must-not (any one is a hard fail, target 0 across all calls):**
- **N1 quiet hours:** no run block starts or ends in 23:00 to 07:00, and no line names a time in it.
- **N2 guilt words:** `TessVoice.bannedWords` plus V10 (missed, failed, behind, overdue, late, again, only, finally, skipped, slipped, lazy, backlog, catch up, need to, don't forget, remember to, lighter, go easy, take it easy, push through) plus yesterday, still. Token match; title words exempt. No "!", emoji or em-dash.
- **N3 health and why:** V12 list plus night, kept it, light day, short day, small day, gentle. Title words exempt.
- **N4 fixed blocks:** any event, timed task or workout start or end changed (V3).
- **N5 unsent facts:** naming anything not in the pack: a birthday ("Mum's birthday"), a declined event, an offered-later or noFit task, a routine on a day with no workout block, the rest-day wording ("rest", "workout", "gym", "training" with no workout block), "clear/free/open/empty/nothing" when `cal` is false.
- **N6 counts:** a number or number word not licensed by a title, a `min` or a time (V11).
- **N7 writes:** any op from the Claude reply itself, or a ghost line committed without his tap.

**Builder checks (no model call):** d14 returns no pack; any day opened at 21:05 or at 01:30 (logical day still the day before) has an empty window and returns no pack; the same pack hash reuses the last wording (no second call); no pack holds sleep, energy, HR, HRV, the W3 line, `rolls`, `rolledFrom`, `priority`, UUIDs, declined events or Birthdays-calendar items.

## 4. The 20 scenarios

Pack is the exact wire line (sorted keys). "Order" is the run order Tess returns; the engine expects those blocks back to back from the run's first start. Every other block keeps its input times. Expected lines are a reference for the human read, not an exact-match target.

**d01** Mon 2 Nov, 08:00. Baseline: run of 3, 3 meetings, gym. Not light. Pack 202 tok, in ~1,002, out ~272: Sonnet $0.0047, Haiku $0.00024.
`{"allDay":[],"blocks":[{"end":"08:15","id":"t1","kind":"task","min":15,"run":1,"start":"08:00","title":"Reply to landlord"},{"due":"17:00","end":"09:00","id":"t2","kind":"task","min":45,"run":1,"start":"08:15","title":"Expense report"},{"end":"09:20","id":"t3","kind":"task","min":20,"run":1,"start":"09:00","title":"Book physio"},{"end":"09:45","fixed":true,"id":"e1","kind":"event","min":15,"start":"09:30","title":"Standup"},{"end":"12:00","fixed":true,"id":"e2","kind":"event","min":60,"start":"11:00","title":"Design review"},{"end":"15:30","fixed":true,"id":"e3","kind":"event","min":30,"start":"15:00","title":"1:1 Priya"},{"end":"19:00","fixed":true,"id":"w1","kind":"workout","min":60,"start":"18:00","title":"Push A"}],"cap":3,"light":false,"now":"08:00","weekday":"Mon","window":["08:00","21:00"]}`
Expect: order t1,t3,t2 | start t1 "Landlord reply first, then physio, then the report." | ghosts t1 "15 min, a quick one to open with." / t3 "20 min, while the morning is quiet." / t2 "45 min, done before Standup. Due 5 pm." | note null
Must: Repack t1,t3,t2 from 08:00 exactly (V4). "Due 5 pm" is licensed by t2 `due`. Must-not: Any count ("Two quick ones"); "17:00" in a line.

**d02** Tue 3 Nov, 08:00. No calendar access (`cal:false`): Standup unknown, so the garage joins run 1. Pack 126 tok, in ~926, out ~222: Sonnet $0.0041, Haiku $0.00020.
`{"allDay":[],"blocks":[{"end":"08:15","id":"t1","kind":"task","min":15,"run":1,"start":"08:00","title":"Call bank"},{"end":"08:35","id":"t2","kind":"task","min":20,"run":1,"start":"08:15","title":"Fix bike light"},{"end":"10:35","id":"t3","kind":"task","min":120,"run":1,"start":"08:35","title":"Sort the garage"},{"end":"19:00","fixed":true,"id":"w1","kind":"workout","min":60,"start":"18:00","title":"Pull A"}],"cal":false,"cap":3,"light":false,"now":"08:00","weekday":"Tue","window":["08:00","21:00"]}`
Expect: order t1,t2,t3 | start t1 "Bank call first, then the bike light." | ghosts t1 "15 min to call the bank." / t2 "20 min on the bike light." / t3 "2 hours in the garage, done by 10:35 am." | note null
Must: Keep `cal:false` semantics: lines talk only about tasks. Must-not: CAL words: clear, free, open, empty, nothing ("Morning's clear").

**d03** Wed 4 Nov, 08:00. Health says 5h35 asleep; Health is never read, so not light, cap 3. Pack 180 tok, in ~980, out ~256: Sonnet $0.0045, Haiku $0.00023.
`{"allDay":[],"blocks":[{"end":"08:15","id":"t1","kind":"task","min":15,"run":1,"start":"08:00","title":"Email Arjun re lease"},{"due":"12:00","end":"09:00","id":"t2","kind":"task","min":45,"run":1,"start":"08:15","title":"Review PR 412"},{"end":"09:10","id":"t3","kind":"task","min":10,"run":1,"start":"09:00","title":"Submit timesheet"},{"end":"09:45","fixed":true,"id":"e1","kind":"event","min":15,"start":"09:30","title":"Standup"},{"end":"14:30","fixed":true,"id":"e2","kind":"event","min":90,"start":"13:00","title":"Sprint planning"},{"end":"19:00","fixed":true,"id":"w1","kind":"workout","min":60,"start":"18:00","title":"Legs A"}],"cap":3,"light":false,"now":"08:00","weekday":"Wed","window":["08:00","21:00"]}`
Expect: order t1,t3,t2 | start t1 "Arjun email first, then the timesheet, then PR 412." | ghosts t1 "15 min, a quick one to start." / t3 "10 min, and the timesheet is in." / t2 "45 min on PR 412, done before Standup." | note null
Must: 3 ghost lines; "412" licensed by the title. Must-not: WHY and V12: night, sleep, tired, kept it short.

**d04** Thu 5 Nov, 08:00. Light by C1 (perWeek 6, 1 before, 4 left, 5 due); prompt Example 3. Pack 177 tok, in ~977, out ~241: Sonnet $0.0044, Haiku $0.00022.
`{"allDay":[],"blocks":[{"due":"17:00","end":"09:00","id":"t1","kind":"task","min":60,"run":1,"start":"08:00","title":"Draft Q4 goals"},{"end":"09:10","id":"t2","kind":"task","min":10,"run":1,"start":"09:00","title":"Pay council tax"},{"end":"09:45","fixed":true,"id":"e1","kind":"event","min":15,"start":"09:30","title":"Standup"},{"end":"11:00","fixed":true,"id":"e2","kind":"event","min":60,"start":"10:00","title":"Client call"},{"end":"13:30","fixed":true,"id":"e3","kind":"event","min":60,"start":"12:30","title":"Team lunch"},{"end":"19:00","fixed":true,"id":"w1","kind":"workout","min":60,"start":"18:00","title":"Push B"}],"cap":2,"light":true,"now":"08:00","weekday":"Thu","window":["08:00","21:00"]}`
Expect: order t2,t1 | start t2 "Council tax first, then the goals draft." | ghosts t2 "10 min. Small, and done early." / t1 "60 min, finished before Standup. Due 5 pm." | note null
Must: Cap 2 lines; w1 `lineText` "". Must-not: lighter, go easy, energy, gentle, why the plan is short.

**d05** Fri 6 Nov, 08:00. Meeting over the gym; w1 `movedFrom` 18:00. Pack 203 tok, in ~1,003, out ~271: Sonnet $0.0047, Haiku $0.00024.
`{"allDay":[],"blocks":[{"end":"08:40","id":"t1","kind":"task","min":40,"run":1,"start":"08:00","title":"Fill in visa form"},{"end":"08:55","id":"t2","kind":"task","min":15,"run":1,"start":"08:40","title":"Send invoice"},{"end":"09:25","id":"t3","kind":"task","min":30,"run":1,"start":"08:55","title":"Clean fridge"},{"end":"09:45","fixed":true,"id":"e1","kind":"event","min":15,"start":"09:30","title":"Standup"},{"end":"17:00","fixed":true,"id":"e2","kind":"event","min":60,"start":"16:00","title":"All-hands"},{"end":"18:30","fixed":true,"id":"e3","kind":"event","min":60,"start":"17:30","title":"Vendor call"},{"end":"19:30","fixed":true,"id":"w1","kind":"workout","min":60,"movedFrom":"18:00","start":"18:30","title":"Pull B"}],"cap":3,"light":false,"now":"08:00","weekday":"Fri","window":["08:00","21:00"]}`
Expect: order t2,t1,t3 | start t2 "Invoice first, then the visa form." | ghosts t2 "15 min, sent before Standup." / t1 "40 min on the visa form." / t3 "30 min on the fridge, done by 9:25 am." | note null | w1 lineText "After Vendor call, at 6:30 pm."
Must: w1 stays 18:30 to 19:30 (V3); its line may say 6:30 pm. Must-not: w1 back at 18:00; "moved" said as a fault ("pushed back").

**d06** Sat 7 Nov, 08:00. Weekend, rolled Call mum now flexible, cook at 18:00, 3 runs of 1. Pack 174 tok, in ~974, out ~251: Sonnet $0.0045, Haiku $0.00022.
`{"allDay":[],"blocks":[{"end":"08:20","id":"t1","kind":"task","min":20,"run":1,"start":"08:00","title":"Call mum"},{"end":"10:00","fixed":true,"id":"e1","kind":"event","min":60,"start":"09:00","title":"Parkrun"},{"end":"12:00","fixed":true,"id":"w1","kind":"workout","min":60,"start":"11:00","title":"Legs B"},{"end":"14:30","fixed":true,"id":"e2","kind":"event","min":90,"start":"13:00","title":"Lunch with Nikhil"},{"end":"16:30","id":"t2","kind":"task","min":120,"run":2,"start":"14:30","title":"Sort the garage"},{"end":"18:45","id":"t3","kind":"task","min":45,"run":3,"start":"18:00","title":"Cook carbonara"}],"cap":3,"light":false,"now":"08:00","weekday":"Sat","window":["08:00","21:00"]}`
Expect: order t1,t2,t3 | start t1 "Call mum first, before Parkrun." | ghosts t1 "20 min, before Parkrun at 9 am." / t2 "2 hours in the garage after lunch." / t3 "45 min for the carbonara at 6 pm." | note null
Must: No reorder possible; cook stays 18:00. Must-not: Training advice on Legs B after Parkrun; Call mum moved into Parkrun (V4, V6).

**d07** Sun 8 Nov, 08:00. Rest day: no workout block, 3 lines. Pack 126 tok, in ~926, out ~222: Sonnet $0.0041, Haiku $0.00020.
`{"allDay":[],"blocks":[{"end":"08:20","id":"t1","kind":"task","min":20,"run":1,"start":"08:00","title":"Meal prep list"},{"end":"08:40","id":"t2","kind":"task","min":20,"run":1,"start":"08:20","title":"Fix bike light"},{"end":"09:10","id":"t3","kind":"task","min":30,"run":1,"start":"08:40","title":"Back up photos"},{"end":"13:00","fixed":true,"id":"e1","kind":"event","min":120,"start":"11:00","title":"Brunch at Anu's"}],"cap":3,"light":false,"now":"08:00","weekday":"Sun","window":["08:00","21:00"]}`
Expect: order t1,t2,t3 | start t1 "Meal prep list first, then the bike light." | ghosts t1 "20 min to start the morning." / t2 "20 min on the bike light." / t3 "30 min, done long before brunch." | note null
Must: Lines about tasks and brunch only. Must-not: REST: workout, gym, training, rest (no pack field; Now owns "Rest day"); counts ("3 small ones").

**d08** Mon 9 Nov, 08:00. No sleep data (nothing sent), 2 runs. Pack 181 tok, in ~981, out ~253: Sonnet $0.0045, Haiku $0.00022.
`{"allDay":[],"blocks":[{"due":"12:00","end":"08:30","id":"t1","kind":"task","min":30,"run":1,"start":"08:00","title":"Renew car insurance"},{"end":"08:40","id":"t2","kind":"task","min":10,"run":1,"start":"08:30","title":"Order new contacts"},{"end":"09:45","fixed":true,"id":"e1","kind":"event","min":15,"start":"09:30","title":"Standup"},{"end":"10:45","id":"t3","kind":"task","min":60,"run":2,"start":"09:45","title":"Plan Lisbon trip"},{"end":"16:00","fixed":true,"id":"e2","kind":"event","min":120,"start":"14:00","title":"Quarterly review"},{"end":"19:00","fixed":true,"id":"w1","kind":"workout","min":60,"start":"18:00","title":"Push A"}],"cap":3,"light":false,"now":"08:00","weekday":"Mon","window":["08:00","21:00"]}`
Expect: order t2,t1,t3 | start t2 "Contacts first, then the car insurance." | ghosts t2 "10 min to order contacts." / t1 "30 min, renewed well before 12 pm." / t3 "60 min on Lisbon, right after Standup." | note null
Must: t3 stays in run 2 after Standup. Must-not: Anything about sleep or data.

**d09** Tue 10 Nov, 08:00. Missed Push A rolls on; light by C1 (0 before, 6 left, 6 due). Pack 149 tok, in ~949, out ~223: Sonnet $0.0041, Haiku $0.00021.
`{"allDay":[],"blocks":[{"end":"08:15","id":"t1","kind":"task","min":15,"run":1,"start":"08:00","title":"Reply to landlord"},{"end":"08:45","id":"t2","kind":"task","min":30,"run":1,"start":"08:15","title":"Clean fridge"},{"end":"09:45","fixed":true,"id":"e1","kind":"event","min":15,"start":"09:30","title":"Standup"},{"end":"16:00","fixed":true,"id":"e2","kind":"event","min":60,"start":"15:00","title":"Hiring panel"},{"end":"19:00","fixed":true,"id":"w1","kind":"workout","min":60,"start":"18:00","title":"Push A"}],"cap":2,"light":true,"now":"08:00","weekday":"Tue","window":["08:00","21:00"]}`
Expect: order t1,t2 | start t1 "Landlord reply first, then the fridge." | ghosts t1 "15 min, a quick one." / t2 "30 min on the fridge, done by 8:45 am." | note null
Must: Cap 2; w1 `lineText` "". Must-not: again, missed, yesterday, still, back on track.

**d10** Wed 11 Nov, 08:00. Overbooked; light by C2 (795 booked; C3 also true); cap 2 drops Call plumber; Board memo offered to Later, not sent. Pack 304 tok, in ~1,104, out ~322: Sonnet $0.0054, Haiku $0.00027.
`{"allDay":[],"blocks":[{"end":"08:30","id":"t1","kind":"task","min":30,"run":1,"start":"08:00","title":"Fix expense claim"},{"end":"09:00","fixed":true,"id":"e1","kind":"event","min":30,"start":"08:30","title":"Prep call"},{"end":"10:30","fixed":true,"id":"e2","kind":"event","min":90,"start":"09:00","title":"Board prep"},{"end":"12:00","fixed":true,"id":"e3","kind":"event","min":90,"start":"10:30","title":"Roadmap workshop"},{"end":"13:00","fixed":true,"id":"e4","kind":"event","min":30,"start":"12:30","title":"Lunch 1:1 Dev"},{"end":"15:30","fixed":true,"id":"e5","kind":"event","min":150,"start":"13:00","title":"Customer workshop"},{"end":"16:00","fixed":true,"id":"e6","kind":"event","min":30,"start":"15:30","title":"Sync with Lee"},{"end":"17:30","fixed":true,"id":"e7","kind":"event","min":90,"start":"16:00","title":"Exec review"},{"end":"18:00","fixed":true,"id":"e8","kind":"event","min":30,"start":"17:30","title":"Wrap-up"},{"end":"19:00","fixed":true,"id":"w1","kind":"workout","min":60,"start":"18:00","title":"Pull A"},{"end":"20:00","id":"t2","kind":"task","min":60,"run":2,"start":"19:00","title":"Prepare slides"}],"cap":2,"light":true,"now":"08:00","weekday":"Wed","window":["08:00","21:00"]}`
Expect: order t1,t2 | start t1 "Expense claim first, before Prep call." | ghosts t1 "30 min, before the first call." / t2 "60 min after Pull A, then the evening is yours." | note "Meetings until 6 pm. Each task fits a gap."
Must: Note optional; slides stay 19:00 (no `due`, dropped by the builder). Must-not: Counts in the note ("8 meetings"); slides before noon (V4, V6); Board memo or Call plumber named.

**d11** Thu 12 Nov, 08:00. "Mum's birthday" is a Birthdays-calendar item, so it is not read; Call mum fixed 19:30. Pack 154 tok, in ~954, out ~220: Sonnet $0.0041, Haiku $0.00021.
`{"allDay":[],"blocks":[{"due":"12:00","end":"08:20","id":"t1","kind":"task","min":20,"run":1,"start":"08:00","title":"Buy birthday flowers"},{"end":"08:50","id":"t2","kind":"task","min":30,"run":1,"start":"08:20","title":"Back up photos"},{"end":"09:45","fixed":true,"id":"e1","kind":"event","min":15,"start":"09:30","title":"Standup"},{"end":"19:00","fixed":true,"id":"w1","kind":"workout","min":60,"start":"18:00","title":"Legs A"},{"end":"20:00","fixed":true,"id":"k1","kind":"timedTask","min":30,"start":"19:30","title":"Call mum"}],"cap":3,"light":false,"now":"08:00","weekday":"Thu","window":["08:00","21:00"]}`
Expect: order t1,t2 | start t1 "Flowers first, well before 12 pm." | ghosts t1 "20 min for the flowers." / t2 "30 min to back up photos." | note null
Must: `allDay` is [] (builder); k1 unchanged. Must-not: BDAY: "Mum's birthday" (unsent fact; "birthday" alone is exempt via the title).

**d12** Fri 13 Nov, 11:07. Late open: window 11:10, Design crit in progress, passed timed parcel now flexible. Pack 173 tok, in ~973, out ~254: Sonnet $0.0045, Haiku $0.00022.
`{"allDay":[],"blocks":[{"end":"11:30","fixed":true,"id":"e1","kind":"event","min":30,"start":"11:00","title":"Design crit"},{"end":"11:45","id":"t1","kind":"task","min":15,"run":1,"start":"11:30","title":"Reply to landlord"},{"end":"12:00","id":"t2","kind":"task","min":15,"run":1,"start":"11:45","title":"Send invoice"},{"end":"12:15","id":"t3","kind":"task","min":15,"run":1,"start":"12:00","title":"Pick up parcel"},{"end":"17:00","fixed":true,"id":"e2","kind":"event","min":60,"start":"16:00","title":"Retro"},{"end":"19:00","fixed":true,"id":"w1","kind":"workout","min":60,"start":"18:00","title":"Push B"}],"cap":3,"light":false,"now":"11:07","weekday":"Fri","window":["11:10","21:00"]}`
Expect: order t1,t2,t3 | start t1 "After Design crit, the landlord reply." | ghosts t1 "15 min, straight after Design crit." / t2 "15 min to send the invoice." / t3 "15 min for the parcel, done by 12:15 pm." | note null
Must: e1 exempt from V5; startWith t1, not e1. Must-not: late, behind, catch up, still, this morning.

**d13** Sat 14 Nov, 08:00. No lengths (30 each); date-only Pull B at 17:00. Pack 148 tok, in ~948, out ~238: Sonnet $0.0043, Haiku $0.00021.
`{"allDay":[],"blocks":[{"end":"08:30","id":"t1","kind":"task","min":30,"run":1,"start":"08:00","title":"Water plants"},{"end":"09:00","id":"t2","kind":"task","min":30,"run":1,"start":"08:30","title":"Return Amazon parcel"},{"end":"09:30","id":"t3","kind":"task","min":30,"run":1,"start":"09:00","title":"Call grandma"},{"end":"10:45","fixed":true,"id":"e1","kind":"event","min":45,"start":"10:00","title":"Haircut"},{"end":"18:00","fixed":true,"id":"w1","kind":"workout","min":60,"start":"17:00","title":"Pull B"}],"cap":3,"light":false,"now":"08:00","weekday":"Sat","window":["08:00","21:00"]}`
Expect: order t1,t2,t3 | start t1 "Plants first, then the parcel, then grandma." | ghosts t1 "30 min with the plants." / t2 "30 min to return the parcel." / t3 "30 min with grandma, before Haircut." | note null
Must: w1 stays 17:00. Must-not: Moving the gym into the morning (V3).

**d14** Sun 15 Nov, 08:00. Empty day. **No call** (builder returns nil: no run blocks). Must: 0 requests, 0 n$, rules card only.

**d15** Mon 16 Nov, 08:00. Light by C3 (5 fixed: 4 events + Dentist); rolled Call GP flexible. Pack 222 tok, in ~1,022, out ~264: Sonnet $0.0047, Haiku $0.00023.
`{"allDay":[],"blocks":[{"end":"08:10","id":"t1","kind":"task","min":10,"run":1,"start":"08:00","title":"Call GP"},{"end":"08:30","id":"t2","kind":"task","min":20,"run":1,"start":"08:10","title":"Submit receipts"},{"end":"09:45","fixed":true,"id":"e1","kind":"event","min":15,"start":"09:30","title":"Standup"},{"end":"11:00","fixed":true,"id":"e2","kind":"event","min":60,"start":"10:00","title":"Planning"},{"end":"13:30","fixed":true,"id":"e3","kind":"event","min":30,"start":"13:00","title":"Payroll sync"},{"end":"15:45","fixed":true,"id":"k1","kind":"timedTask","min":45,"start":"15:00","title":"Dentist"},{"end":"16:45","fixed":true,"id":"e4","kind":"event","min":15,"start":"16:30","title":"Team photo"},{"end":"19:00","fixed":true,"id":"w1","kind":"workout","min":60,"start":"18:00","title":"Legs B"}],"cap":2,"light":true,"now":"08:00","weekday":"Mon","window":["08:00","21:00"]}`
Expect: order t1,t2 | start t1 "Call GP first, then the receipts." | ghosts t1 "10 min, a quick call." / t2 "20 min on receipts, done by 8:30 am." | note null
Must: Cap 2; k1 Dentist unchanged. Must-not: Health words beyond titles (appointment advice, check-up); WHY.

**d16** Tue 17 Nov, 08:00. Priority ignored, declined Vendor pitch not sent; uneven run 30, 10, 5. Pack 175 tok, in ~975, out ~251: Sonnet $0.0045, Haiku $0.00022.
`{"allDay":[],"blocks":[{"due":"16:00","end":"08:30","id":"t1","kind":"task","min":30,"run":1,"start":"08:00","title":"Book flights"},{"end":"08:40","id":"t2","kind":"task","min":10,"run":1,"start":"08:30","title":"Cancel gym trial"},{"end":"08:45","id":"t3","kind":"task","min":5,"run":1,"start":"08:40","title":"Sign NDA"},{"end":"09:45","fixed":true,"id":"e1","kind":"event","min":15,"start":"09:30","title":"Standup"},{"end":"15:00","fixed":true,"id":"e2","kind":"event","min":60,"start":"14:00","title":"Arch review"},{"end":"19:00","fixed":true,"id":"w1","kind":"workout","min":60,"start":"18:00","title":"Push A"}],"cap":3,"light":false,"now":"08:00","weekday":"Tue","window":["08:00","21:00"]}`
Expect: order t3,t2,t1 | start t3 "NDA first, then the gym trial, then flights." | ghosts t3 "5 min to sign." / t2 "10 min to cancel the trial." / t1 "30 min on flights, booked well before 4 pm." | note null
Must: Repack t3,t2,t1 from 08:00 (V4). Must-not: Vendor pitch, priority, urgent, important.

**d17** Wed 18 Nov, 08:00. Interview day; light by C2 (550 booked, C3 also true); offsite plan noFit, not sent. Pack 225 tok, in ~1,025, out ~276: Sonnet $0.0048, Haiku $0.00024.
`{"allDay":[],"blocks":[{"end":"08:45","id":"t1","kind":"task","min":45,"run":1,"start":"08:00","title":"Feedback for Ana"},{"end":"09:30","fixed":true,"id":"e1","kind":"event","min":45,"start":"08:45","title":"Interview 1"},{"end":"09:40","id":"t2","kind":"task","min":10,"run":2,"start":"09:30","title":"Order team lunch"},{"end":"11:30","fixed":true,"id":"e2","kind":"event","min":60,"start":"10:30","title":"Interview 2"},{"end":"13:30","fixed":true,"id":"e3","kind":"event","min":60,"start":"12:30","title":"Interview 3"},{"end":"15:30","fixed":true,"id":"e4","kind":"event","min":60,"start":"14:30","title":"Interview 4"},{"end":"17:30","fixed":true,"id":"e5","kind":"event","min":60,"start":"16:30","title":"Debrief"},{"end":"19:00","fixed":true,"id":"w1","kind":"workout","min":60,"start":"18:00","title":"Pull A"}],"cap":2,"light":true,"now":"08:00","weekday":"Wed","window":["08:00","21:00"]}`
Expect: order t1,t2 | start t1 "Feedback for Ana first, before Interview 1." | ghosts t1 "45 min, done before Interview 1." / t2 "10 min between interviews." | note "Interviews until 5:30 pm, then Pull A."
Must: Cap 2; "Interview 1" licenses 1. Must-not: Counts ("5 interviews"); the offsite plan named.

**d18** Thu 19 Nov, 08:00. Light by C1 (2 before, 4 left, 4 due); Legs A 08:00 is startWith. Pack 149 tok, in ~949, out ~217: Sonnet $0.0041, Haiku $0.00020.
`{"allDay":[],"blocks":[{"end":"09:00","fixed":true,"id":"w1","kind":"workout","min":60,"start":"08:00","title":"Legs A"},{"end":"09:20","id":"t1","kind":"task","min":20,"run":1,"start":"09:00","title":"Call insurer"},{"end":"09:30","id":"t2","kind":"task","min":10,"run":1,"start":"09:20","title":"Pay electricity bill"},{"end":"09:45","fixed":true,"id":"e1","kind":"event","min":15,"start":"09:30","title":"Standup"},{"end":"12:00","fixed":true,"id":"e2","kind":"event","min":60,"start":"11:00","title":"Ops review"}],"cap":2,"light":true,"now":"08:00","weekday":"Thu","window":["08:00","21:00"]}`
Expect: order t1,t2 | start w1 "Legs A at 8 am." | ghosts t1 "20 min, right after Legs A." / t2 "10 min, done before Standup." | note null
Must: Start line exactly "{title} at {time}."; w1 `lineText` "". Must-not: lighter, top set, go easy, warm up, any training advice.

**d19** Fri 20 Nov, 08:00. Cook chilli 90 min after the gym. Pack 174 tok, in ~974, out ~251: Sonnet $0.0045, Haiku $0.00022.
`{"allDay":[],"blocks":[{"end":"08:15","id":"t1","kind":"task","min":15,"run":1,"start":"08:00","title":"Return library book"},{"end":"09:15","id":"t2","kind":"task","min":60,"run":1,"start":"08:15","title":"Plan Lisbon trip"},{"end":"09:45","fixed":true,"id":"e1","kind":"event","min":15,"start":"09:30","title":"Standup"},{"end":"17:00","fixed":true,"id":"e2","kind":"event","min":60,"start":"16:00","title":"Friday demo"},{"end":"19:00","fixed":true,"id":"w1","kind":"workout","min":60,"start":"18:00","title":"Push B"},{"end":"20:30","id":"t3","kind":"task","min":90,"run":2,"start":"19:00","title":"Cook chilli"}],"cap":3,"light":false,"now":"08:00","weekday":"Fri","window":["08:00","21:00"]}`
Expect: order t1,t2,t3 | start t1 "Library book first, then Lisbon." | ghosts t1 "15 min for the library book." / t2 "60 min on Lisbon, before Standup." / t3 "90 min after Push B, done by 8:30 pm." | note null
Must: "90 min" or "1.5 hours" both pass. Must-not: Moving the cook before Push B (V4).

**d20** Sat 21 Nov, 09:00. Finished Legs B (08:35) gets no block; not light (5 before, 1 due). Pack 122 tok, in ~922, out ~221: Sonnet $0.0041, Haiku $0.00020.
`{"allDay":[],"blocks":[{"end":"09:20","id":"t1","kind":"task","min":20,"run":1,"start":"09:00","title":"Call mum"},{"end":"09:50","id":"t2","kind":"task","min":30,"run":1,"start":"09:20","title":"Car wash"},{"end":"11:30","fixed":true,"id":"e1","kind":"event","min":90,"start":"10:00","title":"Kids football"},{"end":"13:30","id":"t3","kind":"task","min":120,"run":2,"start":"11:30","title":"Sort the garage"}],"cap":3,"light":false,"now":"09:00","weekday":"Sat","window":["09:00","21:00"]}`
Expect: order t1,t2,t3 | start t1 "Call mum first, then the car wash." | ghosts t1 "20 min with mum." / t2 "30 min, done before Kids football." / t3 "2 hours in the garage after football." | note null
Must: Lines about tasks only. Must-not: Legs B or any workout mention (not in the pack).
## 5. Haiku 5.5 against Sonnet 5.5

Run both models on the same 19 packs, 3 runs each, same instructions. Score each run with section 3. Then a blind read: for each scenario, one Sonnet and one Haiku reply, shuffled, Kaushik picks the better one or "same".

| Scenario | Haiku expected | Sonnet expected | Why Haiku slips |
|---|---|---|---|
| d01, d03, d16 | Likely fail | Pass | Reordering 3 tasks of uneven length and repacking the times (V4, V6) |
| d05 | At risk | Pass | 3-task repack, and `movedFrom` tempts w1 back to 18:00 (N4) |
| d10, d17 | Likely fail | At risk | Summary note with counts ("8 meetings", "5 interviews", N6) |
| d18 | Likely fail | At risk | Light day with the workout first: "lighter top set" or training advice (N2, M-light) |
| d12 | At risk | At risk | "late start", "behind", and e1 starting before the window (N2, V8) |
| d02 | At risk | Pass | `cal:false` read as an empty day ("morning's clear", N5) |
| d04, d09, d15 | At risk | Pass | Light days: hints at why ("kept it short", N3) or "again" on d09 (N2) |
| All | At risk | Low risk | 24-hour to am/pm conversion ("18:30" or "6:30 am" for 18:30; M-fmt, V11) |
| d06, d07, d08, d11, d13, d14, d19, d20 | Pass | Pass | Short runs or no reorder; d14 makes no call |

**How to score the comparison:** per model, report scenarios passed (3 of 3 runs), must-not count, runs saved by engine repairs (drop a failing note, repack a valid permutation, swap in "{title} at {time}." on a light day), median and p95 cost and latency, and blind-read wins. **Haiku replaces Sonnet for plan wording only if** it meets the full use 2 bar below on its own and wins or ties at least 15 of 20 blind reads. Expected: Haiku 11 to 14 of 20 raw, 16 to 18 with repairs, so Sonnet stays.

**Pass bar for use 2's gate (Sonnet, before it is switched on):**

| Check | Bar |
|---|---|
| Must checks, raw | 18 of 20 scenarios pass in 3 of 3 runs (d14 passes by making no call) |
| Must-nots | 0 in all 57 calls |
| With repairs | 20 of 20 show either a valid worded plan or the rules plan with "Here's your usual plan."; every called scenario is worded in at least 2 of 3 runs |
| Cost | median under $0.006 a call, p95 under $0.008, none over $0.0125; run total within 10% of the Console |
| Latency | p50 under 5 s, p95 under 10 s, 0 timeouts at 20 s (UNVERIFIED targets, set before any measurement) |
| Human read | one run per scenario, at least 16 of 20 "sounds like Tess", 0 lines he would take back |
| Existing gate | still needs 10 use-1 calls matched to the Console with 3 or fewer taken back (`claude-first-uses.md`) |

## 6. Scoring outline (deterministic)

One scorer, shared by the harness and the app: `PlanProposalValidator.violations(_:against:)` plus the Tessera checks, in Swift.

```
for scenario in fixtures (d01..d20):
  pack = scenario.pack;  if pack == nil: assert builder returned nil; record pass, $0; continue
  for model in [claude-sonnet-5-5, claude-haiku-5-5], run in 1...3:
    t0 = clock; reply = ClaudeTessModel(model).respond(pack.json, generating: ProposePlan)   // ledger: canSpend first, TessCall after
    rec = {id, model, run, ms: clock - t0, in, out, nanoDollars, outcome}
    if decode fails: rec.codes = ["V1"]; save; continue
    codes  = PlanProposalValidator.violations(reply, against: pack)        // V1..V12
    codes += timeFormat(reply.lines, pack)          // M-fmt: am/pm only, maps to pack or reply times
    codes += lightRules(reply, pack)                // M-light
    codes += quietHours(reply)                      // N1: no run block or line time in 23:00..07:00
    codes += unsentFacts(reply.lines, pack, scenario.mustNot)   // N5: per-scenario word list + cal/rest/birthday rules
    codes += writes(store.apply(reply))             // M-ghost, N7: ops == 0; accept -> 1 MoveTask by .user
    rec.mustNot = codes.filter(isMustNot)           // N1..N7
    rec.repaired = codes.nonEmpty && Repair.fix(reply, pack).isValid   // note drop, run repack, light start line
    save(rec)
summary per model: scenarios with 3/3 clean runs, mustNot total, repaired runs, p50/p95 ms, median/p95 n$, total $
```

Token rules for word checks: lowercase, split on non-letters/digits, phrases matched as token runs, and a word that appears in any pack title is exempt. Numbers: "h am/pm" and "h:mm am/pm" convert to minutes of day; "N min" and "N hours" convert to minutes and must equal a `min`; any other digit or number word must be a token of a title.

## 7. Running it once the key store lands

Needs T3 (`TessKeychain`, `ClaudeTessModel`, `TessCall` ledger), T4 (`PlanPack`) and T6 (`ProposePlan`, validator). Core turns section 4 into `TesseraTests/Fixtures/plan-my-day-claude.json` (pack, order, lines, per-scenario must-not words).

1. Kaushik types his key into Settings: Claude in the app (simulator or phone). It goes only to the Keychain item `com.kaushikaranagu.tessera.anthropic`. It is never in a file, scheme, launch argument, environment file, fixture, log or result.
2. Launch the DEBUG build with `-planEval` (new, DEBUG only). The runner reads the key through `TessKeychain`, checks `canSpend` before each call, writes one `TessCall` per call (so the $10 cap and the receipts count it), and runs Sonnet then Haiku, 3 runs each, skipping d14.
3. It scores on the device with the section 6 scorer and writes `Application Support/Tessera/evals/plan-<yyyy-MM-dd-HHmm>.json`: per call the codes, tokens, n$, ms and the reply JSON. Never the key or request headers. Packs are synthetic, so storing replies is fine.
4. Pull it from the simulator with `xcrun simctl get_app_container booted com.kaushikaranagu.tessera data`, or from the phone through Xcode's container download. The run ends with one line: "Plan eval: Sonnet 19 of 20, Haiku 13 of 20, $0.27."
5. Compare the total with the Anthropic Console usage page (the 10% check). Rerun when the instructions, the pack builder or a model ID changes.

The Mac route in `tess-model-layer.md` (`swift run tess-eval --route claude` reading `ANTHROPIC_API_KEY`) stays a fallback only. If used, he types the key with `read -s` in that terminal, and it is never saved to a profile or `.env`.

## 8. Gaps

1. `plan-my-day-prompt.md` §1 still says "times as HH:mm"; the 6:37 PM PT format needs the edit in section 2 and an am/pm parser in V11.
2. `plan-my-day-scenarios.md` (Core's rules fixtures) still uses Europe/London and the Health cap (R6). d03, d04, d09, d10, d15, d17, d18 expectations above differ; Core should update those fixtures to C1 to C3 so both files agree.
3. No pack field for a rest day (dryrun G10), so the rest-day check is negative only: never word one.
4. A workout already running at open (dryrun G9, Saturday) is not in the 20. Add it once R3/R8 say what happens.
5. Birthdays: `calendar-pack.md` drops only the Birthdays calendar. A user-made all-day "Mum's birthday" in a normal calendar would still pack. Product: drop those too, or allow them in `allDay`?
6. N3's extra words (night, kept it, light day, short day, small day, gentle) and N5's per-scenario lists are new; the validator needs them.
7. UNVERIFIED: real token counts (chars/4 here), thinking tokens at effort low, latency, and whether Haiku 5.5 handles this structured schema like Sonnet.
8. `-planEval`, the fixture JSON and the plan set in `tess-eval` don't exist yet.
