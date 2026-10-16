# Grammar regression table

For: Core engine (`TessGrammar`, `TessDates`), board item 33. Research lab. Date: 2026-10-16.

One deduplicated table of every grammar phrase row in today's fixtures, with one expected parse per phrase under today's Product calls and its status on current master. Core runs it as a single suite after each grammar PR.

**Master read:** `origin/master` at `1d0833c` (Merge PR #175), rechecked 2026-10-16 for board item 49: no file under `TesseraCore/` changed between `15fc404` and `1d0833c`, so every status below carries over. First read at `15fc404` (Merge PR #162). The 5:58 PM PT grammar regression calls were applied to rows A to I in a second pass on `1d0833c` (17 rows, marked "(5:58 call)"), then the 6:47 PM PT call (17 rows, marked "(6:47 call)"), then the 7:06 PM PT open-question calls (18 rows, marked "(7:06 call)"). The grammar files (`TessGrammar.swift`, `TessGrammar+Kitchen.swift`) last changed in `82c51d9` (the #153 hotfix), so `15fc404` parses exactly as `db049cb`, the commit the post-hotfix sections traced. No Swift toolchain here: every status is a hand trace. Nothing was run. Group K (board item 61) was traced on `0a27447` (Merge PR #189). Its set rules are unchanged since `1d0833c`; the grammar did change in between (the reschedule past guard, a late `tonight`, `tomorrow` and `pastDay` on His day, `notGroceries`), and rows A to J were not re-traced against those changes.

## Sources and coverage

| File | Rows | Taken | Notes |
|---|---|---|---|
| `grammar-misfires.md` | 298 | 298 | Status from its post-hotfix section (`db049cb`), re-checked against the decisions below. Rows 239 and 279 repeat 67 and 2 |
| `spoken-normaliser.md` | 80 | 80 | The normalised text is the phrase. Status from its post-hotfix section. Rows 18, 19, 27, 28, 31, 34 normalise to the same `80 x 8` |
| `reschedule-time-rows.md` | 80 | 80 | No post-hotfix section (written at `02903a0`), so all 80 were spot-traced on `15fc404` |
| `cook-timer-phrases.md` | 40 | 40 | Written at `6cc61ec` (pre-hotfix). All 40 re-traced; only row 12 changed (now a task Fri 14:30) |
| `people-names.md` | 40 | 40 | Already traced at `db049cb` |
| `reading.md`, `money.md`, `people.md`, `upkeep.md` | 40, 50, 40, 40 | 40, 47, 40, 40 | All traced on `15fc404`. Money rows 38 to 40 are receipt photos and never reach `TessGrammar.parse` |
| `m5-parse-order.md` | (no rows of its own) | | Used for the agreed order, its guards and the expected values it changes (money 17 and 25, people 32 and 40, upkeep 34, 38 and 40) |
| `upkeep-starters.md` | 50 phrases plus named near-misses | 88 | Main and alternative phrases, the plain-verb rows and the near-misses its tests name |
| `reminders.md` | 40 | 40 | Group J, board item 49. Traced at `2473436`; grammar unchanged to `1d0833c`. R14 merges into A224 and R37 into D464, so 38 new rows |
| `set-logger.md` | 40 | 40 | Group K, board item 61. Traced at `0a27447`. Set phrases already here (B300, B302, B303, B306, B309, A180, H625, D473) were left out of the source, so no row merges |
| `show-photos.md` | 25 photos | 0 | No row routes typed or OCR text through `TessGrammar.parse`: receipts go to `ReceiptTotal`, recipes to `RecipeParser`, notes to `CreateNote`. Guard for Core: OCR text must never be fed to the grammar (row 18's "call plumber thurs" would become a task) |

**814 unique rows** after merging 51 duplicate source rows (same normalised phrase, same context; a row written at another clock merges when it gives the same parse, as R14 does into A224).

## How to read the table

**Dedupe key.** The phrase lower-cased, edge punctuation trimmed (a trailing `?` kept, since it decides the question guard), spaces collapsed, plus the context. Titles in the expected column keep the case the phrase was typed in ("Call Ravi" vs "Call ravi").

**Context.** The mode, then the store when it matters, then the clock when it is not the default.
- Modes: **none** (nothing running), **live workout** (Bench Press in focus, last set 80 x 8), **shop run** (Groceries is the running process), **cook** (Weeknight dal running, step 2 of 3 "simmer", timers Rice ends 18:10 and Simmer ends 18:20). "Soften flared" adds an 8-minute Soften timer that ended at 17:59:30 and was not stopped; "last step" puts the cook on step 3.
- Clock: **Thu 15 Oct 2026 18:10 America/Los_Angeles** unless the cell says 09:00, 23:30 or (all cook rows) 18:00, which the cook timer fixture needs. Group J (reminders) runs on Fri 16 Oct: its context cell gives the day and clock (`Fri 17:40`, `Fri 21:15`, `Sat 00:30`). Rows written at 18:00 Europe/London give the same parse at 18:10, except spoken row 50 ("in 20 min"), now 18:30. Fri is 16 Oct, Sat 17, Sun 18, Mon 19, Tue 20, Wed 21, next Thu 22; for past days, Sat 10, Sun 11, Mon 12, Tue 13, Wed 14, Fri 9.
- Stores (the part after the mode): none means the misfires store (recipes Spaghetti carbonara, Chilli con carne, Weeknight dal, Salmon rice bowl, Egg fried rice; open tasks Dentist Sat 17 10:00, Call mum, Clean the oven; no people). **tasks**: the reschedule store (adds Haircut today 17:00, Pay rent Fri 09:00, Bins out today 21:00, Call dad Fri 12:00, Call bank done). **people**: the shared M5 store with people Mum (aliases Mom, Amma), Sam, Ben, Rosemary, Ravi, Will, Rose, Mark, Bill; "task done" means "Call mum" is already done. **book**: Dune reading at p 120 of 612 plus the reading shelf; "two books" adds Project Hail Mary reading; "book in front" means Dune is the running process. **total awaited**: a shop ended 1 h ago with no total. **chores**: the 25 upkeep starters picked plus the upkeep.md chores, open tasks "Clean the oven" and "Do the ironing"; "chores paused" means paused until Sun 18. **call mum alert**: adds "Call mum" Fri 16 18:00 with `alerts` true (at Fri 18:02 it has just rung). Group K adds **db**, **machine**, **bw** (another exercise in focus), **no sets** (nothing logged yet) and **spoken** (the heard text); its preamble defines them.

**Expected parse.** Action plus key fields: `task "Title" Day dd HH:mm` or `Later`, `note "body" Day dd`, `groceries [a, b]`, `set WxR`, `lift Exercise WxR`, `sets`, `reschedule Task Day dd HH:mm`, `timer "Label" minutes`, `cook Recipe`, `no write, asks "line"` (the grammar claims the phrase, writes nothing and asks), `SetTaskAlerts`, `MoveTask`, `cookStep`, `ignoredInWorkout`, `nil` (the grammar returns nil and the phrase goes to the model). When the target needs a slice that is not on master, the cell names it in brackets and gives what master must do until then: `target [Money] · now: nil`. **Gates:** Money, People, Reading, Upkeep (with `did` narrowed in the question guard), Lists 8, 12b (cook pause and extend), N1 (the `alerts` field and dated tasks with no time, `notifications.md`), month dates (the month parser planned with People, T706).

**Day with no time and `alerts` (6:20 and 6:30 PM PT calls).** `Sat 17, no time` is a dated task with no clock time: a task with no time is never saved as 09:00. `alerts T` or `alerts F` at the end of a task says whether it should ring: true for a reminder lead (remind me, nudge me, ping me, don't let me forget, set a reminder) or a clock time, and only when the task has an instant; "remind me" plus a day with no time is 09:00 with `alerts T`; a plain day with no time is `no time, alerts F`. Master has neither `alerts` nor a date-only task, so the status column judges the rest of the parse and the `alerts` part waits on N1. A row with no `alerts` mark is not checked for it. "(6:30 call)" marks the 56 existing rows these two calls changed (A222 joined in the 5:58 pass), plus J752, the call's own example. "(5:58 call)" marks the 17 rows the 5:58 PM calls changed, and "(6:47 call)" the 17 rows the 6:47 PM call changed (the next-whole-hour default and cook rows with a day). The next-whole-hour rule that master and the THU call used for a day with no time is gone: `call mum thu` said on a Thursday is `Thu 15, no time`.

**Status on master.** **pass**: master gives the expected parse, or, for a gated row, the "now" parse. **wrong write**: master writes a different object, date, time, title or line, or writes when it should not. **miss**: master returns nil (or writes only part of the parse) where the grammar should act now. A gated row that passes still owes its target when the gate opens. The root cause follows the status in brackets.

## Decision codes

| Code | Product call in `product/decisions.md` |
|---|---|
| C1 | 4:26 PM call 1: bare hours, 1 to 6 PM, 7 to 11 the next one today, 12 noon |
| C2 | 4:26 PM call 2: a past log writes a note dated that past day, never a task |
| C3 | 4:26 PM call 3: non-food `get` goes to tasks |
| C4 | 4:26 PM call 4: "is" questions (and other questions) go to the question path |
| C5 | 4:26 PM call 5: a passed time today lands tomorrow |
| B430 | 4:30 PM: `buy` with a clearly non-food object is a task; unclear stays Groceries |
| P434 | 4:34 PM: `paid` plus an amount is Money, ticking a named chore in the same ghost row |
| T441 | 4:41 PM time-form rules: a named weekday means that weekday; 7 to 11 on another day is PM with a meal or evening word, else AM; `tonight`/`this evening` after 8 PM stays today until 11:30 PM |
| O410 | 4:10 PM: one parse order for M5, with the guards in `m5-parse-order.md` |
| M410 | 4:10 PM Money defaults: four currencies, bare "38" answers a waiting total only with no workout, a split logs his share |
| K450 | 4:50 PM cook timer calls (step-verb label, flared then soonest, step N by voice, 180 cap, "2 onions" writes nothing, seconds under 2 min, Q1 ahead of the guard, extend and pause wait for 12b) |
| U450 | 4:50 PM upkeep starter calls (guards S1 to S6, noun-first logs, "fine" is done for checks, `alarm` not an AM cue, "get new sheets" is a task, near-misses follow the file) |
| THU | 18:58 UTC: "thu" said on a Thursday means today (its next-whole-hour time is replaced by T647: no time) |
| PD8 | People ship list Decision 8 (approved 19:22 UTC): a contact phrase decides; `buy` keeps its kitchen meaning otherwise |
| MA, RD, PA, UA | The Money (19:07 UTC), Reading (18:40 UTC), People (19:22 UTC) and Upkeep (19:11 UTC) ship lists, approved with their defaults |
| D558 | 5:58 PM grammar regression calls: 1 "table" is not a meal word; 2 "tonight" after 8 PM is tonight (as T441); 3 "next fri" is next week's Friday; 4 reschedule rules R13c, f, g, i and j taken; 5 in "paid 12.50 at 12.30" 12.50 is the amount and 12.30 the time; 6 "done" while a timer rings ends the timer first; 7 the test clock is Los Angeles |
| L607 | 6:07 PM late-night rules: "tomorrow" before 4 AM is the coming daytime and the reply names the weekday |
| N620 | 6:20 PM notifications, first set (`notifications.md` N1): `alerts` for a reminder lead or a clock time; quiet hours 11 PM to 7 AM; a task with no time is never saved as 9:00 |
| Q622 | 6:22 PM Claude's first uses: grammar misses go to Haiku, so phrases that need judgement must reach the model |
| T647 | 6:47 PM reminder and default-time calls (Research #180, all defaults): "morning" stays 09:00 because he said it; the silent next-whole-hour default goes, so a weekday that is today, "today" with no time, and a planned cook with a day get no time and no alert; reminders.md defaults stand ("Reminder" title, eggs to Groceries, place reminders to Later, repeats take the first one) |
| T650 | 6:50 PM reschedule and tonight calls (Research #181, all defaults): a late "tonight" or "this evening" with no clock time keeps the next whole hour, tonight only, quiet hours still apply; a reschedule never lands in the past and rolls to the next occurrence (R13e); a reschedule with no task named applies to the task on Now (R13h); cancel keeps the task and drops only its alert, `again in N` with no recent alert goes to the model |
| T706 | 7:06 PM open-question calls (Research #188, all 20 defaults, `grammar-open-defaults.md`): the grammar reads `in N` and `day after tomorrow`, and a plain relative time rings; `N days before X` goes to the model; `remind me in 20` in a cook is a timer; RPE `@N` in a live workout only; a drop with no reps and `add 2.5` go to the model; `add X` is Groceries; M8 sends `12.40 lunch fri` to the model once Money lands; percent sets the page (asks with no page count); `abandoned`, `gave up on`, `dnf` set a book aside; a bare number is the page of the book in front; `rang mum` is a call; `lunch with ravi` asks plan or done; `buy flowers for mum` is a task about Mum; a lone `will` is ignored; and-lists and training partners go to the model; a month alone is the 1st and a month is 30 days; "Bins every Thursday" keeps its title |
| R630 | 6:30 PM: "remind me" plus a day alerts at 9 AM; a plain "call mum sat" gets no time and no alert |
| S701 to S706 | Proposed set-logger defaults (board item 61, `set-logger.md`), awaiting Product: S701 a bare whole number is reps only from 1 to 50 and not within two loads of the last weight, else the model; S702 `+N` and `-N` alone go to the model; S703 a weight in kg snaps to the dial's nearest load (a tie to the lighter), outside the dial's range goes to the model, pounds are kept as said; S704 `at N` after a set is RPE 5 to 10 in a live workout, never a time; S705 `to failure` and `warmup` set the kind, `fail at N` goes to the model; S706 `bodyweight N`, `+W for R` on a bodyweight lift and `bar for N` are read, `skip` writes nothing. Each turns a wrong write into a miss or the right write |
| MB | Master behaviour the fixtures agree on; no call needed (guard rows) |
| FX | The fixture's own expected value; no Product call covers it (see open questions where it matters) |

## Root cause codes

RC1 to RC20 are `grammar-misfires.md`'s. New here: **RELT** relative dates (`in 20 min`, `in 2 hours`, `day after tomorrow`, `N days before X`), **ORD** ordinal dates (`the 20th`, `the twentieth`), **RPE** `@N` after a set, **ADD** `add N` in a workout and `add X` elsewhere (GC 40, 41), **DROP** a drop set with no reps, **NRM** a spoken phrase the normaliser should reshape, with a Core backstop, **UPK** an upkeep verb that falls through to the task rule. From the reminder rows: **LEAD** reminder leads not read (`ping`, `nudge`, `don't let me forget`, `set a reminder for`, `about` and `later` after the lead, an empty title), **DAY4** the 4 AM day and the late "tonight" window, **DAYW** day words `this weekend`, `every <day>`, **PLACE** `when I get home`, `when I leave work` not stripped, **ALRT** alert edits (`cancel the 6pm reminder`, `again in 10`), **RBUY** `remind me to buy` food with no day or time kept as a task, **GUARD** a remind phrase that needs the model (`actually 7`, `quarter to 7`) claimed by the grammar. From the set logger rows (group K): **SNAP** a weight said to Tess logged as said, not snapped to the exercise's loads or checked against its range, **REPS** any whole number 1 to 100 read as reps (`81`, `+5`, `-5`; A180 is the same cause), **SETT** a set word with `at N` (`fail at 6`) falling to the task rule, **LOADW** load words (`bodyweight N`, `+W for R`, `bar for N`) not read, **KIND** set kind words (`to failure`, `warmup`) not read.

## Conflicts resolved

30 places where two sources disagree on the expected parse. The later Product call wins.

1. **`push the dentist to thu 3pm`** (C377). Reschedule A12 wanted Fri 16 15:00 (call 5 plus "thu is today"); misfires 112 wanted Thu 22. **T441** (4:41 PM, after both): a named weekday means that weekday. Thu 22 15:00. Same rule settles A112.
2. **`dinner tomorrow at 7`** (A105). Reschedule open question 2 read 7 on another day as AM (Fri 07:00); misfires 105 wanted 19:00 from the meal word. **T441**: PM with a meal word. Fri 16 19:00.
3. **`move dentist to 7`** (A127). Misfires 127 expected the model; reschedule A8, A9, A15, A20 read a bare hour after `to` on the task's own day. **C1 then T441** give an hour, so the family is made consistent: Sat 17 07:00 (another day, no meal word, AM). R13c is taken at 5:58 PM (D558 call 4).
4. **`tonight` said at 23:30** (C405, C437). Reschedule rows followed call 5 (tomorrow 20:00). **T441** keeps "tonight" today only until 11:30 PM, so at 23:30 tomorrow 20:00 stands (boundary flagged in open question 2).
5. **`call mum this evening`** at 18:10 (C420). Call 5 alone would roll to tomorrow 18:00; reschedule R11e proposed the next whole hour. **T441** keeps "this evening" today. Thu 15 19:00.
6. **`buy lego for priya`** (F544). people.md row 32 kept Groceries (Decision 8). **B430**: a toy is clearly non-food, so a task, Later.
7. **`get mum a card`** (A002, merging misfires 2 and 279 and people 33). Misfires accepted "task or model"; people wanted a task about Mum. **C3 and B430**: a task, Later, about Mum once People lands.
8. **`paid rent 650`** (H614, merging money 25, upkeep 34, starters 22). Money said model; upkeep said chore only, no spend. **P434**: spend 650 plus DoChore(Pay rent) in one ghost row.
9. **`paid council tax 142.50`** (I670, merging upkeep 40 and starters 23). Upkeep said AddChore plus DoChore, no spend. **P434**: spend 142.50 plus DoChore when the chore exists, never a new chore.
10. **`Paid 120000 rs deposit`** (B354). The M5 order check found upkeep would make a chore. **P434**: a spend in INR, no chore.
11. **`paid 40 for gas sat`** (A012). Misfires said spend via the model; the M5 order check found upkeep would make a chore. **P434**: a spend dated Sat 10 once Money lands; until then the call 2 note.
12. **Past logs with a day** (A001 to A025, A038 to A040, and the people and upkeep rows that merge with them). Misfires expected "the model"; people and upkeep expected a talk or check-in. **C2**: until People and Upkeep land, a note dated that past day; their targets once they do.
13. **`call mum today at 5`, `call mum today 3pm`** (A109, A110). Misfires wanted Tess to ask. **C5**: never ask; tomorrow at that time.
14. **`is` questions** (A209, A210 and reschedule A33). The spec comment in `TessGrammar.swift` kept "is" phrases as captures. **C4**: questions.
15. **A bare length in a cook** (`9 min` D441, `8 mins` A189, `two minutes` D452). Cook timer row 2 labelled it "Timer". **K450**: the current step's verb, "Simmer".
16. **`2 onions` mid-cook** (D471). Cook timer row 34 leaned to groceries under RC18. **K450**: writes nothing.
17. **`step 3` by voice** (D467). Cook mode ASSUMED-4 said only swipes change step. **K450**: allowed, GoToCookStep(2).
18. **`is the rice done`** (D462). Call 4 sends "is" questions to the model, which cannot see timers. **K450**: Q1 may run ahead of the question guard, so a read-only timer answer.
19. **`spent 60 dinner split with sam`** (H634). money.md row 49 logged 60. **M410**: a split logs his share, 30.
20. **`spent 20 chf taxi`** (H604). money.md row 14 logged an unmarked 20. **M410**: four currencies; other codes go to the model.
21. **`test the smoke alarm at 7`** (I736). Misfires RC1 and master list `alarm` as an AM cue (Fri 07:00). **U450**: `alarm` stops being an AM cue. Thu 15 19:00. `wake me at 7` (A101) keeps its AM cue.
22. **`get new sheets`** (I711). upkeep-starters said RC3's blockers keep it on Groceries. **U450**: a task, matching the 4:30 rule. `buy bed sheets` (I710) follows B430 the same way.
23. **A day with no time** (55 rows, marked "(6:30 call)"). The source rows and master save 09:00; `reminders.md` open question 1 and `notifications.md` N1 kept 09:00 with an alert; the 6:20 PM call says a task with no time is never saved as 9:00. **R630** (6:30 PM, last): "remind me" plus a day stays 09:00 with `alerts T` (A224, B326, B335, B336, B342, B343, B345, B346, and J752, J754, J755, J759, J766, J772); a plain day is dated with no time and `alerts F` (47 rows, now gated on N1, keeping master's 09:00 as the "now" parse until N1 lands).
24. **`next fri`** (A222, C389, J753). Misfires and reschedule A24 left 16 or 23 Oct open (GC question 4); `reminders.md` R18 took next week. **D558 call 3**: Fri 23 Oct. A222 is a dated task with no time (6:30 call); C389 keeps the Dentist's 10:00 (R13a). C389 was a pass at Fri 16 and is now a wrong write (RC7).
25. **`table for 4 at 8 sat`** (A117). Misfires 117 wanted 20:00 if "table" were a meal word. **D558 call 1**: it is not, so another day with no meal word is AM: Sat 17 08:00, which master already writes (now a pass).
26. **`paid 12.50 at 12.30`** (C430). P434 read 12.30 as a time, M11 read only amounts, reschedule B30 said the model. **D558 call 5**: spend 12.50 at 12:30 today once Money lands; until then nil, never a task.
27. **`done` with a flared timer** (D465). Cook mode F2 and the 4:50 rule ("done with that" finishes the step) pointed at the step. **D558 call 6**: a ringing timer ends first, the cook keeps going.
28. **Widened reschedule rows** (A127, C373, C374, C380, C387, C403, C404 for R13c; C388 R13f; C391 R13g; C395, C396 R13i; C397 R13j). Misfires 127 and 112 expected the model; the reschedule fixture proposed the widened rules. **D558 call 4** takes them, so the fixture's values stand; C397 loses its "(or nil)". R13e (never in the past) and R13h (no object) were not named in the call; their rows (C379, C392) keep master behaviour plus call 5. **T650** (6:50 PM) names both: a reschedule never lands in the past, it rolls to the next occurrence (C379 is dated today with no time, so it stands), and with no task named it applies to the task on Now (C392).
29. **A day with no time that master puts on the next whole hour, and cook rows with a day** (17 rows, marked "(6:47 call)"). THU (18:58 UTC) and master gave `call mum thu` on a Thursday, `move dentist to today` and `carbonara thu` the next whole hour (19:00), and `make chilli sat` 09:00. **T647** (6:47 PM): the silent default goes; all 17 are dated with no time and `alerts F`, gated on N1, with master's time as the "now" parse. "morning" keeps 09:00 (A073, A116, C390, C418, C421, C435 unchanged). C379 drops its "kept 10:00 has passed" note: the move to today carries no time.
30. **Open questions 5, 6, 7, 9, 10 and 12** (18 rows, marked "(7:06 call)"). The fixtures kept their own values (FX) for these rows: a drop set at the last reps (B302), a set at last weight plus 2.5 (B310), and nil for the Reading and People gaps and month dates; the approved Money ship list kept `12.40 lunch fri` a task (H611), and B430 kept `buy flowers for mum` on Groceries (A070). **T706** (7:06 PM, all 20 defaults): B302 and B310 go to the model (both now pass); H611 goes to the model once Money lands (M8), gated on Money instead of N1; G561, G579, G580, G589, F519, F531, A070, I655 and I659 get their targets, gated on Reading, People or month dates, with master's nil (or Groceries) as the "now" parse; B338, C422 to C425 and C438 gain `alerts T` (a plain relative time rings). Every other row the call names keeps its value and gains T706 (in place of FX where it had it).

## New findings from the spot-traces

Rows no post-hotfix section covered, traced on `15fc404`:

- **`move dentist to today` writes a time in the past** (C379). The hotfix's "keep what wasn't said" puts the Dentist's old 10:00 on today: Thu 15 10:00, eight hours ago. Reschedule rule R13e (never in the past) is not built.
- **`move dentist to 9:30` lands at 21:30** (C372). `TessDates` resolves the bare 9:30 against today (21:30 is next), then the reschedule moves that hour to Sat. On another day it should be 09:30 (T441).
- **`moved dentist to fri` becomes a note dated last Friday** (C397), and **`changed the meeting to fri`** does the same (I716). The past-log rule reads `fri` as a past day even after `to`.
- **`can you move the dentist to friday`** (C395) now goes to the question path (`can you`), so it is a miss instead of a wrong task.
- **`test the smoke alarm at 7`** (I736) is Fri 07:00 because `alarm` is still in `amCues`.
- **`timer 2:30` in a cook** (D450) is now the task "Timer", Fri 14:30 (was 02:30).
- **Reminder rows** (J, traced at `2473436`, same grammar as `1d0833c`): 9 of 38 pass on the parse; none can pass on `alerts`, which master does not have (no `alerts`, no notifications, no "On Now then." anywhere in `TesseraCore`). `remind me tonight` at 21:15 rolls to Sat 20:00 (J751) and `remind me tomorrow at 9` at 00:30 lands on Sun (J756).
- **`call mum at 7 tonight`** (C407 area, reschedule B16) and **`move haircut to tonight` at 23:30** (C405) now pass.

## The table

Machine-readable rows sit between the two markers below. Each row is one line, seven cells.

<!-- rows:start -->

### A. Everyday, kitchen and training phrases (295 rows)

| id | phrase | context | expected parse | source rows | decision | status |
|---|---|---|---|---|---|---|
| A001 | `watered plants sat` | none | DoChore(Water plants) Sat 10 [Upkeep] · now: note "Watered plants" Sat 10 12:00 | grammar-misfires#1, upkeep#18, upkeep-starters#20 | C2, UA | pass |
| A002 | `get mum a card` | none | task "Get mum a card" Later, about Mum [People] · now: task "Get mum a card" Later | grammar-misfires#2, grammar-misfires#279, people#33 | C3, B430 | pass |
| A003 | `coffee with ravi at 7` | none | task "Coffee with ravi" Thu 15 19:00 (about Ravi once People lands) | grammar-misfires#3, people#18 | C1 | pass |
| A004 | `watered plants thu` | none | DoChore(Water plants) Thu 15 [Upkeep] · now: note "Watered plants" Thu 15 12:00 | grammar-misfires#4, upkeep#19 | C2, THU | pass |
| A005 | `called mum thu` | none | SetTaskDone("Call mum") [People] · now: note "Called mum" Thu 15 12:00 | grammar-misfires#5, people#7 | C2, THU | pass |
| A006 | `saw mum sat` | none | LogTalk(Mum) Sat 10 [People] · now: note "Saw mum" Sat 10 12:00 | grammar-misfires#6, people#6 | C2 | pass |
| A007 | `met sam sun` | none | LogTalk(Sam) Sun 11 [People] · now: note "Met sam" Sun 11 12:00 | grammar-misfires#7 | C2 | pass |
| A008 | `went to the gym mon` | none | note "Went to the gym" Mon 12 12:00 | grammar-misfires#8 | C2 | pass |
| A009 | `ran 5k sat` | none | note "Ran 5k" Sat 10 12:00 | grammar-misfires#9 | C2 | pass |
| A010 | `ran 5 miles sat` | none | note "Ran 5 miles" Sat 10 12:00 | grammar-misfires#10 | C2 | pass |
| A011 | `paid rent fri` | none | DoChore(Pay rent) Fri 9 [Upkeep] · now: note "Paid rent" Fri 9 12:00 | grammar-misfires#11 | C2, P434 | pass |
| A012 | `paid 40 for gas sat` | none | spend 40, note "gas", Sat 10 [Money] · now: note "Paid 40 for gas" Sat 10 12:00 | grammar-misfires#12 | P434, C2 | pass |
| A013 | `bought milk sat` | none | note "Bought milk" Sat 10 12:00 | grammar-misfires#13 | C2 | pass |
| A014 | `cleaned the bathroom wed` | none | DoChore(Clean the bathroom) Wed 14 [Upkeep] · now: note "Cleaned the bathroom" Wed 14 12:00 | grammar-misfires#14, upkeep-starters#13 | C2, UA | pass |
| A015 | `took the bins out thu` | none | DoChore(Take out the bins) Thu 15 [Upkeep] · now: note "Took the bins out" Thu 15 12:00 | grammar-misfires#15 | C2, THU | pass |
| A016 | `fed the cat thu` | none | note "Fed the cat" Thu 15 12:00 | grammar-misfires#16 | C2 | pass |
| A017 | `washed the car sat` | none | DoChore(Wash the car) Sat 10 [Upkeep] · now: note "Washed the car" Sat 10 12:00 | grammar-misfires#17 | C2 | pass |
| A018 | `visited nan sun` | none | LogTalk(Nan) Sun 11 [People] · now: note "Visited nan" Sun 11 12:00 | grammar-misfires#18 | C2 | pass |
| A019 | `had lunch with ravi wed` | none | LogTalk(Ravi) Wed 14 [People] · now: note "Had lunch with ravi" Wed 14 12:00 | grammar-misfires#19 | C2, O410 | pass |
| A020 | `cooked chilli sun` | none | note "Cooked chilli" Sun 11 12:00 | grammar-misfires#20 | C2 | pass |
| A021 | `made carbonara thu` | none | note "Made carbonara" Thu 15 12:00 | grammar-misfires#21 | C2 | pass |
| A022 | `finished the report today` | none | note "Finished the report" Thu 15 12:00 (completion grammar later) | grammar-misfires#22 | C2 | pass |
| A023 | `watched dune sat` | none | note "Watched dune" Sat 10 12:00 | grammar-misfires#23 | C2 | pass |
| A024 | `walked 10k steps fri` | none | note "Walked 10k steps" Fri 9 12:00 | grammar-misfires#24 | C2 | pass |
| A025 | `benched 80x8 mon` | none | note "Benched 80x8" Mon 12 12:00, never a task | grammar-misfires#25 | C2 | pass |
| A026 | `bench 80x8 mon` | none | lift Bench Press 80x8 dated Mon 12, or nil; never a task | grammar-misfires#26 | FX | wrong write (RC12) |
| A027 | `squat 100x5 tue` | none | lift Back Squat 100x5 dated Tue 13, or nil; never a task | grammar-misfires#27 | FX | wrong write (RC12) |
| A028 | `ran 5k in 22:15` | none | note "Ran 5k in 22:15" Thu 15, never a task | grammar-misfires#28 | C2 | wrong write (RC2) |
| A029 | `slept at 11` | none | note "Slept at 11" Thu 15, never a task | grammar-misfires#29 | C2 | wrong write (RC2) |
| A030 | `woke up at 6` | none | note "Woke up at 6" Thu 15, never a task | grammar-misfires#30 | C2 | wrong write (RC2) |
| A031 | `did laundry tue` | none | DoChore(Laundry) Tue 13 [Upkeep, did narrowed] · now: nil | grammar-misfires#31 | O410, UA | pass |
| A032 | `did legs mon` | none | nil (did X never creates a chore) | grammar-misfires#32 | O410 | pass |
| A033 | `need to call mum thu` | none | task "Need to call mum" Thu 15, no time, alerts F (6:47 call) [N1] · now: task "Need to call mum" Thu 15 19:00 | grammar-misfires#33 | THU, T647 | pass |
| A034 | `feed the cat sat` | none | task "Feed the cat" Sat 17, no time, alerts F (6:30 call) [N1] · now: task "Feed the cat" Sat 17 09:00 | grammar-misfires#34 | MB, N620, R630 | pass |
| A035 | `weed the garden sun` | none | task "Weed the garden" Sun 18, no time, alerts F (6:30 call) [N1] · now: task "Weed the garden" Sun 18 09:00 | grammar-misfires#35 | MB, N620, R630 | pass |
| A036 | `water plants sun` | none | task "Water plants" Sun 18, no time, alerts F (6:30 call) [N1] · now: task "Water plants" Sun 18 09:00 | grammar-misfires#36, upkeep#20, upkeep-starters#20 | UA, N620, R630 | pass |
| A037 | `read 40 pages sat` | none | task "Read 40 pages" Sat 17, no time, alerts F (6:30 call) [N1] · now: task "Read 40 pages" Sat 17 09:00 | grammar-misfires#37 | MB, N620, R630 | pass |
| A038 | `watered plants sat` | live workout | as the idle row: note "Watered plants" Sat 10 12:00 (DoChore once Upkeep lands) | grammar-misfires#38 | C2 | pass |
| A039 | `watered plants sat` | cook, 18:00 | as the idle row: note "Watered plants" Sat 10 12:00 (DoChore once Upkeep lands) | grammar-misfires#39 | C2 | pass |
| A040 | `called mum thu` | shop run | note "Called mum" Thu 15 12:00 (SetTaskDone once People lands) | grammar-misfires#40 | C2 | pass |
| A041 | `get mum a card` | shop run | task "Get mum a card" Later | grammar-misfires#41 | C3, O410 | pass |
| A042 | `get mum a card` | live workout | task "Get mum a card" Later | grammar-misfires#42 | C3 | pass |
| A043 | `get mum a card` | cook, 18:00 | task "Get mum a card" Later | grammar-misfires#43 | C3 | pass |
| A044 | `get mum flowers` | none | task "Get mum flowers" Later | grammar-misfires#44 | C3 | pass |
| A045 | `get dad a beer` | none | task "Get dad a beer" Later | grammar-misfires#45 | C3 | pass |
| A046 | `get her a card` | none | task "Get her a card" Later | grammar-misfires#46 | C3 | pass |
| A047 | `get him flowers` | none | task "Get him flowers" Later | grammar-misfires#47 | C3 | pass |
| A048 | `get a haircut` | none | task "Get a haircut" Later | grammar-misfires#48 | C3 | pass |
| A049 | `get a plumber in` | none | task "Get a plumber in" Later | grammar-misfires#49 | C3 | pass |
| A050 | `get a new phone` | none | task "Get a new phone" Later | grammar-misfires#50 | C3 | pass |
| A051 | `get passport photos` | none | task "Get passport photos" Later | grammar-misfires#51 | C3 | pass |
| A052 | `get petrol` | none | task "Get petrol" Later | grammar-misfires#52 | C3 | pass |
| A053 | `get cash out` | none | task "Get cash out" Later | grammar-misfires#53 | C3 | pass |
| A054 | `get flights booked` | none | task "Get flights booked" Later | grammar-misfires#54 | C3 | pass |
| A055 | `buy Candy a drink` | none | task "Buy Candy a drink" Later | grammar-misfires#55 | B430 | pass |
| A056 | `buy present for mum` | none | task "Buy present for mum" Later | grammar-misfires#56 | B430 | pass |
| A057 | `buy a new phone` | none | task "Buy a new phone" Later | grammar-misfires#57 | B430 | pass |
| A058 | `buy tickets for the gig` | none | task "Buy tickets for the gig" Later | grammar-misfires#58 | B430 | pass |
| A059 | `buy milk and bench 80x8` | none | groceries [milk] + lift Bench Press 80x8 (RC6 split); nil until the split | grammar-misfires#59 | FX | wrong write (RC6) |
| A060 | `get protein and do legs` | none | groceries [protein] + model for the rest (RC6 split) | grammar-misfires#60 | FX | miss (RC6) |
| A061 | `get mum from the station at 8` | none | task "Get mum from the station" Thu 15 20:00 | grammar-misfires#61 | C1 | pass |
| A062 | `get tickets for the gig` | none | nil | grammar-misfires#62 | MB | pass |
| A063 | `get the car washed` | none | nil | grammar-misfires#63 | MB | pass |
| A064 | `get mum a card sat` | none | task "Get mum a card" Sat 17, no time, alerts F (6:30 call) [N1] · now: task "Get mum a card" Sat 17 09:00 | grammar-misfires#64 | MB, N620, R630 | pass |
| A065 | `get coffee` | none | groceries [coffee] | grammar-misfires#65 | B430 | pass |
| A066 | `get bin bags` | none | groceries [bin bags] | grammar-misfires#66 | B430 | pass |
| A067 | `buy milk` | none | groceries [milk] | grammar-misfires#67, grammar-misfires#239 | B430 | pass |
| A068 | `buy toothpaste` | none | groceries [toothpaste] | grammar-misfires#68 | B430 | pass |
| A069 | `buy batteries` | none | groceries [batteries] | grammar-misfires#69 | B430 | pass |
| A070 | `buy flowers for mum` | none | task "Buy flowers for mum" Later, about Mum (7:06 call) [People] · now: groceries [flowers for mum] | grammar-misfires#70 | B430, T706 | pass |
| A071 | `buy sun cream` | none | groceries [sun cream] | grammar-misfires#71, grammar-misfires#256 | B430 | pass |
| A072 | `buy sun cream sat` | none | task "Buy sun cream" Sat 17, no time, alerts F (6:30 call) [N1] · now: task "Buy sun cream" Sat 17 09:00 | grammar-misfires#72 | FX, N620, R630 | wrong write (RC10) |
| A073 | `buy milk sat morning` | none | task "Buy milk" Sat 17 09:00 | grammar-misfires#73 | T441 | wrong write (RC11) |
| A074 | `7` | none | nil | grammar-misfires#74 | MB | pass |
| A075 | `at 7` | none | nil | grammar-misfires#75 | MB | pass |
| A076 | `7pm` | none | nil | grammar-misfires#76 | MB | pass |
| A077 | `19:00` | none | nil | grammar-misfires#77 | MB | pass |
| A078 | `half 7` | none | nil (no title) | grammar-misfires#78 | MB | pass |
| A079 | `7` | live workout | set 80x7 (reps only) | grammar-misfires#79 | MB | pass |
| A080 | `at 7` | live workout | nil | grammar-misfires#80 | MB | pass |
| A081 | `7pm` | live workout | nil | grammar-misfires#81 | MB | pass |
| A082 | `19:00` | live workout | nil | grammar-misfires#82 | MB | pass |
| A083 | `half 7` | live workout | nil | grammar-misfires#83, reschedule-time-rows#B33 | MB | pass |
| A084 | `7` | cook, 18:00 | nil | grammar-misfires#84 | MB | pass |
| A085 | `7` | shop run | nil | grammar-misfires#85 | MB | pass |
| A086 | `call mum at 7` | none | task "Call mum" Thu 15 19:00 | grammar-misfires#86 | C1 | pass |
| A087 | `call mum 7pm` | none | task "Call mum" Thu 15 19:00 | grammar-misfires#87 | MB | pass |
| A088 | `call mum at 7pm` | none | task "Call mum" Thu 15 19:00 | grammar-misfires#88, spoken-normaliser#54 | MB | pass |
| A089 | `call mum 19:00` | none | task "Call mum" Thu 15 19:00 | grammar-misfires#89 | MB | pass |
| A090 | `call mum at 7 pm` | none | task "Call mum" Thu 15 19:00 | grammar-misfires#90, reschedule-time-rows#B2 | T441 | wrong write (RC11) |
| A091 | `call mum 7 pm` | none | task "Call mum" Thu 15 19:00 | grammar-misfires#91, reschedule-time-rows#B1 | T441 | miss (RC11) |
| A092 | `call mum half 7` | none | task "Call mum" Thu 15 19:30 | grammar-misfires#92, reschedule-time-rows#B10 | C1, T441 | miss (RC11) |
| A093 | `call mum at half 7` | none | task "Call mum" Thu 15 19:30 | grammar-misfires#93 | C1, T441 | miss (RC11) |
| A094 | `dinner at 7.30` | none | task "Dinner" Thu 15 19:30 | grammar-misfires#94, reschedule-time-rows#B7 | C1, T441 | miss (RC11) |
| A095 | `dinner at 7:30` | none | task "Dinner" Thu 15 19:30 | grammar-misfires#95 | C1 | pass |
| A096 | `meet ravi at 6:30` | none | task "Meet ravi" Thu 15 18:30 | grammar-misfires#96 | C1 | pass |
| A097 | `pick up kids at 3` | none | task "Pick up kids" Fri 16 15:00 | grammar-misfires#97 | C1, C5 | pass |
| A098 | `drinks at 8` | none | task "Drinks" Thu 15 20:00 | grammar-misfires#98 | C1 | pass |
| A099 | `bins out at 10` | none | task "Bins out" Thu 15 22:00 (noun-out never binds with a time) | grammar-misfires#99, upkeep-starters#2 | C1, U450 | pass |
| A100 | `gym at 7` | none | task "Gym" Thu 15 19:00 (Fri 07:00 one tap away on the ghost) | grammar-misfires#100 | C1 | pass |
| A101 | `wake me at 7` | none | task "Wake me" Fri 16 07:00 (am cue) | grammar-misfires#101 | C1 | pass |
| A102 | `call mum at 12` | none | task "Call mum" Fri 16 12:00 | grammar-misfires#102 | C1, C5 | pass |
| A103 | `lunch with ravi at noon` | none | task "Lunch with ravi" Fri 16 12:00 | grammar-misfires#103 | C5 | pass |
| A104 | `standup tomorrow at 9` | none | task "Standup" Fri 16 09:00 | grammar-misfires#104 | T441 | pass |
| A105 | `dinner tomorrow at 7` | none | task "Dinner" Fri 16 19:00 (meal word means PM) | grammar-misfires#105 | T441 | pass |
| A106 | `call mum tonight at 9` | none | task "Call mum" Thu 15 21:00 | grammar-misfires#106 | C1 | pass |
| A107 | `call mum at 9 tonight` | none | task "Call mum" Thu 15 21:00 | grammar-misfires#107 | C1 | pass |
| A108 | `call mum tonight 9pm` | none | task "Call mum" Thu 15 21:00 | grammar-misfires#108 | MB | pass |
| A109 | `call mum today at 5` | none | task "Call mum" Fri 16 17:00 | grammar-misfires#109 | C1, C5 | pass |
| A110 | `call mum today 3pm` | none | task "Call mum" Fri 16 15:00 | grammar-misfires#110 | C5 | pass |
| A111 | `call mum thu at 8` | none | task "Call mum" Thu 15 20:00 | grammar-misfires#111 | C1, THU | pass |
| A112 | `call mum thu 3pm` | none | task "Call mum" Thu 22 15:00 (named weekday means that weekday) | grammar-misfires#112 | T441 | pass |
| A113 | `call mum thu 8pm` | none | task "Call mum" Thu 15 20:00 | grammar-misfires#113 | THU | pass |
| A114 | `dentist sat at 10` | none | task "Dentist" Sat 17 10:00 | grammar-misfires#114 | T441 | pass |
| A115 | `call mum sun afternoon` | none | task "Call mum" Sun 18 14:00 | grammar-misfires#115 | FX | wrong write (RC11) |
| A116 | `dentist sat morning` | none | task "Dentist" Sat 17 09:00 | grammar-misfires#116 | FX | wrong write (RC11) |
| A117 | `table for 4 at 8 sat` | none | task "Table for 4" Sat 17 08:00 ("table" is not a meal word: another day, AM) (5:58 call) | grammar-misfires#117 | T441, D558 | pass |
| A118 | `call 2 clients at 3` | none | task "Call 2 clients" Fri 16 15:00 | grammar-misfires#118 | C1, C5 | pass |
| A119 | `plank 2:30` | none | nil (a hold, never a task) | grammar-misfires#119, reschedule-time-rows#B27 | MB | pass |
| A120 | `plank 2:30` | live workout | nil | grammar-misfires#120 | MB | pass |
| A121 | `call mum at 7` | live workout | task "Call mum" Thu 15 19:00 | grammar-misfires#121 | C1 | pass |
| A122 | `call mum at 7` | cook, 18:00 | task "Call mum" Thu 15 19:00 | grammar-misfires#122 | C1 | pass |
| A123 | `call mum at 7` | shop run | task "Call mum" Thu 15 19:00 | grammar-misfires#123 | C1 | pass |
| A124 | `cook dinner at 7` | none | task "Cook dinner" Thu 15 19:00 | grammar-misfires#124 | C1 | pass |
| A125 | `move dentist to fri` | none | reschedule Dentist Fri 16 10:00 | grammar-misfires#125, reschedule-time-rows#A1 | FX | pass |
| A126 | `move dentist to 3pm` | none | reschedule Dentist Sat 17 15:00 | grammar-misfires#126, reschedule-time-rows#A6 | FX | pass |
| A127 | `move dentist to 7` | none | reschedule Dentist Sat 17 07:00 (bare hour on its own day) (5:58 call) | grammar-misfires#127 | C1, T441, D558 | miss (RC13) |
| A128 | `Olive` | none | nil | grammar-misfires#128 | MB | pass |
| A129 | `Olive` | shop run | groceries [olive] | grammar-misfires#129 | MB | pass |
| A130 | `call Olive thu` | none | task "Call Olive" Thu 15, no time, alerts F (6:47 call) [N1] · now: task "Call Olive" Thu 15 19:00 | grammar-misfires#130 | THU, T647 | pass |
| A131 | `text Olive` | shop run | nil | grammar-misfires#131 | O410 | pass |
| A132 | `get Olive a present` | none | task "Get Olive a present" Later | grammar-misfires#132 | C3 | pass |
| A133 | `get Honey a coffee` | none | task "Get Honey a coffee" Later | grammar-misfires#133 | C3 | pass |
| A134 | `get Basil some flowers` | none | task "Get Basil some flowers" Later | grammar-misfires#134 | C3 | pass |
| A135 | `get Candy flowers` | none | task "Get Candy flowers" Later, about Candy [People] · now: groceries [Candy flowers] (unclear stays Groceries) | grammar-misfires#135 | B430 | pass |
| A136 | `coffee with Pepper, then gym` | none | nil | grammar-misfires#136 | FX | wrong write (RC8) |
| A137 | `lunch with Olive, Basil` | none | nil | grammar-misfires#137 | FX | wrong write (RC8) |
| A138 | `drinks with Candy, Honey` | none | nil | grammar-misfires#138 | FX | wrong write (RC8) |
| A139 | `Candy, Honey and Basil are coming` | none | nil | grammar-misfires#139 | FX | wrong write (RC8) |
| A140 | `Olive, Basil and Ginger` | none | groceries [Olive, Basil, Ginger] | grammar-misfires#140 | MB | pass |
| A141 | `text Ginger, Basil and Honey` | none | nil | grammar-misfires#141 | MB | pass |
| A142 | `Pepper sat` | none | task "Pepper" Sat 17, no time, alerts F (6:30 call) [N1] · now: task "Pepper" Sat 17 09:00 | grammar-misfires#142 | MB, N620, R630 | pass |
| A143 | `Ginger's birthday sat` | none | task "Ginger's birthday" Sat 17, no time, alerts F (6:30 call) [N1] · now: task "Ginger's birthday" Sat 17 09:00 | grammar-misfires#143 | MB, N620, R630 | pass |
| A144 | `dinner with Ginger fri` | none | task "Dinner with Ginger" Fri 16, no time, alerts F (6:30 call) [N1] · now: task "Dinner with Ginger" Fri 16 09:00 | grammar-misfires#144 | MB, N620, R630 | pass |
| A145 | `meet Rosemary at 7` | none | task "Meet Rosemary" Thu 15 19:00 | grammar-misfires#145 | C1 | pass |
| A146 | `Basil at 7` | none | task "Basil" Thu 15 19:00 | grammar-misfires#146 | C1 | pass |
| A147 | `Basil 7pm` | none | task "Basil" Thu 15 19:00 | grammar-misfires#147 | MB | pass |
| A148 | `pick up Honey at 4` | none | task "Pick up Honey" Fri 16 16:00 | grammar-misfires#148 | C1, C5 | pass |
| A149 | `get Ginger from school at 3` | none | task "Get Ginger from school" Fri 16 15:00 | grammar-misfires#149 | C1, C5 | pass |
| A150 | `get Honey from the station` | none | nil | grammar-misfires#150 | MB | pass |
| A151 | `buy rosemary` | none | groceries [rosemary], no person link | grammar-misfires#151, people#34 | PD8 | pass |
| A152 | `get ginger` | none | groceries [ginger] | grammar-misfires#152 | MB | pass |
| A153 | `Honey` | live workout | nil | grammar-misfires#153 | MB | pass |
| A154 | `Basil` | cook, 18:00 | nil | grammar-misfires#154 | MB | pass |
| A155 | `Pepper` | shop run | groceries [pepper] | grammar-misfires#155 | MB | pass |
| A156 | `call Pepper` | none | nil | grammar-misfires#156 | MB | pass |
| A157 | `lunch with Basil, sat` | none | task "Lunch with Basil" Sat 17, no time, alerts F (6:30 call) [N1] · now: task "Lunch with Basil" Sat 17 09:00 | grammar-misfires#157 | MB, N620, R630 | pass |
| A158 | `bench then call mum` | none | nil | grammar-misfires#158 | MB | pass |
| A159 | `bench then call mum` | live workout | nil | grammar-misfires#159 | MB | pass |
| A160 | `bench 80x8 then call mum` | none | lift Bench Press 80x8 + nil for the rest (RC6 split) | grammar-misfires#160 | FX | miss (RC6) |
| A161 | `bench 80x8, call mum` | none | lift Bench Press 80x8 + nil for the rest (RC6 split) | grammar-misfires#161 | FX | miss (RC6) |
| A162 | `bench 80x8, call mum thu` | none | lift Bench Press 80x8 + task "Call mum" Thu 15 19:00 | grammar-misfires#162 | FX | wrong write (RC6) |
| A163 | `bench 80x8 and call mum thu` | none | lift Bench Press 80x8 + task "Call mum" Thu 15 19:00 | grammar-misfires#163 | FX | wrong write (RC6) |
| A164 | `squat 100x5 and buy milk` | none | lift Back Squat 100x5 + groceries [milk] | grammar-misfires#164 | FX | miss (RC6) |
| A165 | `leg day then dentist at 4` | none | task "Dentist" Fri 16 16:00 (workout part to the model) | grammar-misfires#165 | FX | wrong write (RC6) |
| A166 | `pull ups then call mum tonight` | none | task "Call mum" Thu 15 20:00 | grammar-misfires#166 | FX | wrong write (RC6) |
| A167 | `bench 3x5 at 80 then call mum at 7` | none | lift Bench Press 3x5 at 80 + task "Call mum" Thu 15 19:00 | grammar-misfires#167 | FX | wrong write (RC6) |
| A168 | `80x8 then call mum` | live workout | set 80x8 + nil for the rest | grammar-misfires#168 | FX | miss (RC6) |
| A169 | `8 and call mum at 7` | live workout | set 80x8 + task "Call mum" Thu 15 19:00 | grammar-misfires#169 | FX | wrong write (RC6) |
| A170 | `same, call mum thu` | live workout | set 80x8 (same) + task "Call mum" Thu 15, no time, alerts F (6:47 call) [N1] · now: set 80x8 (same) + task "Call mum" Thu 15 19:00 | grammar-misfires#170 | FX, T647 | wrong write (RC6) |
| A171 | `bench 80x8 dentist fri` | live workout | set 80x8 + task "Dentist" Fri 16, no time, alerts F (6:30 call) [N1] · now: set 80x8 + task "Dentist" Fri 16 09:00 | grammar-misfires#171 | FX, N620, R630 | wrong write (RC6) |
| A172 | `call mum then bench` | live workout | nil | grammar-misfires#172 | MB | pass |
| A173 | `squat 100 5, deadlift 140 3` | none | sets [Back Squat 100x5, Deadlift 140x3] | grammar-misfires#173 | MB | pass |
| A174 | `80x8, 80x8, 80x6` | live workout | sets, 3 into Bench Press | grammar-misfires#174 | MB | pass |
| A175 | `same?` | live workout | nil (question) | grammar-misfires#175 | C4 | pass |
| A176 | `bench 80x8?` | none | nil (question) | grammar-misfires#176 | C4 | pass |
| A177 | `done for today` | live workout | nil (finish the workout, model now) | grammar-misfires#177 | FX | wrong write (RC14) |
| A178 | `timer 90` | live workout | ignoredInWorkout | grammar-misfires#178 | MB | pass |
| A179 | `rest timer 90` | live workout | ignoredInWorkout | grammar-misfires#179 | MB | pass |
| A180 | `100` | live workout | nil (100 reads as a weight; ask) | grammar-misfires#180 | FX | wrong write (RC12) |
| A181 | `pull ups 3x8` | none | lift Pull-Up 3 sets x 8, bodyweight | grammar-misfires#181 | FX | wrong write (RC12) |
| A182 | `curls 15x12` | none | lift Dumbbell Curl 15x12 (or nil) | grammar-misfires#182 | FX | wrong write (RC12) |
| A183 | `bench 80x8 today` | none | lift Bench Press 80x8 | grammar-misfires#183 | FX | wrong write (RC12) |
| A184 | `bench 80x8 at 7` | none | nil (ask: set now or plan at 19:00) | grammar-misfires#184 | FX | wrong write (RC12) |
| A185 | `bench 3x5 at 80 tomorrow` | none | task "Bench 3x5 at 80" Fri 16, no time, alerts F (6:30 call) [N1] · now: task "Bench 3x5 at 80" Fri 16 09:00 | grammar-misfires#185 | MB, N620, R630 | pass |
| A186 | `next` | cook, 18:00 | cookStep next (GoToCookStep, step 3) | grammar-misfires#186, cook-timer-phrases#29 | MB | pass |
| A187 | `done` | cook, 18:00 | cookStep finish (FinishCooking; nothing flared) | grammar-misfires#187 | MB | pass |
| A188 | `timer 10` | cook, 18:00 | timer "Timer" 10, linked to the cook | grammar-misfires#188 | MB | pass |
| A189 | `8 mins` | cook, 18:00 | timer "Simmer" 8, linked (bare length takes the step's verb) | grammar-misfires#189 | K450 | miss (RC15) |
| A190 | `pasta 10` | cook, 18:00 | timer "Pasta" 10, linked | grammar-misfires#190, cook-timer-phrases#3 | K450 | miss (RC15) |
| A191 | `finished cooking` | cook, 18:00 | cookStep finish (FinishCooking) | grammar-misfires#191 | K450 | miss (RC15) |
| A192 | `buy parmesan` | cook, 18:00 | groceries [parmesan] | grammar-misfires#192 | MB | pass |
| A193 | `coffee with ravi at 7` | cook, 18:00 | task "Coffee with ravi" Thu 15 19:00 | grammar-misfires#193 | C1 | pass |
| A194 | `parmesan` | shop run | groceries [parmesan] | grammar-misfires#194, spoken-normaliser#45 | MB | pass |
| A195 | `2 lemons` | shop run | groceries [2 lemons] | grammar-misfires#195 | MB | pass |
| A196 | `call mum` | shop run | nil | grammar-misfires#196 | O410 | pass |
| A197 | `done` | shop run | nil (no write until a finish-shop action) | grammar-misfires#197 | FX | pass |
| A198 | `shop` | shop run | nil (the shop is already on) | grammar-misfires#198 | MB | pass |
| A199 | `thanks` | shop run | nil | grammar-misfires#199 | MB | pass |
| A200 | `buy milk` | shop run | groceries [milk] | grammar-misfires#200 | O410 | pass |
| A201 | `finished shopping` | shop run | nil (no write until a finish-shop action) | grammar-misfires#201 | FX | pass |
| A202 | `pick up dry cleaning` | shop run | nil | grammar-misfires#202 | O410 | pass |
| A203 | `sun cream` | shop run | groceries [sun cream] | grammar-misfires#203 | MB | pass |
| A204 | `sat nav charger` | shop run | groceries [sat nav charger] | grammar-misfires#204 | MB | pass |
| A205 | `coffee with ravi at 7` | shop run | task "Coffee with ravi" Thu 15 19:00 | grammar-misfires#205 | C1 | pass |
| A206 | `what else` | shop run | nil (question) | grammar-misfires#206 | MB | pass |
| A207 | `mum's birthday sat` | shop run | task "Mum's birthday" Sat 17, no time, alerts F (6:30 call) [N1] · now: task "Mum's birthday" Sat 17 09:00 | grammar-misfires#207 | MB, N620, R630 | pass |
| A208 | `bench 80x8` | shop run | lift Bench Press 80x8 | grammar-misfires#208 | MB | pass |
| A209 | `is the gym open sat` | none | nil (question) | grammar-misfires#209 | C4 | pass |
| A210 | `is the gym open sat?` | none | nil (question) | grammar-misfires#210 | C4 | pass |
| A211 | `dentist thu?` | none | nil (question) | grammar-misfires#211 | C4 | pass |
| A212 | `who's free sat` | none | nil (question) | grammar-misfires#212 | C4 | pass |
| A213 | `do i have anything tomorrow` | none | nil (question) | grammar-misfires#213 | C4 | pass |
| A214 | `can i move leg day to fri` | none | nil (question) | grammar-misfires#214 | C4 | pass |
| A215 | `should i train today` | none | nil (question) | grammar-misfires#215 | C4 | pass |
| A216 | `any plans sat` | none | nil (question) | grammar-misfires#216 | C4 | wrong write (RC5) |
| A217 | `what's on thu` | none | nil (question) | grammar-misfires#217 | MB | pass |
| A218 | `show ravi the flat sat` | none | task "Show ravi the flat" Sat 17, no time, alerts F (6:30 call) [N1] · now: task "Show ravi the flat" Sat 17 09:00 | grammar-misfires#218 | MB, N620, R630 | pass |
| A219 | `dentist on friday` | none | task "Dentist" Fri 16, no time, alerts F (6:30 call) [N1] · now: task "Dentist" Fri 16 09:00 | grammar-misfires#219 | MB, N620, R630 | pass |
| A220 | `report by fri` | none | task "Report" Fri 16, no time, alerts F (6:30 call) [N1] · now: task "Report" Fri 16 09:00 | grammar-misfires#220 | MB, N620, R630 | pass |
| A221 | `gym this sat` | none | task "Gym" Sat 17, no time, alerts F (6:30 call) [N1] · now: task "Gym" Sat 17 09:00 | grammar-misfires#221 | MB, N620, R630 | pass |
| A222 | `dentist next fri` | none | task "Dentist" Fri 23 Oct, no time, alerts F (5:58 call: next week's Friday; 6:30 call) [N1] · now: task "Dentist" Fri 23 Oct 09:00 | grammar-misfires#222 | FX, D558, N620, R630 | wrong write (RC7) |
| A223 | `packing list for sat` | none | task "Packing list" Sat 17, no time, alerts F (6:30 call) [N1] · now: task "Packing list" Sat 17 09:00 | grammar-misfires#223 | MB, N620, R630 | pass |
| A224 | `remind me tomorrow to call mum` | none | task "Call mum" Fri 16 09:00, alerts T (6:30 call) | grammar-misfires#224, reminders#R14 | MB, R630 | pass |
| A225 | `remind me to call mum` | none | task "Call mum" Later | grammar-misfires#225 | MB | pass |
| A226 | `todo: renew passport` | none | task "Renew passport" Later | grammar-misfires#226 | MB | pass |
| A227 | `call mum, thu` | none | task "Call mum" Thu 15, no time, alerts F (6:47 call) [N1] · now: task "Call mum" Thu 15 19:00 | grammar-misfires#227 | MB, T647 | pass |
| A228 | `fix sat nav` | none | nil | grammar-misfires#228 | FX | wrong write (RC10) |
| A229 | `sun cream` | none | nil (or groceries [sun cream]) | grammar-misfires#229 | FX | wrong write (RC10) |
| A230 | `add sun cream to packing` | none | nil (add to Packing, model) | grammar-misfires#230 | FX | wrong write (RC10) |
| A231 | `list: packing` | none | list "Packing" | grammar-misfires#231 | MB | pass |
| A232 | `list the car on ebay sat` | none | task "List the car on ebay" Sat 17, no time, alerts F (6:30 call) [N1] · now: task "List the car on ebay" Sat 17 09:00 | grammar-misfires#232 | MB, N620, R630 | pass |
| A233 | `note: call mum sat` | none | note "call mum sat" | grammar-misfires#233 | MB | pass |
| A234 | `note to self, eighty felt easy` | none | note "eighty felt easy" | grammar-misfires#234 | FX | wrong write (RC16) |
| A235 | `carbonara thu` | none | cook Spaghetti carbonara Thu 15, no time, alerts F (6:47 call) [N1] · now: cook Spaghetti carbonara Thu 15 19:00 | grammar-misfires#235 | THU, T647 | pass |
| A236 | `timer 10` | none | timer "Timer" 10 | grammar-misfires#236 | MB | pass |
| A237 | `call mum` | none | return the open task "Call mum" [People] · now: nil | grammar-misfires#237, people#13 | PA | pass |
| A238 | `dentist fri 10am` | none | task "Dentist" Fri 16 10:00 | grammar-misfires#238 | MB | pass |
| A239 | `get oat milk` | none | groceries [oat milk] | grammar-misfires#240 | MB | pass |
| A240 | `milk, eggs, bread` | none | groceries [milk, eggs, bread] | grammar-misfires#241 | MB | pass |
| A241 | `2 lemons, a bunch of coriander` | none | groceries [2 lemons, a bunch of coriander] | grammar-misfires#242 | MB | pass |
| A242 | `buy 500 g chicken thighs` | none | groceries [500 g chicken thighs] | grammar-misfires#243 | MB | pass |
| A243 | `get 6 eggs and butter` | none | groceries [6 eggs, butter] | grammar-misfires#244 | MB | pass |
| A244 | `groceries: bin bags` | none | groceries [bin bags] | grammar-misfires#245 | MB | pass |
| A245 | `add to groceries: kitchen roll` | none | groceries [kitchen roll] | grammar-misfires#246 | MB | pass |
| A246 | `buy chalk` | none | groceries [chalk] | grammar-misfires#247 | B430 | pass |
| A247 | `buy bench scraper` | none | groceries [bench scraper] | grammar-misfires#248 | B430 | pass |
| A248 | `get squat rack hooks` | none | groceries [squat rack hooks] | grammar-misfires#249 | B430 | pass |
| A249 | `buy press n seal` | none | groceries [press n seal] | grammar-misfires#250 | B430 | pass |
| A250 | `buy curl cream` | none | groceries [curl cream] | grammar-misfires#251 | B430 | pass |
| A251 | `2 tins tomatoes, pasta, parmesan` | none | groceries [2 tins tomatoes, pasta, parmesan] | grammar-misfires#252 | MB | pass |
| A252 | `buy coffee beans 1 kg` | none | groceries [coffee beans 1 kg] | grammar-misfires#253 | MB | pass |
| A253 | `get bananas x6` | none | groceries [bananas x6] | grammar-misfires#254 | MB | pass |
| A254 | `buy 3 x 400 g tins chickpeas` | none | groceries [3 x 400 g tins chickpeas] | grammar-misfires#255 | MB | pass |
| A255 | `buy sat nav charger` | none | groceries [sat nav charger] | grammar-misfires#257 | B430 | pass |
| A256 | `buy cake candles wed` | none | task "Buy cake candles" Wed 21, no time, alerts F (6:30 call) [N1] · now: task "Buy cake candles" Wed 21 09:00 | grammar-misfires#258 | MB, N620, R630 | pass |
| A257 | `get tonic water` | none | groceries [tonic water] | grammar-misfires#259 | MB | pass |
| A258 | `buy tomorrow's bread` | none | groceries [bread] | grammar-misfires#260 | FX | wrong write (RC19) |
| A259 | `timer pasta 10` | none | timer "Pasta" 10 (no cook to link) | grammar-misfires#261, cook-timer-phrases#39 | MB | pass |
| A260 | `10 min timer` | none | timer "Timer" 10 | grammar-misfires#262 | MB | pass |
| A261 | `timer 90 sec` | none | timer "Timer" 1.5 (line reads "90 sec") | grammar-misfires#263 | K450 | pass |
| A262 | `rice timer 18` | none | timer "Rice" 18 | grammar-misfires#264 | MB | pass |
| A263 | `dough rest timer 45` | none | timer "Dough rest" 45 | grammar-misfires#265 | MB | pass |
| A264 | `cook carbonara` | none | cook Spaghetti carbonara (now) | grammar-misfires#266 | MB | pass |
| A265 | `make dal` | none | cook Weeknight dal (now) | grammar-misfires#267 | MB | pass |
| A266 | `cook chilli` | none | cook Chilli con carne (now) | grammar-misfires#268 | MB | pass |
| A267 | `carbonara thursday` | none | cook Spaghetti carbonara Thu 15, no time, alerts F (6:47 call) [N1] · now: cook Spaghetti carbonara Thu 15 19:00 | grammar-misfires#269 | THU, T647 | pass |
| A268 | `cook dal tonight` | none | cook Weeknight dal Thu 15 20:00 | grammar-misfires#270 | MB | pass |
| A269 | `make chilli sat` | none | cook Chilli con carne Sat 17, no time, alerts F (6:47 call) [N1] · now: cook Chilli con carne Sat 17 09:00 | grammar-misfires#271 | MB, T647 | pass |
| A270 | `shop` | none | shop (start the shop) | grammar-misfires#272 | MB | pass |
| A271 | `out of milk` | none | groceries [milk] | grammar-misfires#273 | FX | miss (RC17) |
| A272 | `need eggs` | none | groceries [eggs] | grammar-misfires#274 | FX | miss (RC17) |
| A273 | `we're out of coffee` | none | groceries [coffee] | grammar-misfires#275 | FX | miss (RC17) |
| A274 | `buy 1 (400 g) tin coconut milk` | none | groceries [1 (400 g) tin coconut milk] | grammar-misfires#276 | MB | pass |
| A275 | `buy milk` | live workout | groceries [milk] | grammar-misfires#277 | MB | pass |
| A276 | `3 lemons` | live workout | groceries [3 lemons], never a set | grammar-misfires#278 | FX | miss (RC18) |
| A277 | `buy present for mum fri` | none | task "Buy present for mum" Fri 16, no time, alerts F (6:30 call) [N1] · now: task "Buy present for mum" Fri 16 09:00 | grammar-misfires#280 | MB, N620, R630 | pass |
| A278 | `get haircut` | none | task "Get haircut" Later | grammar-misfires#281 | C3 | pass |
| A279 | `get car washed` | none | task "Get car washed" Later | grammar-misfires#282 | C3 | pass |
| A280 | `buy train tickets` | none | task "Buy train tickets" Later | grammar-misfires#283 | B430 | pass |
| A281 | `get flu jab` | none | task "Get flu jab" Later | grammar-misfires#284 | C3 | pass |
| A282 | `buy flowers for Anu saturday` | none | task "Buy flowers for Anu" Sat 17, no time, alerts F (6:30 call) [N1] · now: task "Buy flowers for Anu" Sat 17 09:00 | grammar-misfires#285 | MB, N620, R630 | pass |
| A283 | `get milk on the way home tomorrow` | none | task "Get milk on the way home" Fri 16, no time, alerts F (6:30 call) [N1] · now: task "Get milk on the way home" Fri 16 09:00 | grammar-misfires#286 | MB, N620, R630 | pass |
| A284 | `gifts: mug for anu` | none | list add Gifts [mug for anu] [Lists 8] · now: nil | grammar-misfires#287 | FX | pass |
| A285 | `packing: charger` | none | list add Packing [charger] [Lists 8] · now: nil | grammar-misfires#288 | FX | pass |
| A286 | `errands: return parcel thu` | none | list add Errands [return parcel] dated Thu 15 [Lists 8] · now: nil | grammar-misfires#289 | FX | wrong write (RC20) |
| A287 | `get back to Sam` | none | nil | grammar-misfires#290 | MB | pass |
| A288 | `get ready for gym` | none | nil | grammar-misfires#291 | MB | pass |
| A289 | `buy time with the landlord` | none | task "Buy time with the landlord" Later | grammar-misfires#292 | B430 | wrong write (RC3) |
| A290 | `get the bins out` | none | nil | grammar-misfires#293 | MB | pass |
| A291 | `buy new trainers` | none | task "Buy new trainers" Later | grammar-misfires#294 | B430 | pass |
| A292 | `get a new phone case` | none | task "Get a new phone case" Later | grammar-misfires#295 | C3 | pass |
| A293 | `buy a birthday cake for dad sun` | none | task "Buy a birthday cake for dad" Sun 18, no time, alerts F (6:30 call) [N1] · now: task "Buy a birthday cake for dad" Sun 18 09:00 | grammar-misfires#296 | MB, N620, R630 | pass |
| A294 | `note buy milk` | none | note "buy milk" | grammar-misfires#297 | MB | pass |
| A295 | `remind me to buy milk at 6` | none | task "Buy milk" Fri 16 18:00 | grammar-misfires#298 | C1, C5 | pass |

### B. Spoken phrases (normalised text) (72 rows)

| id | phrase | context | expected parse | source rows | decision | status |
|---|---|---|---|---|---|---|
| B296 | `85 x 6` | live workout | set 85x6 | spoken-normaliser#1 | MB | pass |
| B297 | `107.5 x 3` | live workout | set 107.5x3 | spoken-normaliser#2 | MB | pass |
| B298 | `Squat 102.5 x 5` | none | lift Back Squat 102.5x5 | spoken-normaliser#3 | MB | pass |
| B299 | `80 kg x 8` | live workout | set 80x8 | spoken-normaliser#4 | MB | pass |
| B300 | `same again` | live workout | set 80x8 (same) | spoken-normaliser#5 | MB | pass |
| B301 | `Same weight one more rep` | live workout | nil (a relative rule later may make 80x9) | spoken-normaliser#6 | FX | pass |
| B302 | `drop to 70` | live workout | nil (drop with no reps goes to the model) (7:06 call) | spoken-normaliser#7 | T706 | pass |
| B303 | `80 x 8 @8` | live workout | set 80x8, RPE 8 | spoken-normaliser#8 | T706 | miss (RPE) |
| B304 | `82.5 x 6 @9` | live workout | set 82.5x6, RPE 9 | spoken-normaliser#9 | T706 | miss (RPE) |
| B305 | `85 x 5 @9.5` | live workout | set 85x5, RPE 9.5 | spoken-normaliser#10 | T706 | miss (RPE) |
| B306 | `same @9` | live workout | set 80x8 (same), RPE 9 | spoken-normaliser#11 | T706 | miss (RPE) |
| B307 | `Bench 3x8 at 80` | none | lift Bench Press 3x8 at 80 | spoken-normaliser#12 | MB | pass |
| B308 | `Deadlift 2 plates for 5` | none | nil | spoken-normaliser#13 | MB | pass |
| B309 | `8` | live workout | set 80x8 (reps only) | spoken-normaliser#14, upkeep#37 | MB | pass |
| B310 | `add 2.5` | live workout | nil (`add 2.5` goes to the model) (7:06 call) | spoken-normaliser#15 | T706 | pass |
| B311 | `80 x 8, 80 x 8, 80 x 6` | live workout | sets, 3 into Bench Press | spoken-normaliser#16 | MB | pass |
| B312 | `Squat 100, 5` | none | lift Back Squat 100x5 | spoken-normaliser#17 | MB | pass |
| B313 | `80 x 8` | live workout | set 80x8 | spoken-normaliser#18, spoken-normaliser#19, spoken-normaliser#27, spoken-normaliser#28, spoken-normaliser#31, spoken-normaliser#34 | MB | pass |
| B314 | `3x10 Bench at 80` | none | lift Bench Press 3x10 at 80 | spoken-normaliser#20 | MB | pass |
| B315 | `Bench 80 kg, 8` | none | lift Bench Press 80x8 | spoken-normaliser#21 | MB | pass |
| B316 | `185 lb x 5` | live workout | set 83.9 kg x 5, unit lb | spoken-normaliser#22, money#31 | MB | pass |
| B317 | `Deadlift 225 lb x 3` | none | lift Deadlift 225 lb x 3 | spoken-normaliser#23 | MB | pass |
| B318 | `I weigh 182 lb` | none | nil (body weight via the model) | spoken-normaliser#24 | MB | pass |
| B319 | `Eleven stone four` | none | nil | spoken-normaliser#25 | MB | pass |
| B320 | `£12.50 at Tesco` | none | spend 12.50 GBP, note "Tesco" [Money] · now: nil | spoken-normaliser#26 | MA | pass |
| B321 | `80 x 7` | live workout | set 80x7 | spoken-normaliser#29, spoken-normaliser#32 | MB | pass |
| B322 | `Come on come on 80 x 7` | live workout | nil | spoken-normaliser#30 | MB | pass |
| B323 | `(empty string)` | live workout | nil (no capture) | spoken-normaliser#33 | MB | pass |
| B324 | `Test the smoke alarm Saturday` | none | task "Test the smoke alarm" Sat 17, no time, alerts F (6:30 call) [N1] · now: task "Test the smoke alarm" Sat 17 09:00 | spoken-normaliser#35 | MB, N620, R630 | pass |
| B325 | `I'd like a reminder for Friday to book the MOT` | none | nil (model makes "Book the MOT" Fri) | spoken-normaliser#36 | FX | wrong write (NRM) |
| B326 | `Remind me to call Ravi tomorrow` | none | task "Call Ravi" Fri 16 09:00, alerts T (6:30 call) | spoken-normaliser#37 | MB, R630 | pass |
| B327 | `Buy 2 lemons and some milk` | none | groceries [2 lemons, some milk] | spoken-normaliser#38 | MB | pass |
| B328 | `2 lemons and some milk` | none | nil | spoken-normaliser#39 | MB | pass |
| B329 | `Get 12 eggs` | none | groceries [12 eggs] | spoken-normaliser#40 | MB | pass |
| B330 | `Buy 6 eggs and a pint of milk` | none | groceries [6 eggs, a pint of milk] | spoken-normaliser#41 | MB | pass |
| B331 | `By 4 lemons and a bag of rice` | none | nil | spoken-normaliser#42 | MB | pass |
| B332 | `By 5pm send the invoice` | none | task "Send the invoice" Fri 16 17:00 | spoken-normaliser#43 | C5 | pass |
| B333 | `Buy 1 kg atta and 0.5 kg dahi` | none | groceries [1 kg atta, 0.5 kg dahi] | spoken-normaliser#44 | MB | pass |
| B334 | `Add 2 tins of chickpeas` | cook, 18:00 | groceries [2 tins of chickpeas] | spoken-normaliser#46 | T706 | miss (ADD) |
| B335 | `Remind me to call the bank Friday` | none | task "Call the bank" Fri 16 09:00, alerts T (6:30 call) | spoken-normaliser#47 | MB, R630 | pass |
| B336 | `Remind me to renew the passport Tuesday` | none | task "Renew the passport" Tue 20 09:00, alerts T (6:30 call) | spoken-normaliser#48 | MB, R630 | pass |
| B337 | `Call the dentist tomorrow 9am` | none | task "Call the dentist" Fri 16 09:00 | spoken-normaliser#49 | MB | pass |
| B338 | `Remind me to take the chicken out in 20 min` | none | task "Take the chicken out" Thu 15 18:30, alerts T (7:06 call) | spoken-normaliser#50 | T706 | wrong write (RELT) |
| B339 | `Pay the window cleaner Thursday` | none | task "Pay the window cleaner" Thu 15, no time, alerts F (6:47 call) [N1] · now: task "Pay the window cleaner" Thu 15 19:00 | spoken-normaliser#51 | THU, T647 | pass |
| B340 | `Remind me to put the bins out Thursday at 8` | none | task "Put the bins out" Thu 15 20:00 | spoken-normaliser#52 | C1, THU | pass |
| B341 | `Dentist on the 20th at 3:30` | none | task "Dentist" Tue 20 15:30 | spoken-normaliser#53 | C1 | wrong write (ORD) |
| B342 | `Remind me to send the form tomorrow` | none | task "Send the form" Fri 16 09:00, alerts T (6:30 call) | spoken-normaliser#55 | MB, R630 | pass |
| B343 | `Remind me day after tomorrow to pay rent` | none | task "Pay rent" Sat 17 09:00, alerts T (6:30 call) | spoken-normaliser#56 | T706, R630 | wrong write (RELT) |
| B344 | `Prepone the dentist to Wednesday` | none | nil (model reschedules; or reschedule Dentist Wed 21 10:00 if `prepone` joins the shape) | spoken-normaliser#57 | FX | wrong write (RC13) |
| B345 | `Remind me to clean the car Saturday` | none | task "Clean the car" Sat 17 09:00, alerts T (6:30 call) | spoken-normaliser#58 | MB, R630 | pass |
| B346 | `Remind me to collect the courier tomorrow` | none | task "Collect the courier" Fri 16 09:00, alerts T (6:30 call) | spoken-normaliser#59 | MB, R630 | pass |
| B347 | `Remind me 2 days before the MOT` | none | nil | spoken-normaliser#60 | T706 | wrong write (RELT) |
| B348 | `Spent 12.50 at Tesco` | none | spend 12.50, category tesco [Money] · now: nil | spoken-normaliser#61, money#19 | MA | pass |
| B349 | `Spent 1250 at Tesco` | none | ambiguous ghost "12.50 or 1250?" (spoken digits) [Money] · now: nil | spoken-normaliser#62 | MA | pass |
| B350 | `Lunch was £10` | none | nil (model) | spoken-normaliser#63 | MA | pass |
| B351 | `20 quid for petrol` | none | spend 20 GBP, note "petrol" [Money] · now: nil | spoken-normaliser#64 | MA | pass |
| B352 | `Spent 1500 on petrol` | none | spend 1500, note "petrol" [Money] · now: nil | spoken-normaliser#65 | MA | pass |
| B353 | `Spent 100000 on the bike` | none | spend 100000, note "the bike" [Money] · now: nil | spoken-normaliser#66 | MA | pass |
| B354 | `Paid 120000 rs deposit` | none | spend 120000 INR, note "deposit", no chore [Money] · now: nil | spoken-normaliser#67 | P434 | pass |
| B355 | `Spent 4 quid at seven eleven` | none | spend 4 GBP, note "seven eleven" [Money] · now: nil | spoken-normaliser#68 | MA | pass |
| B356 | `note: The bar felt heavy today.` | none | note "The bar felt heavy today." | spoken-normaliser#69 | MB | pass |
| B357 | `note: eighty felt easy` | none | note "eighty felt easy" | spoken-normaliser#70 | MB | pass |
| B358 | `note: the squat rack in bay two is broken` | none | note "the squat rack in bay two is broken" | spoken-normaliser#71 | MB | pass |
| B359 | `85 x 8` | live workout | set 85x8 | spoken-normaliser#72 | MB | pass |
| B360 | `80 x 9` | live workout | set 80x9 | spoken-normaliser#73 | MB | pass |
| B361 | `Buy oat milk, no wait, almond milk` | none | nil (skip grammar; model adds almond milk) | spoken-normaliser#74 | FX | wrong write (NRM) |
| B362 | `Remind me to eat five a day` | none | task "Eat five a day" Later | spoken-normaliser#75 | MB | pass |
| B363 | `Meeting in Room 101 at 3` | none | task "Meeting in Room 101" Fri 16 15:00 | spoken-normaliser#76 | C1, C5 | pass |
| B364 | `Book a table for 2 at 7` | none | task "Book a table for 2" Thu 15 19:00 | spoken-normaliser#77 | C1 | pass |
| B365 | `Work nine to five on Saturday` | none | task "Work nine to five" Sat 17, no time, alerts F (6:30 call) [N1] · now: task "Work nine to five" Sat 17 09:00 | spoken-normaliser#78 | MB, N620, R630 | pass |
| B366 | `Two-three more sets` | live workout | nil | spoken-normaliser#79 | MB | pass |
| B367 | `Remind me to water the plants 2-3 times a week` | none | task "Water the plants 2-3 times a week" Later | spoken-normaliser#80 | MB | pass |

### C. Reschedule and time forms (72 rows)

| id | phrase | context | expected parse | source rows | decision | status |
|---|---|---|---|---|---|---|
| C368 | `Move the dentist to Friday.` | none, tasks | reschedule Dentist Fri 16 10:00 | reschedule-time-rows#A2 | FX | pass |
| C369 | `move my haircut to tmrw` | none, tasks | reschedule Haircut Fri 16 17:00 | reschedule-time-rows#A3 | FX | pass |
| C370 | `push dentist till monday` | none, tasks | reschedule Dentist Mon 19 10:00 | reschedule-time-rows#A4 | FX | pass |
| C371 | `shift dentist to sun` | none, tasks | reschedule Dentist Sun 18 10:00 | reschedule-time-rows#A5 | FX | pass |
| C372 | `move dentist to 9:30` | none, tasks | reschedule Dentist Sat 17 09:30 (another day: AM) | reschedule-time-rows#A7 | T441 | wrong write (RC13) |
| C373 | `move dentist to 11` | none, tasks | reschedule Dentist Sat 17 11:00 (5:58 call) | reschedule-time-rows#A8 | C1, T441, D558 | miss (RC13) |
| C374 | `move dentist to 3` | none, tasks | reschedule Dentist Sat 17 15:00 (5:58 call) | reschedule-time-rows#A9 | C1, D558 | miss (RC13) |
| C375 | `move dentist to sat 2pm` | none, tasks | reschedule Dentist Sat 17 14:00 | reschedule-time-rows#A10 | MB | pass |
| C376 | `move dentist to fri at 4` | none, tasks | reschedule Dentist Fri 16 16:00 | reschedule-time-rows#A11 | C1 | pass |
| C377 | `push the dentist to thu 3pm` | none, tasks | reschedule Dentist Thu 22 15:00 (named weekday means that weekday) | reschedule-time-rows#A12 | T441 | pass |
| C378 | `move dentist to tonight` | none, tasks | reschedule Dentist Thu 15 20:00 | reschedule-time-rows#A13 | MB | pass |
| C379 | `move dentist to today` | none, tasks | reschedule Dentist Thu 15, no time, alerts F (6:47 call) [N1] · now: reschedule Dentist Thu 15 19:00 (kept 10:00 has passed) | reschedule-time-rows#A14 | C5, T647, T650 | wrong write (RC13) |
| C380 | `move haircut to 7` | none, tasks | reschedule Haircut Thu 15 19:00 (5:58 call) | reschedule-time-rows#A15 | C1, D558 | miss (RC13) |
| C381 | `move pay rent to 7pm` | none, tasks | reschedule Pay rent Fri 16 19:00 | reschedule-time-rows#A16 | FX | pass |
| C382 | `move pay rent to 5pm` | none, tasks | reschedule Pay rent Fri 16 17:00 | reschedule-time-rows#A17 | FX | pass |
| C383 | `move bins out to 9:30` | none, tasks | reschedule Bins out Thu 15 21:30 | reschedule-time-rows#A18 | C1 | pass |
| C384 | `move call mum to fri` | none, tasks | reschedule Call mum Fri 16, no time, alerts F (6:30 call) [N1] · now: reschedule Call mum Fri 16 09:00 | reschedule-time-rows#A19 | MB, N620, R630 | pass |
| C385 | `move call to fri` | none, tasks | nil (two open matches) | reschedule-time-rows#A21 | MB | pass |
| C386 | `move call bank to fri` | none, tasks | nil (task is done) | reschedule-time-rows#A22 | MB | pass |
| C387 | `move call mum to 7` | none, tasks | reschedule Call mum Thu 15 19:00 (5:58 call) | reschedule-time-rows#A20 | C1, D558 | miss (RC13) |
| C388 | `push dentist to next week` | none, tasks | reschedule Dentist Sat 24 10:00 (5:58 call) | reschedule-time-rows#A23 | FX, D558 | miss (RC13) |
| C389 | `move dentist to next fri` | none, tasks | reschedule Dentist Fri 23 Oct 10:00 (next week's Friday, time kept) (5:58 call) | reschedule-time-rows#A24 | FX, D558 | wrong write (RC7) |
| C390 | `move pay rent to sat morning` | none, tasks | reschedule Pay rent Sat 17 09:00 | reschedule-time-rows#A25 | T441 | miss (RC11) |
| C391 | `push dentist to later` | none, tasks | reschedule Dentist to Later (no date) (5:58 call) | reschedule-time-rows#A26 | FX, D558 | miss (RC13) |
| C392 | `push to tmrw` | none, tasks | reschedule the task on Now to Fri 16, its time kept (6:50 call, R13h) | reschedule-time-rows#A27 | FX, T650 | wrong write (RC13) |
| C393 | `push it to fri` | none, tasks | nil | reschedule-time-rows#A28 | MB | pass |
| C394 | `do it later` | none, tasks | nil | reschedule-time-rows#A29 | MB | pass |
| C395 | `can you move the dentist to friday` | none, tasks | reschedule Dentist Fri 16 10:00 (5:58 call) | reschedule-time-rows#A30 | FX, D558 | miss (RC13) |
| C396 | `move dentist to fri please` | none, tasks | reschedule Dentist Fri 16 10:00 (5:58 call) | reschedule-time-rows#A31 | FX, D558 | miss (RC13) |
| C397 | `moved dentist to fri` | none, tasks | reschedule Dentist Fri 16 10:00 (R13j: `moved` is a reschedule verb); never a note on Fri 9 (5:58 call) | reschedule-time-rows#A32 | FX, D558 | wrong write (RC13) |
| C398 | `is the dentist still on fri` | none, tasks | nil (question) | reschedule-time-rows#A33 | C4 | pass |
| C399 | `push ups to failure` | none, tasks | nil | reschedule-time-rows#A34 | MB | pass |
| C400 | `move 80 to 82.5` | live workout | nil | reschedule-time-rows#A35 | MB | pass |
| C401 | `move money to savings fri` | none, tasks | nil | reschedule-time-rows#A36 | MB | pass |
| C402 | `shift 8 to 4 tomorrow` | none, tasks | nil | reschedule-time-rows#A37 | MB | pass |
| C403 | `move haircut to 8` | none, tasks, 09:00 | reschedule Haircut Thu 15 20:00 (5:58 call) | reschedule-time-rows#A38 | C1, D558 | miss (RC13) |
| C404 | `move bins out to 11` | none, tasks, 23:30 | reschedule Bins out Fri 16 11:00 (5:58 call) | reschedule-time-rows#A39 | C1, C5, D558 | miss (RC13) |
| C405 | `move haircut to tonight` | none, tasks, 23:30 | reschedule Haircut Fri 16 20:00 | reschedule-time-rows#A40 | C5, T441 | pass |
| C406 | `call mum at 7:30 pm` | none | task "Call mum" Thu 15 19:30 | reschedule-time-rows#B3 | T441 | wrong write (RC11) |
| C407 | `call mum 7.30pm` | none | task "Call mum" Thu 15 19:30 | reschedule-time-rows#B4 | T441 | miss (RC11) |
| C408 | `call mum 7:30pm` | none | task "Call mum" Thu 15 19:30 | reschedule-time-rows#B5 | MB | pass |
| C409 | `call mum at 7.30` | none | task "Call mum" Thu 15 19:30 | reschedule-time-rows#B6 | C1 | miss (RC11) |
| C410 | `dinner 7.30` | none | nil (a bare H.MM stays a number) | reschedule-time-rows#B8 | FX | pass |
| C411 | `dentist at 4.15` | none | task "Dentist" Fri 16 16:15 | reschedule-time-rows#B9 | C1, C5 | miss (RC11) |
| C412 | `call mum half past 7` | none | task "Call mum" Thu 15 19:30 | reschedule-time-rows#B11 | C1 | miss (RC11) |
| C413 | `call mum quarter past 7` | none | task "Call mum" Thu 15 19:15 | reschedule-time-rows#B12 | C1 | miss (RC11) |
| C414 | `call mum half 6` | none | task "Call mum" Thu 15 18:30 | reschedule-time-rows#B13 | C1 | miss (RC11) |
| C415 | `call mum half 5` | none | task "Call mum" Fri 16 17:30 | reschedule-time-rows#B14 | C1, C5 | miss (RC11) |
| C416 | `call mum tonight at half 8` | none | task "Call mum" Thu 15 20:30 | reschedule-time-rows#B15 | C1 | wrong write (RC11) |
| C417 | `call mum at 7 tonight` | none | task "Call mum" Thu 15 19:00 | reschedule-time-rows#B16 | C1 | pass |
| C418 | `call mum tmrw morning` | none | task "Call mum" Fri 16 09:00 | reschedule-time-rows#B17 | FX | wrong write (RC11) |
| C419 | `dentist sat afternoon` | none | task "Dentist" Sat 17 14:00 | reschedule-time-rows#B18 | FX | wrong write (RC11) |
| C420 | `call mum this evening` | none | task "Call mum" Thu 15 19:00 (evening under way: next whole hour) | reschedule-time-rows#B19 | T441, T650 | miss (RC11) |
| C421 | `gym in the morning` | none | task "Gym" Fri 16 09:00 | reschedule-time-rows#B20 | C5 | miss (RC11) |
| C422 | `call mum in 2 hours` | none | task "Call mum" Thu 15 20:10, alerts T (7:06 call) | reschedule-time-rows#B21 | T706 | miss (RELT) |
| C423 | `call mum in 20 mins` | none | task "Call mum" Thu 15 18:30, alerts T (7:06 call) | reschedule-time-rows#B22 | T706 | miss (RELT) |
| C424 | `remind me in 2 hours to call mum` | none | task "Call mum" Thu 15 20:10, alerts T (7:06 call) | reschedule-time-rows#B23 | T706 | wrong write (RELT) |
| C425 | `remind me to call mum in an hour` | none | task "Call mum" Thu 15 19:10, alerts T (7:06 call) | reschedule-time-rows#B24 | T706 | wrong write (RELT) |
| C426 | `call mum at seven` | none | task "Call mum" Thu 15 19:00 | reschedule-time-rows#B25 | C1 | miss (RC11) |
| C427 | `call mum at noon` | none | task "Call mum" Fri 16 12:00 | reschedule-time-rows#B26 | C5 | pass |
| C428 | `rest 2:30` | live workout | ignoredInWorkout | reschedule-time-rows#B28 | MB | pass |
| C429 | `ran 5k in 22:30` | none | note "Ran 5k in 22:30" Thu 15, never a task | reschedule-time-rows#B29 | C2 | wrong write (RC2) |
| C430 | `paid 12.50 at 12.30` | none | spend 12.50 Thu 15 12:30 (12.50 the amount, 12.30 the time) [Money] · now: nil; never a task (5:58 call) | reschedule-time-rows#B30 | P434, D558 | pass |
| C431 | `buy 2 x 6 rolls` | none | groceries [2 x 6 rolls] | reschedule-time-rows#B31 | MB | pass |
| C432 | `buy 7up` | none | groceries [7up] | reschedule-time-rows#B32 | MB | pass |
| C433 | `call mum at 7.30` | none, 09:00 | task "Call mum" Thu 15 19:30 | reschedule-time-rows#B34 | C1 | miss (RC11) |
| C434 | `call mum this afternoon` | none, 09:00 | task "Call mum" Thu 15 14:00 | reschedule-time-rows#B35 | T441 | miss (RC11) |
| C435 | `call mum in the morning` | none, 09:00 | task "Call mum" Fri 16 09:00 | reschedule-time-rows#B36 | C5 | miss (RC11) |
| C436 | `call mum half 11` | none, 23:30 | task "Call mum" Fri 16 11:30 | reschedule-time-rows#B37 | C1, C5 | miss (RC11) |
| C437 | `call mum tonight` | none, 23:30 | task "Call mum" Fri 16 20:00 | reschedule-time-rows#B38 | C5, T441 | pass |
| C438 | `call mum in 2 hours` | none, 23:30 | task "Call mum" Fri 16 01:30, alerts T (7:06 call) | reschedule-time-rows#B39 | T706 | miss (RELT) |
| C439 | `call mum midnight` | none, 23:30 | task "Call mum" Fri 16 00:00 | reschedule-time-rows#B40 | FX | miss (RC11) |

### D. Cook timers (37 rows)

| id | phrase | context | expected parse | source rows | decision | status |
|---|---|---|---|---|---|---|
| D440 | `pasta 9 minutes` | cook, 18:00 | timer "Pasta" 9, linked | cook-timer-phrases#1 | K450 | miss (RC15) |
| D441 | `9 min` | cook, 18:00 | timer "Simmer" 9, linked (step verb label) | cook-timer-phrases#2 | K450 | miss (RC15) |
| D442 | `eggs 6` | cook, 18:00 | timer "Eggs" 6, linked | cook-timer-phrases#4 | K450 | miss (RC15) |
| D443 | `pasta for 9 minutes` | cook, 18:00 | timer "Pasta" 9, linked | cook-timer-phrases#5 | K450 | miss (RC15) |
| D444 | `9 minutes on the pasta` | cook, 18:00 | timer "Pasta" 9, linked | cook-timer-phrases#6 | K450 | miss (RC15) |
| D445 | `oven 25` | cook, 18:00 | timer "Oven" 25, linked | cook-timer-phrases#7 | K450 | miss (RC15) |
| D446 | `timer for the oven 25` | cook, 18:00 | timer "Oven" 25, linked | cook-timer-phrases#8 | K450 | wrong write (RC15) |
| D447 | `oven 180 for 25 minutes` | cook, 18:00 | timer "Oven" 25, linked (180 dropped) | cook-timer-phrases#9 | K450 | miss (RC15) |
| D448 | `lamb 1 hour` | cook, 18:00 | timer "Lamb" 60, linked | cook-timer-phrases#10 | K450 | miss (RC15) |
| D449 | `timer 1 hour 30` | cook, 18:00 | timer "Timer" 90, linked | cook-timer-phrases#11 | K450 | wrong write (RC15) |
| D450 | `timer 2:30` | cook, 18:00 | timer "Timer" 2.5, linked | cook-timer-phrases#12 | K450 | wrong write (RC15) |
| D451 | `simmer 20-25` | cook, 18:00 | timer "Simmer" 20, linked (lower bound) | cook-timer-phrases#13 | K450 | miss (RC15) |
| D452 | `two minutes` | cook, 18:00 | timer "Simmer" 2, linked (after the normaliser: "2 minutes") | cook-timer-phrases#14 | K450 | miss (RC15) |
| D453 | `set a timer for 5 minutes` | cook, 18:00 | timer "Timer" 5, linked | cook-timer-phrases#15 | MB | pass |
| D454 | `another 2` | cook, Soften flared, 18:00 | extend Soften by 2 [12b] · now: nil | cook-timer-phrases#16 | K450 | pass |
| D455 | `add 30 seconds` | cook, 18:00 | extend Rice by 0.5 [12b] · now: nil | cook-timer-phrases#17 | K450 | pass |
| D456 | `add 2 minutes to the rice` | cook, 18:00 | extend Rice by 2 [12b] · now: nil | cook-timer-phrases#18 | K450 | pass |
| D457 | `stop the rice` | cook, 18:00 | StopKitchenTimer(Rice) | cook-timer-phrases#19 | K450 | miss (RC15) |
| D458 | `cancel the simmer timer` | cook, 18:00 | StopKitchenTimer(Simmer) | cook-timer-phrases#20 | K450 | miss (RC15) |
| D459 | `stop` | cook, Soften flared, 18:00 | StopKitchenTimer(Soften) (flared first) | cook-timer-phrases#21 | K450 | miss (RC15) |
| D460 | `stop timer` | cook, 18:00 | StopKitchenTimer(Rice) (soonest, never asks) | cook-timer-phrases#22 | K450 | miss (RC15) |
| D461 | `how long left` | cook, 18:00 | read-only timer answer, no write (runs ahead of the question guard) | cook-timer-phrases#23 | K450 | miss (RC15) |
| D462 | `is the rice done` | cook, 18:00 | read-only timer answer, no write | cook-timer-phrases#24 | K450, C4 | miss (RC15) |
| D463 | `pause` | cook, 18:00 | pause Rice [12b] · now: no write, line "Pause isn't here yet." (grammar claims it) | cook-timer-phrases#25 | K450 | miss (RC15) |
| D464 | `remind me in 20 minutes to take the chicken out` | cook, 18:00 | timer "Take the chicken out" 20, linked (a cook timer: N3 notification, no task alert) | cook-timer-phrases#26, reminders#R37 | T706 | wrong write (RC15) |
| D465 | `done` | cook, Soften flared, 18:00 | StopKitchenTimer(Soften); the cook keeps going ("done" ends a ringing timer first) (5:58 call) | cook-timer-phrases#27 | FX, D558 | wrong write (RC15) |
| D466 | `finished cooking` | cook, last step, 18:00 | cookStep finish (FinishCooking) | cook-timer-phrases#28 | K450 | miss (RC15) |
| D467 | `step 3` | cook, 18:00 | GoToCookStep(2), never a timer | cook-timer-phrases#30 | K450 | miss (RC15) |
| D468 | `serves 4` | cook, 18:00 | nil | cook-timer-phrases#31 | MB | pass |
| D469 | `pasta 500g` | cook, 18:00 | nil | cook-timer-phrases#32 | MB | pass |
| D470 | `pasta 500` | cook, 18:00 | nil (over the 180 cap) | cook-timer-phrases#33 | K450 | pass |
| D471 | `2 onions` | cook, 18:00 | nil (writes nothing mid-cook) | cook-timer-phrases#34 | K450 | pass |
| D472 | `3x10` | cook, 18:00 | nil | cook-timer-phrases#35 | MB | pass |
| D473 | `3x10` | live workout | nil (no weight said; never 3 kg) | cook-timer-phrases#36 | FX | wrong write (RC12) |
| D474 | `9 min` | none | nil | cook-timer-phrases#37 | MB | pass |
| D475 | `9 min` | live workout | nil | cook-timer-phrases#38 | MB | pass |
| D476 | `timer 10` | live workout | ignoredInWorkout | cook-timer-phrases#40 | MB | pass |

### E. People names that are also words (40 rows)

| id | phrase | context | expected parse | source rows | decision | status |
|---|---|---|---|---|---|---|
| E477 | `coffee with will thu` | none, people | task "Coffee with will" Thu 15, no time, alerts F (6:47 call), about Will [People, N1] · now: task "Coffee with will" Thu 15 19:00, no link | people-names#1 | PA, THU, T647 | pass |
| E478 | `call bill` | none, people | task "Call bill" Later, about Bill [People] · now: nil | people-names#2 | PA | pass |
| E479 | `call will thu` | none, people | task "Call will" Thu 15, no time, alerts F (6:47 call), about Will [People, N1] · now: task "Call will" Thu 15 19:00, no link | people-names#3 | PA, THU, T647 | pass |
| E480 | `lunch with rose and mark sat` | none, people | task "Lunch with rose and mark" Sat 17, no time, alerts F (6:30 call), about Rose and Mark [People, N1] · now: task "Lunch with rose and mark" Sat 17 09:00, no link | people-names#4 | PA, O410, N620, R630 | pass |
| E481 | `drinks with sky at 9` | none, people | task "Drinks with sky" Thu 15 21:00, no link | people-names#5 | C1 | pass |
| E482 | `dinner with basil fri` | none, people | task "Dinner with basil" Fri 16, no time, alerts F (6:30 call), never groceries [N1] · now: task "Dinner with basil" Fri 16 09:00, never groceries | people-names#6 | PD8, N620, R630 | pass |
| E483 | `saw rose yesterday` | none, people | LogTalk(Rose) Wed 14 [People] · now: note "Saw rose" Wed 14 12:00 | people-names#7 | C2 | pass |
| E484 | `called mark sat` | none, people | LogTalk(Mark) Sat 10 [People] · now: note "Called mark" Sat 10 12:00 | people-names#8 | C2 | pass |
| E485 | `texted will` | none, people | LogTalk(Will) now [People] · now: nil | people-names#9 | PA | pass |
| E486 | `see june at 7` | none, people | task "See june" Thu 15 19:00 (june is not a month here) | people-names#10 | C1 | pass |
| E487 | `get will from the station` | none, people | task "Get will from the station" Later, about Will [People] · now: nil | people-names#11 | PA | pass |
| E488 | `get rose some flowers` | none, people | task "Get rose some flowers" Later, about Rose [People] · now: same task, no link | people-names#12 | C3 | pass |
| E489 | `get honey` | none, people | groceries [honey] | people-names#13 | MB | pass |
| E490 | `rose's birthday 12 may` | none, people | SetBirthday(Rose, 12 May) + task "Rose's birthday" Wed 12 May 2027 [People] · now: nil | people-names#14 | PA | pass |
| E491 | `june's birthday june 3` | none, people | AddPerson(June) + SetBirthday(3 Jun) + task Thu 3 Jun 2027 [People] · now: nil | people-names#15 | PA | pass |
| E492 | `mark's birthday party sat` | none, people | task "Mark's birthday party" Sat 17, no time, alerts F (6:30 call), about Mark [People, N1] · now: task "Mark's birthday party" Sat 17 09:00, no link | people-names#16 | PA, N620, R630 | pass |
| E493 | `buy rose a card` | none, people | task "Buy rose a card" Later (link to Rose not called) | people-names#17 | B430 | pass |
| E494 | `buy rose` | none, people | groceries [rose], no link | people-names#18 | PD8, B430 | pass |
| E495 | `buy flowers for rose` | none, people | task "Buy flowers for rose" Later, about Rose [People] · now: groceries [flowers for rose] | people-names#19 | B430 | pass |
| E496 | `buy basil for rose` | none, people | groceries [basil for rose] | people-names#20 | B430 | pass |
| E497 | `buy sage green paint` | none, people | task "Buy sage green paint" Later | people-names#21 | B430 | wrong write (RC3) |
| E498 | `basil and tomatoes` | none, people | nil (all-food and-lists go to the model for now) | people-names#22 | T706 | pass |
| E499 | `basil, olive and rose` | none, people | nil | people-names#23 | FX | wrong write (RC8) |
| E500 | `rose` | shop run, people | nil, "Rose? That's a person, not a grocery." [People] · now: groceries [rose] | people-names#24 | O410 | pass |
| E501 | `will` | shop run, people | nil (a function word is never a line) | people-names#25 | T706 | wrong write (RC4) |
| E502 | `ginger` | shop run, people | groceries [ginger] | people-names#26 | MB | pass |
| E503 | `pay the bill` | none, people | nil | people-names#27 | MB | pass |
| E504 | `paid bill sat` | none, people | note "Paid bill" Sat 10 12:00, never a chore for a person | people-names#28 | C2 | pass |
| E505 | `paid bill 20` | none, people | spend 20, note "bill" [Money] · now: nil | people-names#29 | P434 | pass |
| E506 | `paid will back 15` | none, people | nil (repayment, not a spend) | people-names#30 | FX | pass |
| E507 | `bill 45 due fri` | none, people | task "Bill 45 due" Fri 16, no time, alerts F (6:30 call) [N1] · now: task "Bill 45 due" Fri 16 09:00 | people-names#31 | MB, N620, R630 | pass |
| E508 | `spent 12.40 lunch with will` | none, people | spend 12.40, note "lunch with will", category lunch [Money] · now: nil | people-names#32 | O410, MA | pass |
| E509 | `lunch with will was 14 quid` | none, people | nil (model) | people-names#33 | O410 | pass |
| E510 | `will do laundry sat` | none, people | task "Will do laundry" Sat 17, no time, alerts F (6:30 call), never about Will [N1] · now: task "Will do laundry" Sat 17 09:00, never about Will | people-names#34 | MB, N620, R630 | pass |
| E511 | `may need to move gym fri` | none, people | task "May need to move gym" Fri 16, no time, alerts F (6:30 call) [N1] · now: task "May need to move gym" Fri 16 09:00 | people-names#35 | MB, N620, R630 | pass |
| E512 | `june 12 dentist` | none, people | task "Dentist" Sat 12 Jun 2027, no time, alerts F (6:30 call) [People, month dates, N1] · now: nil | people-names#36 | PA, N620, R630 | pass |
| E513 | `mark set 3 as warmup` | live workout, people | nil | people-names#37 | MB | pass |
| E514 | `bench 80x8 with mark` | live workout, people | nil (no training partner link) | people-names#38 | T706 | pass |
| E515 | `read to rose` | none, people | nil | people-names#39 | O410 | pass |
| E516 | `read the will` | none, people | nil | people-names#40 | O410 | pass |

### F. People (34 rows)

| id | phrase | context | expected parse | source rows | decision | status |
|---|---|---|---|---|---|---|
| F517 | `called mum` | none, people | SetTaskDone("Call mum") [People] · now: nil | people#1 | PA | pass |
| F518 | `called mum` | none, people, task done | LogTalk(Mum) now [People] · now: nil | people#2 | PA | pass |
| F519 | `rang mum` | none, people | SetTaskDone("Call mum") (7:06 call) [People] · now: nil | people#3 | T706 | pass |
| F520 | `texted ravi` | none, people | LogTalk(Ravi) now [People] · now: nil | people#4 | PA | pass |
| F521 | `met sam yesterday` | none, people | LogTalk(Sam) Wed 14 [People] · now: note "Met sam" Wed 14 12:00 | people#5 | C2 | pass |
| F522 | `met priya` | none, people | ambiguous: new person Priya or note [People] · now: nil | people#8 | PA | pass |
| F523 | `met the deadline` | none, people | nil | people#9 | PA | pass |
| F524 | `saw dune` | none, people | nil | people#10 | PA | pass |
| F525 | `talked to sam and mum` | none, people | LogTalk(Sam, Mum), one note [People] · now: nil | people#11 | PA | pass |
| F526 | `facetimed amma` | none, people | LogTalk(Mum) [People] · now: nil | people#12 | PA | pass |
| F527 | `call ravi` | none, people | task "Call ravi" Later, about Ravi [People] · now: nil | people#14 | PA | pass |
| F528 | `call priya` | none, people | nil | people#15 | PA | pass |
| F529 | `call priya thu` | none, people | task "Call priya" Thu 15, no time, alerts F (6:47 call), no link [N1] · now: task "Call priya" Thu 15 19:00, no link | people#16 | THU, T647 | pass |
| F530 | `coffee with ravi thu` | none, people | task "Coffee with ravi" Thu 15, no time, alerts F (6:47 call), about Ravi [People, N1] · now: task "Coffee with ravi" Thu 15 19:00, no link | people#17 | PA, THU, T647 | pass |
| F531 | `lunch with ravi` | none, people | ambiguous: task "Lunch with ravi" Later, about Ravi, or LogTalk(Ravi) now, waits for a tap (7:06 call) [People] · now: nil | people#19 | T706 | pass |
| F532 | `drinks with ben 7pm` | none, people | task "Drinks with ben" Thu 15 19:00, about Ben [People] · now: same task, no link | people#20 | PA | pass |
| F533 | `dinner with rosemary fri` | none, people | task "Dinner with rosemary" Fri 16, no time, alerts F (6:30 call), about Rosemary [People, N1] · now: task "Dinner with rosemary" Fri 16 09:00, no link | people#21 | PD8, N620, R630 | pass |
| F534 | `ravi's birthday 12 may` | none, people | SetBirthday(Ravi, 12 May) + task Wed 12 May 2027 [People] · now: nil | people#22 | PA | pass |
| F535 | `Ravi's birthday is on the 12th of May` | none, people | as above [People] · now: nil | people#23 | PA | pass |
| F536 | `priya's birthday 3 june` | none, people | AddPerson(Priya) + SetBirthday(3 Jun) + task Thu 3 Jun 2027 [People] · now: nil | people#24 | PA | pass |
| F537 | `sam birthday 12/3` | none, people | SetBirthday(Sam, 12 Mar) + task Fri 12 Mar 2027 [People] · now: nil | people#25 | PA | pass |
| F538 | `mum's birthday 15 oct` | none, people | SetBirthday(Mum, 15 Oct) + task today, untimed [People] · now: nil | people#26 | PA | pass |
| F539 | `mum's birthday sat` | none, people | task "Mum's birthday" Sat 17, no time, alerts F (6:30 call), about Mum [People, N1] · now: task "Mum's birthday" Sat 17 09:00, no link | people#27 | PA, N620, R630 | pass |
| F540 | `buy present for mums birthday on the twentieth` | none, people | task "Buy present for mums birthday" Tue 20, no time, alerts F (6:30 call) [N1] · now: task "Buy present for mums birthday" Tue 20 09:00 | people#28 | B430, N620, R630 | wrong write (ORD) |
| F541 | `when's ravi's birthday` | none, people | nil (question) | people#29 | MB | pass |
| F542 | `gift idea for priya: lego` | none, people | nil (gift ideas are Later) | people#30 | PA | pass |
| F543 | `gift sam: chalk bag` | none, people | nil | people#31 | PA | pass |
| F544 | `buy lego for priya` | none, people | task "Buy lego for priya" Later | people#32 | B430 | wrong write (RC3) |
| F545 | `ravi` | shop run, people | nil, "Ravi? That's a person, not a grocery." [People] · now: groceries [ravi] | people#35 | O410 | pass |
| F546 | `sam` | live workout, people | nil | people#36 | MB | pass |
| F547 | `note called mum, she's fine` | none, people | note "called mum, she's fine" | people#37 | MB | pass |
| F548 | `ravi: call back about the flat` | none, people | nil | people#38 | PA | pass |
| F549 | `spent 12.40 lunch with sam` | none, people | spend 12.40, note "lunch with sam", no talk [Money] · now: nil | people#39 | O410 | pass |
| F550 | `read sam's draft` | none, people | nil | people#40 | O410 | pass |

### G. Reading (40 rows)

| id | phrase | context | expected parse | source rows | decision | status |
|---|---|---|---|---|---|---|
| G551 | `p 142` | none, book | SetBookPage(Dune, 142) [Reading] · now: nil | reading#1 | RD | pass |
| G552 | `p142` | none, book | SetBookPage(Dune, 142) [Reading] · now: nil | reading#2 | RD | pass |
| G553 | `page 142 of dune` | none, book | SetBookPage(Dune, 142) [Reading] · now: nil | reading#3 | RD | pass |
| G554 | `p 142 of 612` | none, book | SetBookPage(Dune, 142) [Reading] · now: nil | reading#4 | RD | pass |
| G555 | `p 50 of 1984` | none, book | ambiguous: StartReading(1984) + page 50, or Dune p 50 [Reading] · now: nil | reading#5 | RD | pass |
| G556 | `p 142` | none, two books | SetBookPage(Project Hail Mary, 142) [Reading] · now: nil | reading#6 | RD | pass |
| G557 | `p 142` | none | claimed, no write, "No book open." [Reading] · now: nil | reading#7 | RD | pass |
| G558 | `p 700` | none, book | SetBookPage(Dune, 700) [Reading] · now: nil | reading#8 | RD | pass |
| G559 | `p 142` | live workout, book | SetBookPage(Dune, 142), workout untouched [Reading] · now: nil | reading#9 | RD | pass |
| G560 | `142` | live workout, book | nil (no write) | reading#10 | RD | pass |
| G561 | `142` | none, book in front | SetBookPage(Dune, 142) (7:06 call) [Reading] · now: nil | reading#11 | T706 | pass |
| G562 | `p 142` | cook, book, 18:00 | SetBookPage(Dune, 142) [Reading] · now: nil | reading#12 | RD | pass |
| G563 | `read dune` | none, book | QueueBook(Dune) returns the existing book [Reading] · now: nil | reading#13 | RD | pass |
| G564 | `read chapter four` | none, book | ambiguous: task or book [Reading] · now: nil | reading#14 | RD | pass |
| G565 | `read dune thu` | none, book | task "Read dune" Thu 15, no time, alerts F (6:47 call) [N1] · now: task "Read dune" Thu 15 19:00 | reading#15 | THU, T647 | pass |
| G566 | `read the sun also rises` | none, book | QueueBook returns The Sun Also Rises [Reading] · now: nil; never a task | reading#16 | RD | wrong write (RC10) |
| G567 | `reading dune` | none, book | StartReading(Dune) [Reading] · now: nil | reading#17 | RD | pass |
| G568 | `reading piranesi 272 pages` | none, book | QueueBook(Piranesi, 272) + StartReading [Reading] · now: nil | reading#18 | RD | pass |
| G569 | `started project hail mary` | none, book | StartReading(Project Hail Mary) [Reading] · now: nil | reading#19 | RD | pass |
| G570 | `start push day` | none, book | nil | reading#20 | RD | pass |
| G571 | `reading 1984` | none, book | StartReading(1984) [Reading] · now: nil | reading#21 | RD | pass |
| G572 | `reading it` | none, book | StartReading(It) [Reading] · now: nil | reading#22 | RD | pass |
| G573 | `reading 30 min` | none, book | nil | reading#23 | RD | pass |
| G574 | `reading timer 30` | none, book | timer "Reading" 30 | reading#24 | RD | pass |
| G575 | `reading dune messiah` | none, book | StartReading(Dune Messiah) [Reading] · now: nil | reading#25 | RD | pass |
| G576 | `reading the expanse 1` | none, book | QueueBook("The Expanse 1") + StartReading [Reading] · now: nil | reading#26 | RD | pass |
| G577 | `reading catch-22` | none, book | StartReading(Catch-22) at p 88 [Reading] · now: nil | reading#27 | RD | pass |
| G578 | `reading educated` | none, book | StartReading(Educated) at p 352 [Reading] · now: nil | reading#28 | RD | pass |
| G579 | `dune 45%` | none, book | SetBookPage(Dune, 275) (7:06 call) [Reading] · now: nil | reading#29 | T706 | pass |
| G580 | `atomic habits 30% on kindle` | none, book | no write, asks "Atomic Habits has no page count. How many pages?" (7:06 call) [Reading] · now: nil | reading#30 | T706 | pass |
| G581 | `dune loc 2304` | none, book | nil | reading#31 | T706 | pass |
| G582 | `project hail mary 3h 20m of 16h 10m` | none, two books | nil | reading#32 | FX | pass |
| G583 | `finished dune` | none, book | FinishBook(Dune) [Reading] · now: nil | reading#33 | RD | pass |
| G584 | `finished Dune: slow start, great end` | none, book | FinishBook(Dune, review) [Reading] · now: nil | reading#34 | RD | pass |
| G585 | `finished` | none, book | FinishBook(Dune) [Reading] · now: nil | reading#35 | RD | pass |
| G586 | `finished` | live workout, book | nil (the workout's, model now) | reading#36 | RD | pass |
| G587 | `finished the report` | none, book | nil (model completes the task) | reading#37 | RD | pass |
| G588 | `finished it` | none, book | ambiguous: FinishBook(Dune) or It [Reading] · now: nil | reading#38 | RD | pass |
| G589 | `abandoned dune` | none, book | SetBookAside(Dune) (7:06 call) [Reading] · now: nil | reading#39 | T706 | pass |
| G590 | `Have I finished Dune` | none, book | nil (question) | reading#40 | MB | pass |

### H. Money (45 rows)

| id | phrase | context | expected parse | source rows | decision | status |
|---|---|---|---|---|---|---|
| H591 | `spent 12.40 lunch` | none | spend 12.40, category lunch [Money] · now: nil | money#1 | MA | pass |
| H592 | `spent 4.50 on coffee` | none | spend 4.50, category coffee [Money] · now: nil | money#2 | MA | pass |
| H593 | `12.40 lunch` | none | spend 12.40, category lunch [Money] · now: nil | money#3 | MA | pass |
| H594 | `12,40 lunch` | none | spend 12.40 (typed "12,40"), category lunch [Money] · now: nil | money#4 | MA | pass |
| H595 | `12.5 lunch` | none | nil (one decimal is not money) | money#5 | MA | pass |
| H596 | `spent 8.50 bar` | none | spend 8.50, category bar [Money] · now: nil | money#6 | MA | pass |
| H597 | `6.50 cab` | none | spend 6.50, category cab [Money] · now: nil | money#7 | MA | pass |
| H598 | `£12.50 lunch` | none | spend 12.50 GBP, category lunch [Money] · now: nil | money#8 | MA | pass |
| H599 | `12.50 gbp lunch` | none | spend 12.50 GBP, category lunch [Money] · now: nil | money#9 | MA | pass |
| H600 | `spent 20 eur taxi` | none | spend 20 EUR, category taxi [Money] · now: nil | money#10 | MA | pass |
| H601 | `€8 parking yesterday` | none | spend 8 EUR, category parking, Wed 14 [Money] · now: nil | money#11 | MA | pass |
| H602 | `₹450 auto` | none | spend 450 INR, category auto [Money] · now: nil | money#12 | MA | pass |
| H603 | `450 rs auto` | none | spend 450 INR, category auto [Money] · now: nil | money#13 | MA | pass |
| H604 | `spent 20 chf taxi` | none | nil (codes beyond the four go to the model) | money#14 | M410 | pass |
| H605 | `spent 1,00,000 on the bike` | none | spend 100000, category bike [Money] · now: nil | money#15 | MA | pass |
| H606 | `lunch was a tenner` | none | nil (model) | money#16 | MA | pass |
| H607 | `lunch with sam was 23 quid` | none | nil (model; people must not bind) | money#17 | O410 | pass |
| H608 | `12 50 at tesco` | none | nil (model asks 12.50 or 1250) | money#18 | MA | pass |
| H609 | `spent 30 dinner sat` | none | spend 30, category dinner, Sat 10 [Money] · now: note "Spent 30 dinner" Sat 10 12:00; never a task | money#20 | MA, C2 | wrong write (RC2) |
| H610 | `spent 12.40 lunch thu` | none | spend 12.40, category lunch, Thu 15 [Money] · now: note "Spent 12.40 lunch" Thu 15 12:00; never a task | money#21 | MA, C2 | wrong write (RC2) |
| H611 | `12.40 lunch fri` | none | nil (M8) (7:06 call) [Money] · now: task "12.40 lunch" Fri 16 09:00 | money#22 | MA, N620, R630, T706 | pass |
| H612 | `pay rent 650 fri` | none | task "Pay rent 650" Fri 16, no time, alerts F (6:30 call) [N1] · now: task "Pay rent 650" Fri 16 09:00 | money#23 | MA, N620, R630 | pass |
| H613 | `pay rent fri` | none | task "Pay rent" Fri 16, no time, alerts F (6:30 call) [N1] · now: task "Pay rent" Fri 16 09:00 | money#24, upkeep-starters#22 | MA, N620, R630 | pass |
| H614 | `paid rent 650` | none | spend 650, note "rent" + DoChore(Pay rent) in one ghost row [Money] · now: nil | money#25, upkeep#34, upkeep-starters#22 | P434 | pass |
| H615 | `spent the day at the beach sat` | none | task "Spent the day at the beach" Sat 17, no time, alerts F (6:30 call) [N1] · now: task "Spent the day at the beach" Sat 17 09:00 | money#26 | MA, N620, R630 | pass |
| H616 | `80 x5` | live workout | set 80x5 | money#27 | MB | pass |
| H617 | `80 for 5` | none | nil | money#28 | MB | pass |
| H618 | `bench 82.50 x 8` | none | lift Bench Press 82.5x8 | money#29 | MB | pass |
| H619 | `82.50 x 8` | none | nil | money#30 | MB | pass |
| H620 | `38.20` | none, total awaited | LogShopTotal 38.20 [Money] · now: nil | money#32 | MA | pass |
| H621 | `£38.20` | none, total awaited | LogShopTotal 38.20 GBP [Money] · now: nil | money#33 | MA | pass |
| H622 | `38` | none, total awaited | LogShopTotal 38 (no workout running) [Money] · now: nil | money#34 | M410 | pass |
| H623 | `skip` | none, total awaited | SkipShopTotal [Money] · now: nil | money#35 | MA | pass |
| H624 | `38.20` | live workout | nil | money#36 | MA | pass |
| H625 | `38` | live workout, total awaited | set 80x38, never a total | money#37 | M410 | pass |
| H626 | `milk, eggs, 2 lemons` | shop run | groceries [milk, eggs, 2 lemons] | money#41 | MB | pass |
| H627 | `milk 1.20` | none | nil | money#42 | MA | pass |
| H628 | `1.20 milk` | shop run | ambiguous: grocery line "1.20 milk" or spend 1.20, waits for a tap [Money] · now: groceries [1.20 milk] | money#43 | O410 | pass |
| H629 | `buy milk 1.20` | none | groceries [milk 1.20] | money#44 | B430 | pass |
| H630 | `8.99 dune` | none, book | spend 8.99, category dune [Money] · now: nil | money#45 | MA | pass |
| H631 | `p 12.50` | none, book | nil (no write; reading asks "Dune, p 12?") | money#46 | RD | pass |
| H632 | `refund 12.40 amazon` | none | nil | money#47 | MA | pass |
| H633 | `12.40 refund from amazon` | none | nil | money#48 | MA | pass |
| H634 | `spent 60 dinner split with sam` | none | spend 30 (his share), category dinner [Money] · now: nil | money#49 | M410 | pass |
| H635 | `spent 12.40 lunch and 3 coffee` | none | nil | money#50 | MA | pass |

### I. Upkeep and upkeep starters (101 rows)

| id | phrase | context | expected parse | source rows | decision | status |
|---|---|---|---|---|---|---|
| I636 | `changed the water filter` | none, chores | DoChore(Change the water filter) if it exists, else AddChore + DoChore [Upkeep] · now: nil | upkeep#1, upkeep-starters#8 | UA | pass |
| I637 | `descaled kettle` | none, chores | DoChore(Descale the kettle) if it exists, else AddChore + DoChore [Upkeep] · now: nil | upkeep#2, upkeep-starters#7 | UA | pass |
| I638 | `descaled the kettle` | none, chores | DoChore(Descale the kettle), no second chore [Upkeep] · now: nil | upkeep#3, upkeep-starters#7 | UA | pass |
| I639 | `watered plants` | none, chores | DoChore(Water the plants) Thu 15 [Upkeep] · now: nil | upkeep#4, upkeep-starters#20 | UA | pass |
| I640 | `cleaned the oven` | none, chores | SetTaskDone("Clean the oven") + DoChore(Clean the oven) if that chore exists [Upkeep] · now: nil | upkeep#5, upkeep-starters#5 | UA | pass |
| I641 | `cleaned bathroom` | none, chores | DoChore(Clean the bathroom) [Upkeep] · now: nil | upkeep#6, upkeep-starters#13 | UA | pass |
| I642 | `took out the bins` | none, chores | DoChore(Take out the bins) [Upkeep] · now: nil | upkeep#7, upkeep-starters#2 | UA | pass |
| I643 | `took the bins out` | none, chores | DoChore(Take out the bins) [Upkeep] · now: nil | upkeep#8, upkeep-starters#2 | U450 | pass |
| I644 | `bins out` | none, chores | DoChore(Take out the bins) [Upkeep] · now: nil | upkeep#9, upkeep-starters#2 | U450 | pass |
| I645 | `hoovered` | none, chores | DoChore on the hoovered chore, else AddChore("Hoover") + DoChore [Upkeep] · now: nil | upkeep#10, upkeep-starters#10 | U450 | pass |
| I646 | `hoovered and mopped the kitchen` | none, chores | nil (shared-object split not called) | upkeep#11 | FX | pass |
| I647 | `did laundry` | none, chores | DoChore(Laundry) [Upkeep, did narrowed] · now: nil | upkeep#12, upkeep-starters#16 | UA, O410 | pass |
| I648 | `did the bins` | none, chores | DoChore(Take out the bins), never Recycling [Upkeep] · now: nil | upkeep#13 | UA | pass |
| I649 | `did 2 loads of laundry` | none, chores | DoChore(Laundry), note "2 loads" [Upkeep] · now: nil | upkeep#14, upkeep-starters#16 | UA | pass |
| I650 | `defrosted the freezer` | none, chores | DoChore(Defrost the freezer) if it exists, else AddChore + DoChore [Upkeep] · now: nil | upkeep#15, upkeep-starters#6 | UA | pass |
| I651 | `defrosted the chicken` | none, chores | nil (ingredient, no chore) | upkeep#16, upkeep-starters#6 | O410 | pass |
| I652 | `watered plants yesterday` | none, chores | DoChore(Water plants) Wed 14 [Upkeep] · now: note "Watered plants" Wed 14 12:00 | upkeep#17 | C2 | pass |
| I653 | `bins out thu` | none, chores | task "Bins out" Thu 15, no time, alerts F (6:47 call) [N1] · now: task "Bins out" Thu 15 19:00 | upkeep#21, upkeep-starters#2 | UA, THU, T647 | pass |
| I654 | `washed the car tomorrow` | none, chores | task "Washed the car" Fri 16, no time, alerts F (6:30 call) [N1] · now: task "Washed the car" Fri 16 09:00 | upkeep#22 | UA, N620, R630 | pass |
| I655 | `car service due march` | none, chores | task "Car service" Mon 1 Mar 2027, no time, alerts F (7:06 call) [month dates, N1] · now: nil | upkeep#23 | T706 | pass |
| I656 | `plants fine` | none, chores | ChoreFine(Water plants); with two plant chores, an ambiguous ghost [Upkeep] · now: nil | upkeep#24, upkeep-starters#20 | U450 | pass |
| I657 | `checked the oil, fine` | none, chores | ChoreFine(Top up the oil) [Upkeep] · now: nil; never groceries | upkeep#25 | O410 | wrong write (RC8) |
| I658 | `plants every 10d` | none, chores | SetChoreInterval(Water plants, 10); ambiguous with two plant chores [Upkeep] · now: nil | upkeep#26, upkeep-starters#20 | U450 | pass |
| I659 | `water filter every 6 months` | none, chores | SetChoreInterval(Change the water filter, 180) (7:06 call) [Upkeep, month dates] · now: nil | upkeep#27 | T706 | pass |
| I660 | `bins every thursday` | none, chores | task "Bins every Thursday" Thu 15, no time, alerts F (6:47 call) [N1] · now: task "Bins every Thursday" Thu 15 19:00 | upkeep#28 | UA, T647, T706 | wrong write (RC7) |
| I661 | `snooze plants` | none, chores | SnoozeChore(Water plants) [Upkeep] · now: nil | upkeep#29 | UA | pass |
| I662 | `pause chores till sun` | none, chores | PauseChores until Sun 18 00:00 [Upkeep] · now: nil | upkeep#30 | UA | wrong write (UPK) |
| I663 | `home` | none, chores paused | ResumeChores [Upkeep] · now: nil | upkeep#31 | UA | pass |
| I664 | `note descaled the kettle, took ages` | none, chores | note "descaled the kettle, took ages" | upkeep#32 | MB | pass |
| I665 | `did i water the plants` | none, chores | nil (question) | upkeep#33 | MB | pass |
| I666 | `spent 40 on a new water filter` | none, chores | spend 40, category new [Money] · now: nil | upkeep#35 | O410 | pass |
| I667 | `did bench 80x8` | none, chores | lift Bench Press 80x8 [did narrowed, with Upkeep] · now: nil | upkeep#36 | O410 | pass |
| I668 | `read the gas meter` | none, chores | nil (never a book, never a chore) | upkeep#38, upkeep-starters#24 | O410 | pass |
| I669 | `finished the ironing` | none, chores | nil (model completes "Do the ironing") | upkeep#39, upkeep-starters#19 | UA | pass |
| I670 | `paid council tax 142.50` | none, chores | spend 142.50, note "council tax" + DoChore(Pay council tax) if it exists, never AddChore [Money] · now: nil | upkeep#40, upkeep-starters#23 | P434 | pass |
| I671 | `cleaned the kitchen` | none, chores | DoChore(Clean the kitchen) [Upkeep] · now: nil | upkeep-starters#1 | UA | pass |
| I672 | `cleaned kitchen` | none, chores | DoChore(Clean the kitchen) [Upkeep] · now: nil | upkeep-starters#1 | UA | pass |
| I673 | `take bins out` | none, chores | nil | upkeep-starters#2 | UA | pass |
| I674 | `take bins out thu` | none, chores | task "Take bins out" Thu 15, no time, alerts F (6:47 call) [N1] · now: task "Take bins out" Thu 15 19:00 | upkeep-starters#2 | UA, THU, T647 | pass |
| I675 | `took out the recycling` | none, chores | DoChore(Take out the recycling) [Upkeep] · now: nil | upkeep-starters#3 | UA | pass |
| I676 | `recycling out` | none, chores | DoChore(Take out the recycling) [Upkeep] · now: nil | upkeep-starters#3 | U450 | pass |
| I677 | `cleaned the fridge` | none, chores | DoChore(Clean the fridge) [Upkeep] · now: nil | upkeep-starters#4 | UA | pass |
| I678 | `did the fridge` | none, chores | DoChore(Clean the fridge) [Upkeep] · now: nil | upkeep-starters#4 | UA | pass |
| I679 | `clean the fridge` | none, chores | nil | upkeep-starters#4 | UA | pass |
| I680 | `clean the fridge sat` | none, chores | task "Clean the fridge" Sat 17, no time, alerts F (6:30 call) [N1] · now: task "Clean the fridge" Sat 17 09:00 | upkeep-starters#4 | UA, N620, R630 | pass |
| I681 | `clean the fridge, bins out` | none, chores | nil | upkeep-starters#4 | UA | pass |
| I682 | `cleared out the fridge` | none, chores | nil | upkeep-starters#4 | UA | pass |
| I683 | `did the oven` | none, chores | DoChore(Clean the oven) + SetTaskDone("Clean the oven") [Upkeep] · now: nil | upkeep-starters#5 | UA | pass |
| I684 | `did the freezer` | none, chores | DoChore(Defrost the freezer) [Upkeep] · now: nil | upkeep-starters#6 | UA | pass |
| I685 | `descaled` | none, chores | ambiguous: Descale the kettle or Descale the shower head [Upkeep] · now: nil | upkeep-starters#7 | U450 | pass |
| I686 | `changed the filter` | none, chores | DoChore(Change the water filter) [Upkeep] · now: nil | upkeep-starters#8 | UA | pass |
| I687 | `cleaned the washing machine` | none, chores | DoChore(Clean the washing machine) [Upkeep] · now: nil | upkeep-starters#9 | UA | pass |
| I688 | `did the washing machine` | none, chores | DoChore(Clean the washing machine) [Upkeep] · now: nil | upkeep-starters#9 | UA | pass |
| I689 | `did the washing` | none, chores | DoChore(Laundry) (S4 family) [Upkeep] · now: nil | upkeep-starters#9 | U450 | pass |
| I690 | `hoovered the flat` | none, chores | DoChore(Hoover the flat) [Upkeep] · now: nil | upkeep-starters#10 | UA | pass |
| I691 | `vacuumed` | none, chores | DoChore(Hoover the flat) (S4 family) [Upkeep] · now: nil | upkeep-starters#10 | U450 | pass |
| I692 | `mopped the floors` | none, chores | DoChore(Mop the floors) [Upkeep] · now: nil | upkeep-starters#11 | UA | pass |
| I693 | `mopped` | none, chores | DoChore(Mop the floors) [Upkeep] · now: nil | upkeep-starters#11 | UA | pass |
| I694 | `mopped the kitchen` | none, chores | AddChore("Mop the kitchen") + DoChore, "How often?" [Upkeep] · now: nil | upkeep-starters#11 | U450 | pass |
| I695 | `dusted` | none, chores | DoChore(Dust the flat) [Upkeep] · now: nil | upkeep-starters#12 | UA | pass |
| I696 | `dusted the flat` | none, chores | DoChore(Dust the flat) [Upkeep] · now: nil | upkeep-starters#12 | UA | pass |
| I697 | `cleaned the bathroom` | none, chores | DoChore(Clean the bathroom) [Upkeep] · now: nil | upkeep-starters#13 | UA | pass |
| I698 | `descaled the shower head` | none, chores | DoChore(Descale the shower head) [Upkeep] · now: nil | upkeep-starters#14 | UA | pass |
| I699 | `descaled the shower` | none, chores | DoChore(Descale the shower head) [Upkeep] · now: nil | upkeep-starters#14 | UA | pass |
| I700 | `emptied the hoover` | none, chores | DoChore(Empty the hoover), never Hoover the flat (S1) [Upkeep] · now: nil | upkeep-starters#15 | U450 | pass |
| I701 | `emptied the hoover bin` | none, chores | AddChore("Empty the hoover bin") + DoChore, "How often?" [Upkeep] · now: nil | upkeep-starters#15 | U450 | pass |
| I702 | `did the laundry` | none, chores | DoChore(Laundry) [Upkeep] · now: nil | upkeep-starters#16 | UA | pass |
| I703 | `did a wash` | none, chores | DoChore(Laundry) (S4 family) [Upkeep] · now: nil | upkeep-starters#16 | U450 | pass |
| I704 | `put a wash on` | none, chores | nil | upkeep-starters#16 | UA | pass |
| I705 | `washed clothes` | none, chores | DoChore(Laundry) (S4 family) [Upkeep] · now: nil | upkeep-starters#16 | U450 | pass |
| I706 | `changed the sheets` | none, chores | DoChore(Change the bed sheets) [Upkeep] · now: nil | upkeep-starters#17 | UA | pass |
| I707 | `changed the bed` | none, chores | DoChore(Change the bed sheets) [Upkeep] · now: nil | upkeep-starters#17 | UA | pass |
| I708 | `change bed sheets` | none, chores | nil | upkeep-starters#17 | UA | pass |
| I709 | `change bed sheets sun` | none, chores | task "Change bed sheets" Sun 18, no time, alerts F (6:30 call) [N1] · now: task "Change bed sheets" Sun 18 09:00 | upkeep-starters#17 | UA, N620, R630 | pass |
| I710 | `buy bed sheets` | none, chores | task "Buy bed sheets" Later | upkeep-starters#17 | B430 | wrong write (RC3) |
| I711 | `get new sheets` | none, chores | task "Get new sheets" Later | upkeep-starters#17 | U450 | wrong write (RC3) |
| I712 | `washed the sheets` | none, chores | DoChore(Change the bed sheets) (S4 family) [Upkeep] · now: nil | upkeep-starters#17 | U450 | pass |
| I713 | `changed the towels` | none, chores | DoChore(Change the towels) [Upkeep] · now: nil | upkeep-starters#18 | UA | pass |
| I714 | `changed towels` | none, chores | DoChore(Change the towels) [Upkeep] · now: nil | upkeep-starters#18 | UA | pass |
| I715 | `changed my mind` | none, chores | nil (S5) | upkeep-starters#18 | U450 | pass |
| I716 | `changed the meeting to fri` | none, chores | nil (S5); never a note dated last Friday | upkeep-starters#18 | U450 | wrong write (RC2) |
| I717 | `ironed shirts` | none, chores | DoChore(Iron shirts) [Upkeep] · now: nil | upkeep-starters#19 | UA | pass |
| I718 | `did the ironing` | none, chores | SetTaskDone("Do the ironing") only [Upkeep] · now: nil | upkeep-starters#19 | UA | pass |
| I719 | `watered the plants` | none, chores | DoChore(Water the plants) [Upkeep] · now: nil | upkeep-starters#20 | UA | pass |
| I720 | `water plants` | none, chores | nil | upkeep-starters#20 | UA | pass |
| I721 | `fed the plants` | none, chores | DoChore(Feed the plants), never watering (S1) [Upkeep] · now: nil | upkeep-starters#21 | U450 | pass |
| I722 | `fed plants` | none, chores | DoChore(Feed the plants) [Upkeep] · now: nil | upkeep-starters#21 | U450 | pass |
| I723 | `fed the plants sun` | none, chores | DoChore(Feed the plants) Sun 11 [Upkeep] · now: note "Fed the plants" Sun 11 12:00 | upkeep-starters#21 | C2 | pass |
| I724 | `feed the plants sun` | none, chores | task "Feed the plants" Sun 18, no time, alerts F (6:30 call) [N1] · now: task "Feed the plants" Sun 18 09:00 | upkeep-starters#21 | UA, N620, R630 | pass |
| I725 | `paid rent` | none, chores | DoChore(Pay rent) [Upkeep] · now: nil | upkeep-starters#22 | P434 | pass |
| I726 | `rent paid` | none, chores | DoChore(Pay rent) (noun-first) [Upkeep] · now: nil | upkeep-starters#22 | U450 | pass |
| I727 | `bins done` | none, chores | DoChore(Take out the bins) (noun-first) [Upkeep] · now: nil | upkeep-starters#2 | U450 | pass |
| I728 | `paid council tax` | none, chores | DoChore(Pay council tax) [Upkeep] · now: nil | upkeep-starters#23 | UA | pass |
| I729 | `pay council tax` | none, chores | nil | upkeep-starters#23 | UA | pass |
| I730 | `pay council tax fri` | none, chores | task "Pay council tax" Fri 16, no time, alerts F (6:30 call) [N1] · now: task "Pay council tax" Fri 16 09:00 | upkeep-starters#23 | UA, N620, R630 | pass |
| I731 | `sent meter readings` | none, chores | DoChore(Send meter readings) (S2, own verb) [Upkeep] · now: nil | upkeep-starters#24 | U450 | pass |
| I732 | `read the meters sun` | none, chores | task "Read the meters" Sun 18, no time, alerts F (6:30 call) (S6) [N1] · now: task "Read the meters" Sun 18 09:00 (S6) | upkeep-starters#24 | U450, N620, R630 | pass |
| I733 | `tested the smoke alarm` | none, chores | DoChore(Test the smoke alarm) (S2) [Upkeep] · now: nil | upkeep-starters#25 | U450 | pass |
| I734 | `smoke alarm fine` | none, chores | DoChore(Test the smoke alarm) ("fine" counts as done for checks) [Upkeep] · now: nil | upkeep-starters#25 | U450 | pass |
| I735 | `tested the smoke alarm sat` | none, chores | DoChore(Test the smoke alarm) Sat 10 [Upkeep] · now: note "Tested the smoke alarm" Sat 10 12:00 | upkeep-starters#25 | C2, U450 | pass |
| I736 | `test the smoke alarm at 7` | none, chores | task "Test the smoke alarm" Thu 15 19:00 ("alarm" is not an AM cue) | upkeep-starters#25 | U450 | wrong write (RC1) |

### J. Reminders (38 rows)

From `reminders.md` (R01 to R40, traced at `2473436`; grammar unchanged since `82c51d9`). Two rows merged into existing ones: R14 `remind me tomorrow to call mum` into A224 (same phrase and parse; A224 runs at Thu 18:10, R14 at Fri 17:40, and both land on tomorrow 09:00), and R37 (the same phrase in a cook at 18:00) into D464. These rows run on **Fri 16 Oct**, at the clock in the context cell. The reply lines (with and without permission, "On Now then.") stay in `reminders.md` for Builder B; this suite checks the parse and `alerts` only.

| id | phrase | context | expected parse | source rows | decision | status |
|---|---|---|---|---|---|---|
| J737 | `remind me in 20 minutes` | none, Fri 17:40 | task "Reminder" Fri 16 18:00, alerts T | reminders#R01 | N620, T647, T706 | wrong write (RELT) |
| J738 | `remind me in 20 minutes to take the chicken out` | none, Fri 17:40 | task "Take the chicken out" Fri 16 18:00, alerts T (in a cook: D464) | reminders#R02 | N620, T706 | wrong write (RELT) |
| J739 | `remind me in an hour to call mum` | none, Fri 17:40 | task "Call mum" Fri 16 18:40, alerts T | reminders#R03 | N620, T706 | wrong write (RELT) |
| J740 | `remind me to stretch in half an hour` | none, Fri 17:40 | task "Stretch" Fri 16 18:10, alerts T | reminders#R04 | N620, T706 | wrong write (RELT) |
| J741 | `remind me in 2h to move the car` | none, Fri 17:40 | task "Move the car" Fri 16 19:40, alerts T | reminders#R05 | N620, T706 | wrong write (RELT) |
| J742 | `ping me in 5` | none, Fri 17:40 | task "Reminder" Fri 16 17:45, alerts T (bare N after "in" is minutes, cap 180) | reminders#R06 | N620, K450, T647, T706 | miss (LEAD) |
| J743 | `remind me in 30 minutes to lock the door` | none, Fri 23:40 | task "Lock the door" Sat 17 00:10, alerts T (rings in quiet hours) | reminders#R07 | N620, T706 | wrong write (RELT) |
| J744 | `remind me at 6 to call mum` | none, Fri 17:40 | task "Call mum" Fri 16 18:00, alerts T | reminders#R08 | C1, N620 | pass |
| J745 | `remind me to call mum at 6` | none, Fri 17:40 | task "Call mum" Fri 16 18:00, alerts T | reminders#R09 | C1, N620 | pass |
| J746 | `remind me at 7 to do push day` | none, Fri 17:40 | task "Do push day" Fri 16 19:00, alerts T | reminders#R10 | C1, N620 | pass |
| J747 | `remind me at 5 to pay rent` | none, Fri 17:40 | task "Pay rent" Sat 17 17:00, alerts T (passed, lands tomorrow) | reminders#R11 | C1, C5, N620 | pass |
| J748 | `set a reminder for 6 to call mum` | none, Fri 17:40 | task "Call mum" Fri 16 18:00, alerts T | reminders#R12 | C1, N620 | miss (LEAD) |
| J749 | `Remind me at 6 PM to call Mum.` | none, Fri 17:40 | task "Call Mum" Fri 16 18:00, alerts T | reminders#R13 | N620 | wrong write (RC11) |
| J750 | `remind me tonight to take my pills` | none, Fri 17:40 | task "Take my pills" Fri 16 20:00, alerts T | reminders#R15 | T441, N620 | pass |
| J751 | `remind me tonight to take my pills` | none, Fri 21:15 | task "Take my pills" Fri 16 22:00, alerts T (after 20:00: the next whole hour, until 23:30) | reminders#R16 | T441, D558, N620, T650 | wrong write (DAY4) |
| J752 | `remind me sat to book the MOT` | none, Fri 17:40 | task "Book the MOT" Sat 17 09:00, alerts T (6:30 call) | reminders#R17 | R630 | pass |
| J753 | `remind me next fri to pay rent` | none, Fri 17:40 | task "Pay rent" Fri 23 Oct 09:00, alerts T | reminders#R18 | D558, R630 | wrong write (RC7) |
| J754 | `remind me this weekend to clean the car` | none, Fri 17:40 | task "Clean the car" Sat 17 09:00, alerts T ("this weekend" is Saturday) | reminders#R19 | R630, FX | wrong write (DAYW) |
| J755 | `remind me in 3 days to call the bank` | none, Fri 17:40 | task "Call the bank" Mon 19 09:00, alerts T | reminders#R20 | R630, T706 | wrong write (RELT) |
| J756 | `remind me tomorrow at 9 to call mum` | none, Sat 00:30 | task "Call mum" Sat 17 09:00, alerts T ("tomorrow" before 04:00 is the coming daytime) | reminders#R21 | L607, N620 | wrong write (DAY4) |
| J757 | `remind me at 2am to take the bread out` | none, Fri 23:30 | task "Take the bread out" Sat 17 02:00, alerts T (rings in quiet hours; reply line in reminders.md) | reminders#R22 | L607, N620 | pass |
| J758 | `remind me tonight to call mum` | none, Sat 01:00 | task "Call mum" Sat 17 20:00, alerts T (reply line in reminders.md) | reminders#R23 | L607, T441, N620 | pass |
| J759 | `nudge me tomorrow` | none, Fri 17:40 | task "Reminder" Sat 17 09:00, alerts T | reminders#R24 | R630, T647 | wrong write (LEAD) |
| J760 | `ping me at 8 about the parcel` | none, Fri 17:40 | task "The parcel" Fri 16 20:00, alerts T | reminders#R25 | C1, N620, FX | wrong write (LEAD) |
| J761 | `don't let me forget to take my pills tonight` | none, Fri 17:40 | task "Take my pills" Fri 16 20:00, alerts T (from the lead; "tonight" alone is not a clock time) | reminders#R26 | T441, N620, FX | wrong write (LEAD) |
| J762 | `remind me later to call mum` | none, Fri 17:40 | task "Call mum" Later, alerts F (no instant) | reminders#R27 | N620 | wrong write (LEAD) |
| J763 | `remind me later` | none, Fri 17:40 | no write, asks "Remind you about what?" | reminders#R28 | FX | wrong write (LEAD) |
| J764 | `remind me when I get home to take the bins out` | none, Fri 17:40 | task "Take the bins out" Later, alerts F (no place reminders yet) | reminders#R29 | T647 | wrong write (PLACE) |
| J765 | `remind me when I leave work to buy eggs` | none, Fri 17:40 | groceries [Eggs] (no place reminders yet) | reminders#R30 | C3, T647 | wrong write (PLACE) |
| J766 | `remind me every sunday to plan the week` | none, Fri 17:40 | task "Plan the week" Sun 18 09:00, alerts T (first one only; repeats wait for Upkeep) | reminders#R31 | R630, T647 | wrong write (DAYW) |
| J767 | `cancel the 6pm reminder` | none, call mum alert, Fri 17:40 | SetTaskAlerts(Call mum, false), task kept [N1] · now: nil | reminders#R32 | T647 | wrong write (ALRT) |
| J768 | `move the call mum reminder to 7` | none, call mum alert, Fri 17:40 | reschedule Call mum Fri 16 19:00, alerts T (kept; the model until the RC13 batch) | reminders#R33 | C1, FX | miss (RC13) |
| J769 | `remind me again in 10` | none, call mum alert, Fri 18:02 | MoveTask(Call mum) Fri 16 18:12, alerts T (the alert that fired in the last 30 min) [N1] · now: nil | reminders#R34 | T647 | wrong write (ALRT) |
| J770 | `remind me to buy eggs` | none, Fri 17:40 | groceries [Eggs] (food with no day or time) | reminders#R35 | C3, T647 | wrong write (RBUY) |
| J771 | `remind me to buy eggs at 6` | none, Fri 17:40 | task "Buy eggs" Fri 16 18:00, alerts T | reminders#R36 | C1, N620 | pass |
| J772 | `uh remind me to um call the dentist tomorrow` | none, Fri 17:40 | task "Call the dentist" Sat 17 09:00, alerts T (after the normaliser drops uh and um) | reminders#R38 | R630 | wrong write (NRM) |
| J773 | `remind me to call mum at 6, actually 7` | none, Fri 17:40 | nil (model makes task "Call mum" Fri 16 19:00, with an alert) | reminders#R39 | Q622 | wrong write (GUARD) |
| J774 | `remind me at quarter to 7 to call mum` | none, Fri 17:40 | nil (model makes task "Call mum" Fri 16 18:45, with an alert) | reminders#R40 | Q622 | wrong write (GUARD) |

### K. Set logger (40 rows)

From `set-logger.md` (board item 61), traced at `0a27447`; the set rules are unchanged since `1d0833c`. New context words: `db` (Dumbbell Bench Press in focus, last set 24 x 10, starter rack 2 to 50 in 2 kg), `machine` (Lat Pulldown in focus, last set 55 x 10, 5 kg stack), `bw` (Pull-Up in focus, last set 0 x 8, added load in 2.5 kg), `no sets` (Bench Press in focus, nothing logged yet) and `spoken` (the heard text; the normaliser runs first once it lands, and master feeds it raw). Barbell loads are the starter kit's 20 to 177.5 in 2.5 kg steps. A note in brackets after a snapped weight is Tess's line, not part of the parse.

| id | phrase | context | expected parse | source rows | decision | status |
|---|---|---|---|---|---|---|
| K775 | `82.5` | live workout | nil (a weight with no reps: the model presets the dial or asks; never 82.5 reps) | set-logger#K775 | S701 | pass |
| K776 | `80 for 8` | live workout | set 80x8 | set-logger#K776 | MB | pass |
| K777 | `80x8` | live workout | set 80x8 | set-logger#K777 | MB | pass |
| K778 | `same` | live workout | set 80x8 (same) | set-logger#K778 | MB | pass |
| K779 | `one more` | live workout | set 80x8 (same) | set-logger#K779 | MB | pass |
| K780 | `8 reps` | live workout | set 80x8 (reps only) | set-logger#K780 | MB | pass |
| K781 | `12` | live workout, db | set 24x12 (reps only) | set-logger#K781 | S701 | pass |
| K782 | `24` | live workout, db | nil (24 is the last weight too: weight or reps, the model asks) | set-logger#K782 | S701 | wrong write (REPS) |
| K783 | `81` | live workout | nil (a weight with no reps; never 81 reps) | set-logger#K783 | S701 | wrong write (REPS) |
| K784 | `55` | live workout, machine | nil (above 50 reps and the last weight: the model asks) | set-logger#K784 | S701 | wrong write (REPS) |
| K785 | `+5` | live workout | nil (a relative change goes to the model, as `add 2.5`) | set-logger#K785 | T706, S702 | wrong write (REPS) |
| K786 | `-5` | live workout | nil (a relative change goes to the model) | set-logger#K786 | T706, S702 | wrong write (REPS) |
| K787 | `+2.5` | live workout | nil (a relative change goes to the model) | set-logger#K787 | T706, S702 | pass |
| K788 | `drop to 70 for 10` | live workout | set 70x10, drop | set-logger#K788 | MB | pass |
| K789 | `drop to 72 for 10` | live workout | set 72.5x10, drop (72 isn't loadable; 72.5) | set-logger#K789 | S703 | wrong write (SNAP) |
| K790 | `81 for 8` | live workout | set 80x8 (81 isn't loadable; 80) | set-logger#K790 | S703 | wrong write (SNAP) |
| K791 | `81.25 x 8` | live workout | set 80x8 (a tie goes to the lighter load) | set-logger#K791 | S703 | wrong write (SNAP) |
| K792 | `81.3 x 8` | live workout | set 82.5x8 (81.3 isn't loadable; 82.5) | set-logger#K792 | S703 | wrong write (SNAP) |
| K793 | `200 x 3` | live workout | nil (past the kit's heaviest load, 177.5: the model asks; never 177.5) | set-logger#K793 | S703 | wrong write (SNAP) |
| K794 | `25 x 10` | live workout, db | set 24x10 (25 isn't loadable; 24, the lighter of a tie) | set-logger#K794 | S703 | wrong write (SNAP) |
| K795 | `57.5 x 10` | live workout, machine | set 55x10 (57.5 isn't loadable; 55, the lighter of a tie) | set-logger#K795 | S703 | wrong write (SNAP) |
| K796 | `80 x 8, 81 x 6` | live workout | sets, 2 into Bench Press: 80x8, 80x6 (81 isn't loadable; 80) | set-logger#K796 | S703 | wrong write (SNAP) |
| K797 | `180 lb for 5` | live workout | set 81.6 kg x 5, unit lb (not snapped: the kit is in kg, as B316) | set-logger#K797 | MB, S703 | pass |
| K798 | `100 for 5 at 8` | live workout | set 100x5, RPE 8 | set-logger#K798 | T706, S704 | wrong write (RPE) |
| K799 | `same at 9` | live workout | set 80x8 (same), RPE 9 | set-logger#K799 | T706, S704 | wrong write (RPE) |
| K800 | `8 at 9` | live workout | set 80x8, RPE 9 | set-logger#K800 | T706, S704 | wrong write (RPE) |
| K801 | `fail at 6` | live workout | nil (failed on rep 6 or after 6 reps is unclear: the model asks; never a task) | set-logger#K801 | S705 | wrong write (SETT) |
| K802 | `80 x 6 to failure` | live workout | set 80x6, kind failure | set-logger#K802 | S705 | miss (KIND) |
| K803 | `warmup 60x5` | live workout | set 60x5, kind warmup | set-logger#K803 | S705 | miss (KIND) |
| K804 | `skip` | live workout | nil (skipping is the screen's; Tess never writes it) | set-logger#K804 | S706 | pass |
| K805 | `bodyweight 12` | live workout | nil (Bench Press is not a bodyweight lift: the model) | set-logger#K805 | S706 | pass |
| K806 | `bodyweight 12` | live workout, bw | set 0x12 (bodyweight, nothing added) | set-logger#K806 | S706 | miss (LOADW) |
| K807 | `+10 for 6` | live workout, bw | set 10x6 (10 kg added) | set-logger#K807 | S706 | miss (LOADW) |
| K808 | `two plates` | live workout | nil (plate counts need bar maths: the model) | set-logger#K808 | MB | pass |
| K809 | `bar for 10` | live workout | set 20x10 (the empty bar) | set-logger#K809 | S706 | miss (LOADW) |
| K810 | `eighty two and a half` | live workout, spoken | nil (the normaliser gives `82.5`, a weight with no reps, as K775) | set-logger#K810 | S701 | pass |
| K811 | `eighty two and a half for eight` | live workout, spoken | set 82.5x8 (after the normaliser: `82.5 for 8`) | set-logger#K811 | MB | miss (NRM) |
| K812 | `a hundred for five at eight` | live workout, spoken | set 100x5, RPE 8 (after the normaliser: `100 for 5 at 8`, then S704) | set-logger#K812 | T706, S704 | miss (NRM) |
| K813 | `same` | live workout, no sets | nil (nothing to repeat yet: the model) | set-logger#K813 | S701 | pass |
| K814 | `8` | live workout, no sets | nil (no last weight; never a weight of 8) | set-logger#K814 | S701 | pass |

<!-- rows:end -->

## Totals

Master `1d0833c`. Rows A to I keep their statuses except two: no file under `TesseraCore/` changed since `15fc404`, and the 6:20 and 6:30 calls move only the target of the rows they touch (the "now" parse on master is the old expected value). The 6:47 pass changes targets only (17 rows gated on N1, statuses carry). The 5:58 pass flips A117 to pass (master already writes Sat 08:00) and C389 to wrong write (master moves the Dentist to Fri 16, not 23). The 7:06 pass flips B302 and B310 to pass (master already returns nil), gates nine rows that pass today and moves H611 from N1 to Money. Group J is new. Group K (40 rows, set logger) is new, traced on `0a27447`.

### By status

| status | rows | share |
|---|---|---|
| pass | 613 | 75.3% |
| wrong write | 121 | 14.9% |
| miss | 80 | 9.8% |
| **all** | **814** | |

Wrong writes are the ones to fix first: each puts a wrong object, date or title into the store with no question asked. A miss only costs a model call (or, offline, a "say it another way"). Before group K: 774 rows, 597 pass, 104 wrong write, 73 miss. Before group J: 736 rows, 586 pass, 78 wrong write, 72 miss. Before the 7:06 call: 595 pass, 104 wrong write, 75 miss.

### By group

| group | rows | pass | wrong write | miss |
|---|---|---|---|---|
| A. Everyday, kitchen and training | 295 | 240 | 38 | 17 |
| B. Spoken (normalised text) | 72 | 60 | 7 | 5 |
| C. Reschedule and time | 72 | 31 | 12 | 29 |
| D. Cook timers | 37 | 12 | 6 | 19 |
| E. People names | 40 | 37 | 3 | 0 |
| F. People | 34 | 32 | 2 | 0 |
| G. Reading | 40 | 39 | 1 | 0 |
| H. Money | 45 | 43 | 2 | 0 |
| I. Upkeep and starters | 101 | 94 | 7 | 0 |
| J. Reminders | 38 | 9 | 26 | 3 |
| K. Set logger | 40 | 16 | 17 | 7 |
| **all** | **814** | **613** | **121** | **80** |

### Gated and not gated

A gated row is judged on its "now" parse. 256 rows are gated (waiting on a slice); 240 of them pass today, so most of the work on those rows waits for the slice, not for the grammar. On top of that, 111 rows carry an `alerts` mark whose check waits on N1 (79 rows A to I, 32 rows in J); none can pass it on master, and none is counted as failing for it.

| gate | rows | pass | wrong write | miss |
|---|---|---|---|---|
| Upkeep (3 of them also need `did` narrowed; 1 also needs month dates) | 77 | 75 | 2 | 0 |
| People (1 also needs month dates; 8 also need N1) | 44 | 44 | 0 | 0 |
| Money | 39 | 37 | 2 | 0 |
| Reading | 30 | 29 | 1 | 0 |
| N1 only (56 dated tasks and cooks with no time, J767 and J769 alert edits) | 58 | 49 | 9 | 0 |
| Month dates (I655, also needs N1) | 1 | 1 | 0 | 0 |
| 12b (cook pause and extend) | 4 | 3 | 0 | 1 |
| Lists 8 | 3 | 2 | 1 | 0 |
| **gated** | **256** | **240** | **15** | **1** |
| **not gated** | **558** | **373** | **106** | **79** |

### By root cause (rows that do not pass)

| root cause | what goes wrong | rows | wrong write | miss |
|---|---|---|---|---|
| RC11 | `half 7`, `7.30`, `7 pm`, `6 PM`, `morning`/`afternoon`/`evening` not read; colon numbers always a time | 29 | 9 | 20 |
| RC15 | cook timers need the word "timer"; `10 min`, `rice 12`, `finished cooking` not read | 27 | 5 | 22 |
| RC13 | reschedule replaces the whole date, misses `push`/`bump`/`can you move` shapes and a bare hour after `to` | 17 | 5 | 12 |
| RELT | relative dates (`in 20 min`, `in an hour`, `in 2h`, `in 3 days`, `day after tomorrow`, `N days before`) | 15 | 12 | 3 |
| RC6 | a set and an errand in one phrase, no split | 14 | 9 | 5 |
| RC12 | lift edge cases (day words, `at N`, bodyweight, `curls`, reps cap) | 8 | 8 | 0 |
| SNAP | a weight said to Tess logged as said: not snapped to the exercise's loads, not checked against its range | 8 | 8 | 0 |
| REPS | any whole number 1 to 100 read as reps, even a weight (`81`, `55`) or a signed change (`+5`, `-5`) | 5 | 5 | 0 |
| LEAD | reminder leads (`ping`, `nudge`, `don't let me forget`, `set a reminder for`), `about`/`later` after the lead, empty title | 7 | 5 | 2 |
| RC2 | past-tense log edge cases (adjective `-ed` titles, `moved X to fri`) | 7 | 7 | 0 |
| RC8 | comma list called groceries on one food item | 6 | 6 | 0 |
| RC10 | short weekdays (`sun`, `sat`, `wed`, `mon`) eaten as days | 5 | 5 | 0 |
| RC3 | `get`/`buy` puts people, services, non-food on the list | 5 | 5 | 0 |
| RC7 | `next` left in the title or ignored (`dentist next fri`, `move dentist to next fri`), `to` leftovers | 4 | 4 | 0 |
| RPE | `@N` after a set; `at N` after a set read as a clock time, so the set becomes a task (K) | 7 | 3 | 4 |
| RC17 | `out of X`, `need X` not grocery phrases | 3 | 0 | 3 |
| LOADW | load words not read (`bodyweight N`, `+W for R` on a bodyweight lift, `bar for N`) | 3 | 0 | 3 |
| NRM | spoken shape the normaliser should reshape (incl. `uh`, `um`, number words in a set) | 5 | 3 | 2 |
| ADD | `add X` outside a workout (`add N` in a workout goes to the model, T706) | 1 | 0 | 1 |
| ORD | ordinal dates (`the 20th`) | 2 | 2 | 0 |
| KIND | set kind words not read (`to failure`, `warmup`) | 2 | 0 | 2 |
| DAY4 | the 4 AM day (`tomorrow` at 00:30) and `tonight` after 20:00 | 2 | 2 | 0 |
| DAYW | `this weekend`, `every <day>` | 2 | 2 | 0 |
| PLACE | `when I get home`, `when I leave work` not stripped | 2 | 2 | 0 |
| ALRT | alert edits (`cancel the 6pm reminder`, `again in 10`) | 2 | 2 | 0 |
| GUARD | remind phrase that needs the model (`actually 7`, `quarter to 7`) claimed by the grammar | 2 | 2 | 0 |
| RC1 | bare hour cue list (`alarm`; `table` is settled) | 1 | 1 | 0 |
| RC4 | shop run takes an errand as a line | 1 | 1 | 0 |
| RC5 | question guard gap | 1 | 1 | 0 |
| RC14 | `done for today` in a workout | 1 | 1 | 0 |
| RC16 | `note to self` | 1 | 1 | 0 |
| RC18 | bare amount and food | 1 | 0 | 1 |
| RC19 | possessive day word in a grocery line | 1 | 1 | 0 |
| RC20 | named list prefix | 1 | 1 | 0 |
| UPK | upkeep verb falls through to the task rule | 1 | 1 | 0 |
| RBUY | `remind me to buy` food with no day or time stays a task | 1 | 1 | 0 |
| SETT | a set word with `at N` (`fail at 6`) falls to the task rule | 1 | 1 | 0 |
| **all** | | **201** | **121** | **80** |

Four causes (RC11, RC15, RC13, RELT) hold 88 of the 201 failing rows. RC11, RC13 and RELT all sit in `TessDates.find` (return which parts were said, read the missing time forms, read `in N`), so one Core change there clears about 61 rows. For the reminder rows, `reminders.md`'s ten grammar changes map onto these codes: relative times (RELT, 7 rows in J), leads (LEAD, 7), and the `alerts` field (N1, all 111 marked rows).

## How Core loads this table (Swift Testing sketch)

The file is the single source. Core copies it into the test bundle (`resources: [.copy("Fixtures/grammar-regression.md")]` on `TesseraCoreTests`) and reads the rows between the two markers. Each row has seven cells. The test builds the context from the context cell, parses the phrase, and compares the parse kind (the same `kind` string `GrammarMisfireTests` uses, with quotes dropped) against the expected cell. For a gated row it compares against the "now" part until that gate's flag is on; the target is checked under `withKnownIssue` so it turns green, and the known issue fails loudly, the day the slice lands. Rows marked wrong write or miss are wrapped in `withKnownIssue` too, keyed by root cause, so the suite is green on master and each fix flips its rows on purpose.

```swift
import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

struct RegressionRow: Sendable, CustomTestStringConvertible {
    let id: String              // "C377"
    let phrase: String          // without the backticks
    let context: String         // "none, tasks, 23:30"
    let target: String          // expected parse, gate part removed
    let gates: [String]         // ["Upkeep"], ["People", "N1"], ... or []
    let now: String?            // the "now:" parse for a gated row
    let sources: String
    let decision: String
    let status: Status
    let rootCause: String?      // "RC11", "RELT", ...
    let alerts: Bool?           // "alerts T" / "alerts F" in the target, outside parentheses; nil = not checked

    enum Status: String, Sendable { case pass, wrongWrite = "wrong write", miss }
    var testDescription: String { "\(id) \(phrase) [\(context)]" }
}

enum RegressionTable {
    static let rows: [RegressionRow] = {
        let url = Bundle.module.url(forResource: "grammar-regression", withExtension: "md")!
        let text = try! String(contentsOf: url, encoding: .utf8)
        let body = text.components(separatedBy: "<!-- rows:start -->")[1]
            .components(separatedBy: "<!-- rows:end -->")[0]
        return body.split(separator: "\n").compactMap(parse)
    }()

    /// One table line to a row. Cells are split on " | " that is not escaped as "\|".
    static func parse(_ line: Substring) -> RegressionRow? {
        guard line.hasPrefix("| "), let first = line.dropFirst(2).first, first.isLetter,
              line.dropFirst(3).first?.isNumber == true else { return nil }   // skips headers and rules
        let cells = line.dropFirst(2).dropLast(2)
            .split(separator: /(?<!\\) \| /).map { $0.replacing("\\|", with: "|") }
        guard cells.count == 7 else { Issue.record("bad row: \(line)"); return nil }
        let (expected, gates, now) = splitGate(cells[3])        // "X [People, N1] · now: Y"
        let bare = expected.replacing(/\([^)]*\)/, with: "")   // notes like "(6:30 call)" never count
        let alerts = bare.firstMatch(of: /alerts ([TF])/).map { $0.1 == "T" }
        let status = cells[6].firstMatch(of: /^(pass|wrong write|miss)(?: \((\w+)\))?/)!
        return RegressionRow(id: cells[0], phrase: cells[1].trimming(while: { $0 == "`" }),
                             context: cells[2], target: expected, gates: gates, now: now,
                             sources: cells[4], decision: cells[5],
                             status: .init(rawValue: String(status.1))!, rootCause: status.2.map(String.init),
                             alerts: alerts)
    }
}

@MainActor
struct GrammarRegressionTests {
    let world: RegressionWorld   // builds the five stores once and hands out TessContext values

    init() throws { world = try RegressionWorld() }

    @Test(arguments: RegressionTable.rows)
    func row(_ row: RegressionRow) throws {
        let context = try world.context(for: row.context)   // mode, store, clock (default Thu 15 18:10 LA)
        let parse = world.grammar(for: row.context).parse(row.phrase, context: context)
        let got = world.kind(parse)
        let want = row.gates.allSatisfy(Gates.isOn) ? row.target : row.now!

        switch row.status {
        case .pass:
            #expect(normalised(got) == normalised(want), "\(row.id) decided by \(row.decision)")
        case .wrongWrite, .miss:
            withKnownIssue("\(row.id) \(row.rootCause ?? "?")") {
                #expect(normalised(got) == normalised(want))
            }
        }

        // alerts (6:20 and 6:30 PM PT calls): checked apart from the kind, and only once N1 adds the field.
        if let wantAlerts = row.alerts {
            let gotAlerts = world.alerts(of: parse)   // nil until N1 adds Parse.task(title:startsAt:alerts:)
            if Gates.isOn("N1") {
                #expect(gotAlerts == wantAlerts, "\(row.id) alerts decided by \(row.decision)")
            } else {
                withKnownIssue("\(row.id) alerts wait on N1") { #expect(gotAlerts == wantAlerts) }
            }
        }
    }
}
```

Notes for Core:
- `RegressionWorld.context(for:)` reads the comma parts of the context cell in order: the mode (`none`, `live workout`, `shop run`, `cook`), then any store words (`tasks`, `people`, `book`, `chores`, `total awaited`, `Soften flared`, `last step`, and the rest listed under "How to read the table"), then an optional `HH:mm` clock. One store per word, built once per suite.
- The clock part of the context may carry a day (`Fri 17:40`, `Sat 00:30`, group J); a bare `HH:mm` stays on Thu 15. The store word `call mum alert` adds "Call mum" Fri 16 18:00 with `alerts` true.
- `normalised` also drops `, alerts T` and `, alerts F` (checked on their own above), and `world.kind` prints a dated task with no time as `Sat 17, no time` once N1 lands.
- `normalised` drops the quotes and any parenthesised note in the expected cell ("(`alarm` is not an AM cue)"), so the cell can carry a reason without breaking the match.
- The status column on master is the baseline. When a fix lands, its rows move to `pass` in this file in the same PR; a known issue that stops failing tells the author which rows to flip.
- The 5 existing `GrammarMisfireTests` and `GrammarRulesTests` rows that overlap stay where they are until this suite is in, then go.

## Open questions for Product

1. **Closed (5:58 call 1).** "table" is not a meal word; A117 is Sat 17 08:00.
2. **Closed (5:58 call 2).** "tonight" after 8 PM is tonight, as T441, until 11:30 PM. The 21:00 row is J751 (21:15, master fails it, DAY4); C405 and C437 at 23:30 keep tomorrow.
3. **Closed (5:58 call 3).** Next week's Friday, 23 Oct: A222, C389, J753, all failing on RC7.
4. **Closed (5:58 call 4)** for R13c, f, g, i and j (12 rows, conflict 28). R13e and R13h closed by the 6:50 call (T650): never in the past, roll to the next occurrence (C379); no task named means the task on Now (C392).
5. **Closed (7:06 call).** The grammar reads `in N` and `day after tomorrow`, and a plain relative time rings (B338, C422 to C425, C438 gain `alerts T`); `2 days before the MOT` goes to the model (B347); in a cook `remind me in 20 minutes` is a timer (D464).
6. **Closed (7:06 call).** RPE `@N` is read in a live workout only (B303 to B306); a drop with no reps and `add 2.5` go to the model (B302, B310, now pass); `add X` outside a workout is Groceries (B334).
7. **Closed (7:06 call).** M8 is taken: `12.40 lunch fri` goes to the model once Money lands, and master keeps its task until then (H611, gated on Money). `paid 12.50 at 12.30` was closed by 5:58 call 5 (C430).
8. **Closed (5:58 call 6).** "done" ends a ringing timer first (D465).
9. **Closed (7:06 call).** Percent sets the page from the page count and asks when there is none (G579, G580); a Kindle location goes to the model (G581); `abandoned`, `gave up on`, `dnf` set the book aside (G589); a bare number is the page of the book in front (G561).
10. **Closed (7:06 call).** `rang mum` is a call (F519); `lunch with ravi` asks plan or done (F531); `buy flowers for mum` is a task about Mum once Mum is a Person (A070); a lone `will` in a shop run is ignored (E501).
11. **Closed (5:58 call 7).** The suite runs on Los Angeles time, as this table already does (Thu 15 18:10, group J on Fri 16).
12. **Closed (7:06 call).** `basil and tomatoes` goes to the model for now (E498); no training partner link (E514); a month alone is the 1st and a month is 30 days once the month parser lands (I655, I659); `bins every thursday` keeps "Bins every Thursday" (I660).

13. **Closed (6:30 and 6:47 calls).** Every `reminders.md` default stands as the J rows have it: "Reminder" with no subject (J737, J742, J759), `remind me to buy eggs` to Groceries (J770), place reminders to Later with no alert (J764, J765), repeats take the first one only (J766), cancel keeps the task and drops the alert (J767), `again in N` with no recent alert goes to the model.
14. **Closed (6:47 call).** "morning" stays 09:00; the next-whole-hour default goes for a weekday that is today, `today` with no time and a cook with a day (17 rows, conflict 29).
15. **Open (board item 61).** The set-logger defaults S701 to S706 are proposals. Until Product answers, the K rows are judged on them; none of them writes where master does not, so taking them can only turn a wrong write into a miss or the right write. Worst today: a set with an RPE said with `at` becomes a task (K798 to K800), and a weight typed alone is logged as that many reps (K782 to K784).

Core notes (no Product call needed): the past-log rule must move after the Upkeep rule when Upkeep lands, or every `watered plants sat` stays a note (E504); and the `did` narrowing in the question guard must ship with Upkeep, not before.
