# Grammar open questions: one default each

For: Product, then Core (board item 33). Research lab. Date: 2026-10-16.

The open questions 5, 6, 7, 9, 10 and 12 in `fixtures/grammar-regression.md`, split into 20 single calls. Each call has a plain question you can answer in one word, the options, one recommended default, the rows it changes (expected value before -> after) and the status on master `1d0833c` after the change. Defaults follow the standing preferences: velocity over perfection, a miss to the model beats a wrong write, ADHD-friendly (one tap, no guessing), kg, 4 AM day, quiet hours 23:00 to 07:00. "Confirm" means the default keeps the fixture's value, so no row changes. `grammar-regression.md` is not edited here.

## 5. Relative times

**5a. Should the grammar read `in 20 min`, `in 2 hours`, `in an hour`, `in 3 days` and `day after tomorrow` itself? (yes/no)**
- Yes: `TessDates` adds the offset to the clock (days count from the 4 AM day); no model call.
- No: send them to the model (one Haiku call each, slower for "remind me in 20 min").
- **Default: yes.** Pure arithmetic on a clock the grammar already has, and the most common reminder shape.
- Rows: confirm B338, B343, C422 to C425, C438, J737 to J743, J755. Master still fails them (RELT) until Core builds it.

**5b. Does a plain relative time with no "remind me" (`call mum in 2 hours`) ring? (yes/no)**
- Yes: it names an exact instant, the same as a clock time under N620.
- No: it is only a dated task, `alerts F`.
- **Default: yes.** He gave the instant; at 23:30 `in 2 hours` (01:30) still rings, as `notifications.md` section 4 lets a timed task through quiet hours.
- Rows: add `alerts T` to C422, C423, C438, and to B338, C424, C425 (their "remind me" already implies it). The `alerts` marks go from 105 to 111; statuses do not change (N1).

**5c. Does `remind me 2 days before the MOT` go to the model? (yes/no)**
- Yes: the date depends on another object, which is judgement (Q622).
- No: the grammar finds a task named "MOT" and subtracts.
- **Default: yes.** Rare, and a wrong lookup would be a silent wrong date.
- Rows: confirm B347 (nil). Master stays wrong write (makes the task "2 days before the MOT") until Core sends `N days before/after X` to the model.

**5d. While cooking, is `remind me in 20 minutes to take the chicken out` a timer? (timer/task)**
- Timer: a linked cook timer "Take the chicken out", 20 min, on the cook screen and Live Activity.
- Task: a task at 18:20 with `alerts T`, as outside a cook (J738).
- **Default: timer.** Cook mode owns short durations (K450), and the timer is the thing on screen while he cooks.
- Rows: confirm D464. Master stays wrong write (RC15).

## 6. Workout extras

**6a. Does the grammar save RPE from `80 x 8 @8` and `same @9`, live workout only? (yes/no)**
- Yes: log the set with its RPE (the `rpe` field already exists on a set); `@N` from 5 to 10 in half steps.
- No: send it to the model.
- **Default: yes, live workout only.** Every number was said, nothing is guessed, and a set mid-workout should never wait on a model call. Idle `bench 80x8 at 7` keeps A184 (nil).
- Rows: confirm B303 to B306. Master stays miss (RPE) until Core adds the rule.

**6b. With no reps (`drop to 70`), does the grammar log a drop set at the last reps? (yes/no)**
- Yes: drop set 70 x 8, reps copied from the last set.
- No: send it to the model, which can ask for the reps.
- **Default: no.** The reps of a drop set are usually different, so 8 is a guess; `drop to 70 for 10` already works.
- Rows: B302 `drop set 70 x last reps (8)` -> `nil`. Master passes (miss -> pass).

**6c. Does `add 2.5` in a workout log a set at last weight plus 2.5? (yes/no)**
- Yes: set 82.5 x 8, reps copied from the last set.
- No: send it to the model (a later build could dial the next set to 82.5 without logging).
- **Default: no.** "add 2.5" is usually what goes on the bar next, not a set already done, so logging it writes a set he has not lifted.
- Rows: B310 `set 82.5x8 (last weight plus 2.5)` -> `nil`. Master passes (miss -> pass).

**6d. Outside a workout, does `add X` put food on Groceries? (yes/no)**
- Yes: `add 2 tins of chickpeas` is a grocery line, unless X names a list (GC 40).
- No: send it to the model.
- **Default: yes.** "add" is a list verb and the object is food.
- Rows: confirm B334. Master stays miss (ADD) until Core adds `add` as a grocery lead.

## 7. Money

**7. Does `12.40 lunch fri` go to the model once Money lands (M8)? (yes/no)**
- Yes (M8): a money-shaped phrase with a future day and no task verb goes to the model, so no task is titled with a price.
- No: keep the approved rule, task "12.40 lunch" Fri.
- **Default: yes, gated on Money.** "12.40 lunch fri" may be a spend or lunch at 12:40, and a price in a task title is a wrong write; Money brings the amount check, so master keeps its task until then.
- Rows: H611 `task "12.40 lunch" Fri 16, no time, alerts F [N1] · now: task ... 09:00` -> `nil (M8) [Money] · now: task "12.40 lunch" Fri 16 09:00`. Master passes (pass, gated).

## 9. Reading gaps

**9a. Does `dune 45%` set the page from the book's page count? (yes/no)**
- Yes: 45% of 612 is p 275 (rounded down); with no page count, ask "How many pages?"; a Kindle location still goes to the model.
- No: all percent and location phrases go to the model.
- **Default: yes.** One multiplication, no new field, and the ask covers the unknown case.
- Rows: G579 `nil` -> `SetBookPage(Dune, 275) [Reading] · now: nil`; G580 `nil` -> `no write, asks "Atomic Habits has no page count. How many pages?" [Reading] · now: nil`; G581 confirm (nil). Master passes all three (gated).

**9b. Are `abandoned dune`, `gave up on dune` and `dnf dune` the same as `set Dune aside`? (yes/no)**
- Yes: SetBookAside(Dune), page kept, one undo.
- No: the model handles them.
- **Default: yes.** Unambiguous words, undoable, and they match the approved S4 verb; `dropped` stays off the drop-set regex.
- Rows: G589 `nil` -> `SetBookAside(Dune) [Reading] · now: nil`. Master passes (gated).

**9c. With a book in front, is a bare `142` its page? (yes/no)**
- Yes: SetBookPage on the book in front only; a waiting shop total (M410), a workout or a cook claims the number first, and two books with none in front give nil.
- No: keep `p` required.
- **Default: yes.** The book is the running thing, the same as a bare number in a workout is a set (GC rule 4).
- Rows: G561 `nil` -> `SetBookPage(Dune, 142) [Reading] · now: nil`. Master passes (gated). G556 (`p 142`, two books, last touched) unchanged.

## 10. People gaps

**10a. Does `rang mum` count as calling Mum? (yes/no)**
- Yes: `rang`, `rung`, `phoned` join `called` as one contact family: SetTaskDone("Call mum"), or LogTalk when the task is done.
- No: leave them to the model.
- **Default: yes.** Same meaning as `called mum` (F517), and a UK speaker says "rang" as often.
- Rows: F519 `nil` -> `SetTaskDone("Call mum") [People] · now: nil`. Master passes (gated).

**10b. Is `lunch with ravi` (no day, no verb) a plan or a log? (ask/model)**
- Ask: a ghost row "Lunch with Ravi: plan or done?", plan on top (task Later, about Ravi), log second (LogTalk now); nothing is written until he taps.
- Model: send it to the model.
- **Default: ask.** One tap, no guess and no model call; with a day or a time it stays a task (A103, E480).
- Rows: F531 `nil` -> `ambiguous: task "Lunch with ravi" Later, about Ravi, or LogTalk(Ravi) now, waits for a tap [People] · now: nil`. Master passes (gated).

**10c. Once Mum is a Person, is `buy flowers for mum` a gift task? (yes/no)**
- Yes: an unclear object `for <Person>` is a task about that person (as E495); clear food stays Groceries (E496).
- No: unclear stays Groceries (B430) even with a person.
- **Default: yes.** Flowers for Mum is a gift errand, not the weekly shop.
- Rows: A070 `groceries [flowers for mum]` -> `task "Buy flowers for mum" Later, about Mum [People] · now: groceries [flowers for mum]`. Master passes (gated).

**10d. In a shop run, is a lone `will` ignored? (yes/no)**
- Yes: a function word alone is never a grocery line, even with Will in People.
- No: it becomes the line "will".
- **Default: yes.** Most likely a cut-off sentence; a line called "will" is junk.
- Rows: confirm E501 (nil). Master stays wrong write (RC4).

## 12. Smaller calls

**12a. Does `basil and tomatoes` go to the model? (yes/no)**
- Yes: "X and Y" food lists are not called yet; the model puts them on Groceries.
- No: an all-food "and" list with no Person in it is Groceries.
- **Default: yes, for now.** Velocity: no new rule, no wrong write; revisit if the hint ledger shows it often.
- Rows: confirm E498 (nil). Master passes.

**12b. Is "training partner" a relation word (`bench 80x8 with mark` links Mark)? (yes/no)**
- Yes: the set is logged and linked to Mark.
- No: not now; the phrase goes to the model.
- **Default: no.** Rare, and People has no partner field to write to.
- Rows: confirm E514 (nil). Master passes.

**12c. Does a month with no day date it on the 1st, and is a month 30 days in an interval? (yes/no)**
- Yes: `car service due march` is a task Mon 1 Mar 2027 with no time; `every 6 months` is 180 days; one month parser also serves People birthdays.
- No: month phrases stay with the model.
- **Default: yes, when the month parser lands.** It is already planned for People (E512), so this is no extra work; until then nil.
- Rows: I655 `nil` -> `task "Car service" Mon 1 Mar 2027, no time, alerts F [month dates, N1] · now: nil`; I659 `nil` -> `SetChoreInterval(Change the water filter, 180) [Upkeep, month dates] · now: nil`. Master passes both (gated).

**12d. Does `bins every thursday` keep the title "Bins every Thursday"? (yes/no)**
- Yes: keep the approved title until recurring tasks land, so the repeat is not lost.
- No: "Bins" or "Put the bins out" (the repeat words drop, as J766 does).
- **Default: yes.** The title is the only trace of the repeat today; Upkeep later binds it to the bins chore.
- Rows: confirm I660. Master stays wrong write (writes "Bins every", RC7).

## Summary

| call | question | default | rows changed | master after |
|---|---|---|---|---|
| 5a | grammar reads `in N`, `day after tomorrow` | yes | none (13 confirmed) | still fails (RELT) |
| 5b | plain relative time rings | yes | +`alerts T` on 6 rows | unchanged (N1) |
| 5c | `N days before X` to the model | yes | none (B347) | wrong write |
| 5d | `remind me in 20` in a cook | timer | none (D464) | wrong write |
| 6a | RPE `@N`, live workout only | yes | none (B303 to B306) | miss |
| 6b | drop with no reps logs last reps | no | B302 -> nil | pass |
| 6c | `add 2.5` logs a set | no | B310 -> nil | pass |
| 6d | `add X` is Groceries | yes | none (B334) | miss |
| 7 | M8: `12.40 lunch fri` to the model | yes, gated | H611 | pass (gated) |
| 9a | percent to page, else ask | yes | G579, G580 | pass (gated) |
| 9b | `abandoned`, `gave up on`, `dnf` set aside | yes | G589 | pass (gated) |
| 9c | bare number is the page of the book in front | yes | G561 | pass (gated) |
| 10a | `rang mum` is a call | yes | F519 | pass (gated) |
| 10b | `lunch with ravi` | ask | F531 | pass (gated) |
| 10c | gift task for a Person | yes | A070 | pass (gated) |
| 10d | lone `will` in a shop run ignored | yes | none (E501) | wrong write |
| 12a | `basil and tomatoes` to the model | yes | none (E498) | pass |
| 12b | training partner relation | no | none (E514) | pass |
| 12c | month on the 1st, month is 30 days | yes | I655, I659 | pass (gated) |
| 12d | keep "Bins every Thursday" | yes | none (I660) | wrong write |

## Net change if every default is taken

| status | now | after | change |
|---|---|---|---|
| pass | 595 | 597 | +2 (B302, B310) |
| wrong write | 104 | 104 | 0 |
| miss | 75 | 73 | -2 |
| **all** | **774** | **774** | |

Twelve expected values change (plus the six 5b `alerts` marks): two flip to pass (B302, B310), ten stay pass. Nine rows that pass today become gated (G561, G579, G580, G589 on Reading; F519, F531, A070 on People; I655, I659 on month dates), so gated goes from 247 to 256 (240 pass, 15 wrong write, 1 miss) and not gated from 527 to 518 (357 pass, 89 wrong write, 72 miss). H611 moves from the N1-only gate to Money. The `alerts` marks go from 105 to 111 (5b). No default adds a wrong write: every new expected value is nil, an ask, or a gated target whose "now" parse is what master already does.
