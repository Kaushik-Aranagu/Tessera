# Monday's week-two kit (board item 144, for 101)

For: the coordinator and Product. Owner: Research lab. Date: Oct 16, 2026 (Pacific). Builds on `week-two.md` (101),
`week-two-pulls.md` (128, P0 to P10), `week-one-checkin.md`, `oct-22-list.md` and `decisions.md` through 11:08 am
Oct 16. Code checked by hand on `origin/master` at `215469f` (#427) and on his phone's build `7b321d2`. Nothing run.

**What changed since `week-two.md` (the four facts that drive the stale flags in §3).**
1. **His phone runs `7b321d2`** (installed 9:57 am Oct 16, catalog v5), not `b19fb4a`. It carries the set ask (#248,
   #254, checked). The next pin waits on #366 and the refused-hold fix; signing lapses about 9:57 am Oct 23.
2. **Fixed days are built on master, not on his phone.** #341 (v6: `scheduleMode`, `fixedWeekdays`), #359 (Routines
   page: ROLLS ON / FIXED DAYS, pin a routine to days) and #363 (plan days, WeekFacts). In FIXED DAYS a day with no
   routine is rest, and a missed fixed day waits for its weekday (Product, 12:32 am Oct 16).
3. **`restWeekday` is stored but read by nothing.** It is in the settings object on master and on `7b321d2`
   (`TesseraSettings.swift:25`), but `week()`, `restDay` and NowPage never read it (no hit outside Settings).
4. **Day marks are decided, not built** ("rest day today", 2:53 am Oct 16; no "Rest today" in code). A planned session
   beats a rest day (3:05 am). A set now stores a best flag (#344, v6+), so bests can be counted on a v6+ copy.
   #381 and #397 (live workout on the new frame) change no question; the set ask and its words are unchanged.

## 1. Monday Oct 19 run order (PDT)

| # | Time | Step | Who |
|---|---|---|---|
| 1 | 7:00 am | Which build is on his phone: `7b321d2`, or a newer pin? Check `decisions.md` for any "Kaushik" since Oct 16 (a rest-day answer drops Q4) | coordinator |
| 2 | 7:30 am | Copy the newest `.tessera` to `~/tessera-checkin`; P0 (copy health, `backupInfo`, `quick_check`). P0 fails or no copy: go to message B | Mac session |
| 3 | 7:40 am | One pass, about 10 minutes: P1, P2, P3, P5, P7, P8, P9 with S=1792148400, E=1792407600. On a v6+ copy, P5 counts the stored best flag (#344) | Mac session |
| 4 | 8:00 am | Post counts, weekdays, routine and exercise names only (§4) to the coordinator's note | Mac session |
| 5 | 8:15 am | Fill message A from the counts (or take B); pick each question's wording by the rules under §2 | coordinator |
| 6 | 8:30 am | Findings that move work whatever he answers (a 0-set wrap-up, kept light Tess sets) go to Product now | coordinator |
| 7 | 8:45 am | Pre-fill §3's blocks with the counts so only his reply time is left | coordinator |
| 8 | 9:50 am | The training-questions trigger fires: send the message | coordinator |
| 9 | Reply + 20 min | `decisions.md` lines, then the board edits grouped by board, in one message to Product; Product applies and tells each owner by reply + 45 min | coordinator, Product |
| 10 | 6:00 pm | Anything unanswered carries to Thursday (`oct-22-list.md`): Q4 is already its question 12; the rest go in Thursday's 6:00 pm message; Q1 drops as stale | coordinator |

## 2. The message (ready to paste)

**A. With data** (P0 passed and the copy has sets).
```
Morning! Your first training weekend, from last night's backup:
[days trained] days trained ([Sat Push A, Sun Pull A]), [sets] sets in all.
[N] new bests: [Bench press, Lat pulldown].
Your training week starts today. 5 quick ones, one word each. Reply "defaults" to take every ★.
1. [Sat] [Push A]: [17] sets. All of them? ★All / Most / Few
2. No workout [Sunday], so today is [Pull A]. Good? ★Yes / No
3. When you say "2 x 10", I ask "2 sets, or 2 kg?". Keep asking? ★Keep / Less / Never
4. Rest day: Sunday? ★Yes / Another day (say which) / Any
5. Do the app's weights match your gym? ★Yes / Dumbbells / Plates
```
Wording rules: no sets before S means every lift is new, so line 3 reads "First numbers on [Bench press, Squat]."
P9 `system` finish: Q1 reads "[Push A] closed itself after 6 hours with [17] sets. All of them?". No empty day:
Q2 reads "If you miss a day, pick up where you left off?". No Tess sets (P7): Q3 reads "If you say "2 x 10", should
I ask "2 sets, or 2 kg?" first? ★Ask / Sets". P8 `near_top` over 0: Q5 reads "The bar tops out at 177.5 kg in the
app. Enough? ★Yes / Plates"; `edits` 3 or more adds "You fixed [4] weights." first. Q4 already answered: drop it and
say "4 quick ones". Folder not set: add "6. 30 s: Review > Backups > a folder you choose > iCloud Drive/Tessera. ★Done".

**B. No data** (P0 fails, or no copy).
```
Morning! I couldn't read your weekend from the backup, so no numbers today.
Your training week starts today. 5 quick ones, one word each. Reply "defaults" to take every ★.
1. Did every set you lifted this weekend get logged? ★Yes / Most / Didn't train
2. If you miss a day, pick up where you left off? ★Yes / No
3. If you say "2 x 10", should I ask "2 sets, or 2 kg?" first? ★Ask / Sets
4. Rest day: Sunday? ★Yes / Another day (say which) / Any
5. Do the app's weights match your gym? ★Yes / Dumbbells / Plates
6. 30 s: Review > Backups > a folder you choose > iCloud Drive/Tessera. ★Done
```
B's Q1 is new (closes `week-two.md` open question 2): Yes = All, Most = Most, Didn't train = no edit.

## 3. Edit blocks per answer, on today's master

"As written" means paste the `week-two.md` §3 block unchanged. Receipts are thing first. `<time>` is his reply time.

| Q | Answer | Edit (what changes) | Owner | vs `week-two.md` |
|---|---|---|---|---|
| Q1 | All ★ | None. 6 h auto-finish stays | none | as written |
| Q1 | Most | Core: save right after each Lock Screen and Siri set (still autosave, `TesseraContext.swift:222-230`). Builder A: the finish step, only if P9 had a `system` finish | Core, Builder A | as written |
| Q1 | Few | Research sets-logged watch; Design taps per set; Builder A builds Design's change | Research, Design, Builder A | as written |
| Q2 | Yes ★ | None. The plan stays ROLLS ON; a missed day rolls on (`PlanSchedule.swift:8-31`) | none | as written |
| Q2 | No | `decisions.md`: "Fixed days, a missed day waits (<time> PT, Kaushik, Monday Q2 No)". Then one op with UNDO on the first v6+ launch: PPL x2 to FIXED DAYS, Push A Mon to Legs B Sat ("PPL x2, on fixed days."). Builder A writes it, or he does it on the Routines page. QA checks Now, Review and the Plans week on his restored copy | Product, Builder A, QA | **stale** (see below) |
| Q3 | Keep ★ | Core's done note gets "; Kaushik kept the ask Mon 19 Oct (<time> PT)" | Core | stale wording only |
| Q3 | Less | Core: ask at N of 3 or less (`setCount`, `TessGrammar+Live.swift:141`); Research re-runs K876 to K881, K817, D473, Q01 to Q28 | Core, Research | stale deadline |
| Q3 | Never | `decisions.md` line, Core drops the bare N x M ask, Builder A line edit, Research rows to "sets" | Product, Core, Builder A, Research | stale deadline |
| Q4 | Yes ★ | `decisions.md`: "Sunday, rest day" (new). Core: on the first launch after the answer, one op with UNDO writes `restWeekday` = 1 ("Sunday, rest day."), and `week()` and `restDay` read it on a rolling plan (6 a week over Mon to Sat). Builder B and Builder A pass nothing new: they already call `week()`. Research fixtures, QA review | Product, Core, Research, QA | **stale** (see below) |
| Q4 | Another day | The same with that day's number (Mon 2 to Sat 7) | same | as above |
| Q4 | Any | `decisions.md` "No fixed rest weekday"; `restWeekday` stays empty | Product | as written |
| Q5 | Yes ★ | None | none | as written |
| Q5 | Plates | Core: two pairs of 25 and 20 (`TesseraCore/Sources/TesseraCore/Catalog/StarterContent.swift:60`), his Equipment by one op with UNDO ("Plates, two pairs of 25 and 20."), skipping values he set. Research re-runs kit rows | Core, Research | stale path and receipt |
| Q5 | Dumbbells | Send "Dumbbells: steps of 2.5 kg or 1 kg? ★2.5 / 1" the same day, then Core's rack block (line 61) and Research's rows | coordinator, Core, Research | stale path and receipt |
| all | any | Thursday: drop `oct-22-list.md` question 12 once Q4 is answered. Research's week-two re-read on Mon Oct 26 | coordinator, Research | new; as written |

**Stale in `week-two.md`, and why.**
- §1 fact 1, §5 7:00 am row, Q3 intro, W4 and the findings row: "his phone runs `b19fb4a`, no ask until Oct 22".
  He has `7b321d2` with the ask, so Q3 uses its with-data wording, and kept light Tess sets mean a miss of the ask.
- Q3 Less and Never: "must merge before the Oct 22 install". The ask is already on his phone, so either change simply
  rides the next pin; it no longer races one.
- §1 fact 2 and the Q4 Yes Core block: "`restWeekday` is not on master", "catalog v4". It is stored (#258, master is
  v9) but read by nothing. The remaining Core work is the reader in `week()` and `restDay`, plus the one-time write.
  Builder B's and Builder A's Q4 items shrink to a check that Now, Review and Plans show Sunday as rest.
- Q2 No (all 6 blocks): `startsOn`, a new catalog field and the Builder A and B "by weekday" items are built (#341,
  #359, #363). What remains is switching his plan and pinning days, after a v6+ build is on his phone.
- §4 defaults line and Q4 timing: "in the Oct 22 install so Sun 25 Oct shows it". Now: the next pin, before the
  Oct 23 signing lapse. If the reader misses it, Sunday keeps the engine's floating rest day.
- Receipts "Rest day: Sunday." and "Plates: two pairs of 25 and 20." break thing first (3:15 am Oct 16).
- W5 and Q5 `StarterContent.swift:60-61` paths: the file is under `TesseraCore/Sources/TesseraCore/Catalog/`.

## 4. Privacy (what leaves the Mac)

- **May leave:** counts (sets, days, starts, finishes, undos, edits, `near_top`, light-set count), weekdays, routine
  names, exercise names (P5 prints names only), kit settings (bar, plates, dumbbell rack), build and copy dates.
- **Never leaves:** any set weight or reps, e1RM values, body facts (weight, Health values), money, note bodies, the
  Claude key. The `.tessera` copy stays in `~/tessera-checkin`, read with `sqlite3 -readonly`, deleted after 7 days.
  The message quotes counts and names only: "[17] sets" is fine; "Bench 80 × 8" is not.

## 5. Needs a Product call before Monday 8:15 am

1. **Q4 Yes: `restWeekday` on a rolling plan, or FIXED DAYS Mon to Sat?** FIXED DAYS is built and needs no code, but
   a missed day then waits instead of rolling on, which contradicts Q2's default. Recommend `restWeekday` with a
   rolling plan (Core's reader above), and the rule that FIXED DAYS ignores `restWeekday` (an unpinned day is rest).
2. **Message B's Q1** ("Did every set get logged? ★Yes / Most / Didn't train"), replacing 86's starless wording.
3. **Q2 No: who flips the plan.** Recommend he does it on the Routines page after the pin; Builder A's op if he asks.

**Decided (Product, decisions.md 11:47 AM PT Oct 16):** Q4 "Yes, Sunday" keeps the rolling plan with `restWeekday`, and fixed days ignore it (Core's reader comes after the pin blockers). Message B's Q1 is "Did every set you lifted this weekend get logged? ★Yes / Most / Didn't train". On Q2 "No", he switches to fixed days himself on the Routines page once the pin is on his phone, and Builder A does it only if he asks.
