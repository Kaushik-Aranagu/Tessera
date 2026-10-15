# Reading fixtures

For: Core engine (M5 Reading slices 1 to 4, `TessGrammar+Reading.swift`), Research lab. Date: 2026-10-15.

These are 40 capture phrases, 10 resume-point cases and 8 finish-review lines for the M5 Reading ship list (`../../product/ship-list-m5-reading.md`, approved 2026-10-15 18:40). Grammar facts come from a static read of `origin/master` at `5258866` (`TessGrammar.swift`, `TessGrammar+Kitchen.swift`, `TessCapturing.swift`, `TessCaptureEngine.swift`, `TessTools.swift`, `NowPicker.swift`). Nothing was run. Every spoken transcript is a plausible guess, not a recording.

## How to read the tables

**Slice ids.** S1 Book class and queue, S2 Reading as a process, S3 Books in What's running and on Now, S4 Reading phrases, S5 Book page, S6 Resume a book, S7 Reading shelf. "S4 table" means the phrase is in the slice 4 capture table as written. "S4 rule" means one of the rules under that table. **Gap** means no slice covers it; the expected column is then a proposal, and the row is an open question.

**Line refs.** "G:" is `TessGrammar.swift`, "K:" is `TessGrammar+Kitchen.swift`, "T:" is `TessTools.swift`, all at `5258866`. `grammar-collisions.md` ("GC") was written against `fcad46c`, so its line numbers are stale. Master has since gained the question guard (G:62, G:94-99), the process rule (G:66, G:102-131), the reschedule rule (G:83-89) and whole-word lift matching with a 3-letter floor (G:327-331). GC row 1 ("p 42 of 80" as Dip) no longer happens.

**Clock.** Thu 15 Oct 2026, 18:00 Europe/London, the same as `../grammar-collisions.md`.

**Shelf fixture.** Dune (612 pages), Dune Messiah (queued), Project Hail Mary (476 pages, queued), It (1138 pages, queued), Atomic Habits (no page count, queued), 1984 (328 pages, queued), The Sun Also Rises (queued), Catch-22 (453 pages, dropped at p 88), Educated (352 pages, finished at p 352). Open tasks: "Finish the report", "Call mum". The routine Push Day, and the recipes from GC.

**Contexts.**
- **I**: idle. Nothing running, no book reading; Dune is queued.
- **R**: Dune reading (suspended, p 120 of 612, last touched). Nothing running.
- **R2**: Dune reading (p 120) and Project Hail Mary reading (p 88 of 476, touched after Dune). Nothing running.
- **RN**: Dune resumed, so it is the running process in Now.
- **W**: live workout, Bench Press in focus, last set 80 x 8. Dune reading, suspended.
- **C**: cooking Weeknight dal. Dune reading, suspended.

`TessCaptureEngine.capture` fills `context.process` from `ProcessTable.running()` only (TessCaptureEngine.swift:23-25), so a suspended book is never "in front". Only RN puts a book there.

**Spoken column.** Raw transcript, then the text after `TessSpokenNormalizer` as specified in `spoken-normaliser.md`. "Typed only" means nobody says it.

## Proposed placement of the reading rule

Slice 4 says "after notes and pasted recipes and before lifts". On master that span holds the question guard, the process rule, relative sets and comma sets. The rows below assume this order:

1. note (G:55)
2. pasted recipe (G:58)
3. question guard (G:62)
4. process rule (G:66): cook steps, workout rest, shop items
5. relative set (G:70)
6. **reading (new)**
7. comma sets (G:73), named lift (G:76), kitchen (G:80), reschedule (G:83), task (G:90)

Reading after the process rule keeps "finished" as a cook step while cooking. Reading after relative sets keeps a bare "42" a set in a live workout. Reading before comma sets keeps a review with a comma in it out of `parseCommaSets`.

## Phrase rows

### Pages

| # | Ctx | Typed | Spoken (raw to normalised) | Expected intent and fields | Feedback line | Collision with master and how it resolves | Slice |
|---|---|---|---|---|---|---|---|
| 1 | R | `p 142` | "Page one forty-two." to `page 142` | SetBookPage(book: Dune, page: 142) | "Dune, p 142." | **`p N` vs named lift.** Today the lift rule reads "p" as the only word and 142 as the weight, then fails (no reps, and "p" is under the 3-letter floor, G:331), so it goes to the model. Resolves: the reading rule runs before lifts and claims `p N` | S4 table, S2 |
| 2 | R | `p142` (also `pg 142`) | Typed only | SetBookPage(Dune, 142) | "Dune, p 142." | `p142` is one token with no number, so no lift. `pg` is 2 letters and fails the floor. Both go to the model today. Resolves: the reading regex accepts `p`, `pg`, `page`, with or without a space | S4 table |
| 3 | R | `page 142 of dune` | "Page 142 of Dune." to `page 142 of Dune` | SetBookPage(Dune, 142) | "Dune, p 142." | "of" is skipped by lifts (G:285), leaving the words "page dune", which match no exercise, so the model gets it. Rule: after `p N of`, a number is the page count and words are a title | S4 table (derived from `Dune p 142` and `p 142 of 612`) |
| 4 | R | `p 142 of 612` | "Page one forty-two of six twelve." to `page 142 of 6 12` | SetBookPage(Dune, 142). Pages is already 612, so it stays | "Dune, p 142 of 612." | Master: model. **Normaliser trap:** its two-part number rule covers 100 to 300 only, so "six twelve" becomes `6 12`, which reads as 6 pages and a stray 12. The normaliser needs "N of M" after `page` as a protected number span | S4 table |
| 5 | R | `p 50 of 1984` | "Page fifty of nineteen eighty-four." to `page 50 of 1984` (if the normaliser joins years) | **Ambiguous.** Top: StartReading(1984) then SetBookPage(1984, 50). Alternative: SetBookPage(Dune, 50) with pages 1984. Waits for a tap, no 2 s commit | "1984, p 50. Or Dune, p 50 of 1984?" | Master: model. A number after `of` is normally pages. Resolves: an exact book title beats the page-count reading, and Dune already has a page count (612) that disagrees. The normaliser has no year rule, so "nineteen eighty-four" may arrive as `19 84` | S4 table, S1 (`book(named:)`), GC rule 9 |
| 6 | R2 | `p 142` | "Page 142." | SetBookPage(Project Hail Mary, 142), the last touched book | "Project Hail Mary, p 142." | Same as row 1. The line always names the book, so a wrong guess is visible before the 2 s commit | S4 rule (two books), S2 |
| 7 | I | `p 142` | "Page 142." | No write | "No book open. Try: reading Dune." | Master: model, which may guess a set or a task. Resolves: the reading rule claims `p N` even with nothing reading, so the model never guesses | S4 rule |
| 8 | R | `p 700` | "Page seven hundred." to `page 700` | SetBookPage(Dune, 700), kept as said. State stays reading | "Dune, p 700. Last page. Finished?" | No collision. Never finishes on its own | S4 rule |
| 9 | W | `p 142` | "Page 142." to `page 142` | SetBookPage(Dune, 142). The workout is not touched | "Dune, p 142." | **`p N` vs relative set** (G:163-186): no match, because "p 142" is not a number, `same` or `W x R`. The lift rule fails too (row 1). Resolves: reading after relative sets, and `p N` always means a book, even with a workout in front (GC rule 4) | S4 ("p 142 during a live workout never becomes a set") |
| 10 | W | `142` | "142." | No write. Over 100, so not a reps-only set (G:168) | "Didn't catch that. Dune, p 142?" | **Bare N vs relative set.** A bare number belongs to the workout in front. The reading rule must not claim it while a workout runs, even when the set rule rejects it. The guess offers the book as a question | S4 (guard), GC rule 4 |
| 11 | RN | `142` | "142." | SetBookPage(Dune, 142) | "Dune, p 142." | No entry, so no relative set. Master: model. **Gap:** the S4 table has no bare number. GC rule 4 says a bare N goes to the book in front | Gap (GC rule 4) |
| 12 | C | `p 142` | "Page 142." | SetBookPage(Dune, 142). The cook is not touched | "Dune, p 142." | The process rule takes only `next`, `done`, `finished` while cooking (G:109-112), so `p 142` falls through to reading. No collision | S4 |

### Queue and start

| # | Ctx | Typed | Spoken (raw to normalised) | Expected intent and fields | Feedback line | Collision with master and how it resolves | Slice |
|---|---|---|---|---|---|---|---|
| 13 | I | `read dune` | "Read Dune." to `Read Dune` | QueueBook("Dune") returns the existing queued Dune. No second copy | "Dune is in the queue." | Master: no day cue, so the model. No collision | S4 table, S1 (dedupe) |
| 14 | I | `read chapter four` | "Read chapter four." | **Ambiguous.** Top: task "Read chapter four" (no date). Alternative: QueueBook("Chapter four"). Waits for a tap | "Read chapter four: a task, or a book?" | **`read X` vs task.** No book matches. The S4 table would queue a book named "Chapter four"; GC rule 5 says a verb never creates an object from a title that resolves to nothing. See open question 1 | S4 table vs GC rule 5 |
| 15 | I | `read dune thu` | "Read Dune Thursday." to `Read Dune Thursday` | Task "Read Dune", today 19:00 (the "thu" said on a Thursday rule, G:437-443) | "Read Dune, today 7 pm." | **`read X` vs the task rule** (G:352-371). A day cue wins: the reading rule bails when `TessDates.extract` finds a day or time outside a known title | S4 rule ("read Dune thu" stays a task) |
| 16 | I | `read the sun also rises` | "Read The Sun Also Rises." | QueueBook returns the existing The Sun Also Rises | "The Sun Also Rises is in the queue." | **Weekday inside a title.** Today "sun" is a weekday cue (G:395, G:414), so the task rule makes "Read the also rises", Sun 18 Oct 09:00. Resolves: the reading rule matches the shelf with `book(named:)` before it looks for day cues, and a word inside a matched title is never a cue. Same for "Saturday" (McEwan) or "Tomorrow, and Tomorrow, and Tomorrow" | S4 rule, S1, GC rule 7 |
| 17 | I | `reading dune` | "Reading Dune." | StartReading(Dune): state reading, process opens suspended, resume point p 0, next step "Dune, p 0" | "Reading Dune, p 0." | Master: model. No collision. It does not take Now (Decision 1) | S4 table, S2 |
| 18 | I | `reading piranesi 272 pages` | "Reading Piranesi, two seventy-two pages." to `Reading Piranesi 272 pages` | QueueBook("Piranesi", pages: 272), then StartReading | "Reading Piranesi, p 0 of 272." | The lift rule takes 272 as the weight, finds no reps and fails. Model today. The normaliser keeps "272 pages" (no "for", so no x) | S4 table, S1 |
| 19 | I | `started project hail mary` | "Started Project Hail Mary." | StartReading(Project Hail Mary), the existing queued book | "Reading Project Hail Mary, p 0." | **`start X` vs other domains** (GC rows 5 to 7). No start grammar on master, so the model. Resolves here because the title is an exact book | S4 table, S1, S2 |
| 20 | I | `start push day` | "Start push day." | Not a book. Push Day is a routine, so the model starts the workout (no start-workout grammar on master) | (the model's line) | **`start X` from the S4 table** would queue and start a book called "Push day". Resolves by GC rule 5: an exact name of another class (routine, recipe, open task) wins, and bare `start X` never creates a new book | S4 table vs GC rule 5 |
| 21 | I | `reading 1984` | "Reading nineteen eighty-four." to `Reading 1984` (needs a year rule) | StartReading(1984). The number is the title, not a page | "Reading 1984, p 0 of 328." | The lift rule takes 1984 as the weight, finds no reps, fails. Resolves: `reading N` with no `p` is a title only when N is an exact book title; else it falls through | S4 table, S1 |
| 22 | I | `reading it` | "Reading It." | StartReading(It). Exact title, and no book is reading, so "it" has nothing to point at | "Reading It, p 0 of 1138." | Master: model. "it" is a title only on an exact match. With a book reading, see row 38 | S4 table, S1 |
| 23 | I | `reading 30 min` | "Reading thirty minutes." to `Reading 30 min` | No write. Session timing is Later | "Didn't catch that. Reading Dune?" | **Inside S4 itself:** `reading X` would make a book called "30 min". The lift rule takes 30 as the weight, fails on no reps, and the model gets it today. Resolves: a title that is only a number with a time unit (`min`, `mins`, `minutes`, `h`, `hours`) is not a title | S4 (guard). Session timing: Later |
| 24 | I | `reading timer 30` | "Reading timer thirty." | Kitchen timer "Reading", 30 min (K:36, K:74-92) | "Reading timer, 30 min." | Guard. The reading rule must not claim a phrase with `timer` in it, so the kitchen timer keeps it | S4 ("every kitchen phrase still parses the same") |
| 25 | R | `reading dune messiah` | "Reading Dune Messiah." | StartReading(Dune Messiah). Dune stays reading, so there are now 2 books | "Reading Dune Messiah, p 0." | Series: "dune" is in both titles. `book(named:)` tries an exact title first, so Dune Messiah wins and "Dune" never steals it | S1 (`book(named:)`), S4 |
| 26 | I | `reading the expanse 1` | "Reading The Expanse one." to `Reading The Expanse 1` | QueueBook("The Expanse 1"), then StartReading. The title is kept as said | "Reading The Expanse 1, p 0." | No series field and no lookup (Later), so the series number is part of the title. A trailing number is not pages unless `pages` follows | S4 table. Series: gap |
| 27 | I | `reading catch-22` | "Reading Catch twenty-two." to `Reading Catch 22` | StartReading(Catch-22) at its saved p 88 (Decision 5) | "Reading Catch-22, p 88." | Spoken has no hyphen. `book(named:)` splits on non-letters, so "catch 22" matches "Catch-22". The lift rule reads "catch" with weight 22 and no reps, and fails | S4, S1, Decision 5 |
| 28 | I | `reading educated` | "Reading Educated." | StartReading(Educated) at its saved page, p 352, which is the last page (Decision 5) | "Reading Educated, p 352." | No collision with master. The result is odd: a re-read starts at the end unless he says "rereading". See open question 5 | S4, Decision 5 |

### Percent, location and audiobook forms

| # | Ctx | Typed | Spoken (raw to normalised) | Expected intent and fields | Feedback line | Collision with master and how it resolves | Slice |
|---|---|---|---|---|---|---|---|
| 29 | R | `dune 45%` | "Dune forty-five percent." to `Dune 45 percent` | Proposal: SetBookPage(Dune, 275), from 45% of 612 rounded down | "Dune, 45%, p 275." | "45%" is not a number, so the lift rule has no numbers. Model today. The normaliser has no "percent" rule, so the grammar must take `%` and `percent` | **Gap** (Book has page only) |
| 30 | I | `atomic habits 30% on kindle` | "Atomic Habits, thirty percent on Kindle." | Proposal: no page write. Atomic Habits has no page count, so Tess asks | "Atomic Habits has no page count. How many pages?" | Model today. A future Habits grammar (`../habits.md`) could read "habits". Resolves: an exact book title wins | **Gap** |
| 31 | R | `dune loc 2304` | "Dune location two three oh four." to `Dune location 2304` | Proposal: no write. A Kindle location does not map to a page without the book's location count | "Didn't catch that. Which page of Dune?" | The lift rule takes 2304 as the weight with no reps, fails. Model today | **Gap** |
| 32 | R2 | `project hail mary 3h 20m of 16h 10m` | "Project Hail Mary, three hours twenty of sixteen hours ten." | Proposal: SetBookPage(Project Hail Mary, 98), from 200 / 970 of 476 pages | "Project Hail Mary, 3h 20m, about p 98." | Model today. `m` and `h` are timer units only when "timer" is in the phrase (K:75), so no timer. Audiobook time is not a page | **Gap** |

### Finish and set aside

| # | Ctx | Typed | Spoken (raw to normalised) | Expected intent and fields | Feedback line | Collision with master and how it resolves | Slice |
|---|---|---|---|---|---|---|---|
| 33 | R | `finished dune` | "Finished Dune." | FinishBook(Dune): state finished, finishedAt now, process ends with reason done | "Finished Dune. One line on it?" | **`finished X` vs completeTask.** Master has no completion grammar, so the model gets it and may call `completeTask` with task "dune" (T:121-127), which fails with no such task. Resolves: the reading rule binds `finished X` when X resolves to a book, before the model runs | S4 table, S2 |
| 34 | R | `finished Dune: slow start, great end` | "Finished Dune, colon, slow start, great end." to `Finished Dune: slow start, great end` (normaliser open: spoken colon) | FinishBook(Dune, review: "slow start, great end") | "Finished Dune: slow start, great end." | The comma reaches `parseCommaSets` (G:73) if reading runs after it; both parts fail as lifts, so it is harmless. Reading before comma sets avoids it. GC row 9 (future `<list>:` rule) binds only to an exact list name | S4 table, S2 |
| 35 | R | `finished` | "Finished." | FinishBook(Dune), the last touched reading book | "Finished Dune." | Master: model, which may call `completeTask` on a guess. Resolves: bare `finished` binds to a book only when a book is reading and no other process is in front | S4 table, S4 rule |
| 36 | W | `finished` | "Finished." | Not a book. Finish the workout (the model today; GC rule 4 for the grammar) | (the workout's line) | **Bare `finished` vs the running workout.** The workout branch of the process rule only takes rest and timer (G:113-119), so `finished` falls through, and the S4 table would finish Dune. Resolves: the reading rule checks `context.process` and yields when it is not a book | S4 table vs GC rule 4 |
| 37 | R | `finished the report` | "Finished the report." | Not a book. Falls through unchanged; the model calls `completeTask` on "Finish the report" | (the model's line) | **`finished X` vs completeTask.** "the report" matches no book, so the reading rule passes. A book whose title has every word ("The Report") would win, so the match must be exact or every word, never a single shared word like "the" | S4 rule ("otherwise the phrase goes on to the task grammar unchanged") |
| 38 | R | `finished it` | "Finished it." | **Ambiguous.** Top: FinishBook(Dune), "it" as the book being read. Alternative: FinishBook(It), the queued book. Waits for a tap | "Finished Dune. Or It?" | Master: model, which may call `completeTask` "it". Resolves: "it" as a pronoun means the last touched reading book. The exact title "It" is offered as the alternative because It is queued, not reading | S4 rule, S1, GC rule 9 |
| 39 | R | `abandoned dune` | "Abandoned Dune." | Proposal: SetBookAside(Dune): state dropped, process ends with reason closed, page kept | "Set Dune aside." | Master: model. **Gap:** the S4 table lists `set Dune aside`, `dropped Dune`, `stop reading Dune` only. Add `abandoned X`, `gave up on X`, `dnf X` as aliases. "dropped" must not touch the drop-set regex (G:171), which needs a number | S4 table (extend), S2 |
| 40 | R | `finished dune?` | "Have I finished Dune?" to `Have I finished Dune` | No write. The question path answers from the book | (the answer, for example "Not yet. Dune, p 120 of 612.") | **Question guard** (G:98): a trailing `?` is a question on master, so the reading rule never sees it. The spoken form loses its `?`, and "have" is not a lead word (G:97), so it would reach the reading rule. Add "have i" to the lead words | S4 (guard). Question lead words: gap |

Count: 40 rows. Slice cover: 35 rows cite an S4 table phrase or rule; 5 are gaps (rows 11 and 29 to 32); row 26 is partly a gap (series) and row 39 extends the S4 table. Ambiguous rows that wait for a tap: 5, 14, 38.

## Collisions with master's grammar

| Existing rule | Phrase that meets it | Today on master | Resolution |
|---|---|---|---|
| Named lift (G:235-253, G:327-331) | `p 142`, `page 142 of dune`, `reading 1984` | No lift: "p" fails the 3-letter floor; one number gives no reps. The model gets them | Reading before lifts. No code change to lifts. GC row 1 is already fixed |
| Relative set (G:163-186) | `p 142` and `142` in a live workout | `p 142` never matches. A bare N from 1 to 100 is a set | Reading after relative sets; `p N` is always a book, bare N never is while a workout runs (rows 9, 10) |
| Process rule, cook (G:109-112) | `finished` while cooking | Cook step | Already earlier in order. Guard row needed |
| Process rule, workout (G:113-119) | `finished` in a workout | Falls through to the model | The reading rule yields when `context.process` is set and is not a book (row 36) |
| completeTask, a model tool (T:121-127) | `finished dune`, `finished`, `finished it`, `finished the report` | All go to the model, which may mark a task done | Reading binds only to a resolved book or, for bare `finished`, a reading book with nothing in front. Anything else falls through unchanged (rows 33, 35, 37, 38) |
| Task day cues (G:352-371, `TessDates` G:393-484) | `read dune thu`, `read the sun also rises` | Both become tasks | A day cue outside a known title keeps it a task. A weekday word inside a matched title is not a cue (rows 15, 16) |
| Kitchen timer (K:36, K:74-92) | `reading timer 30` | Timer | Reading never claims a phrase containing `timer` (row 24) |
| Question guard (G:62, G:94-99) | `finished dune?` | Question, no write | Keep. Add "have i" for the spoken form (row 40) |
| Comma sets (G:73) | `finished Dune: slow start, great end` | Fails as sets, harmless | Reading before comma sets |
| Reschedule shape (G:133) | none found | n/a | "put Dune aside" has no `to`, so the shape does not match |

## Resume-point cases

Setup unless stated: R, Dune at p 142 of 612. "Now" follows `NowPicker` (running process, then timed items, then from 19:00 the most recently touched suspended book, then untimed tasks). "Ledger" is the What's running rows on Home.

| # | Case | Steps | Expected state | What Now shows | Ledger and What's running | Slice |
|---|---|---|---|---|---|---|
| R1 | Last page | `p 612` at 20:00 | Page 612, state reading. Not finished | "Dune", next step "Dune, p 612" | Title, then "p 612 of 612" | S2, S3, S4 rule. Line: "Dune, p 612. Last page. Finished?" (open question 4: at the count, or only past it) |
| R2 | Past the page count | `p 700` | Page 700 kept as said, still reading | "Dune, p 700" | "p 700 of 612" reads wrong. Proposal: show "p 700" alone once the page passes the count | S4 rule, S6 |
| R3 | Restarted after 4 days | Last touched Sun 11 Oct. Opened Thu 15 Oct 19:05, nothing running, no timed item | Still reading, page 142. Not put away, not wrapped up | Dune, "Dune, p 142". Tap Resume: `ResumeProcess`, running, the book page opens with the page drum at 142 and one glint (a haptic under Reduce Motion) | Gone from the Home ledger after 3 days; still in the full What's running list | S3, S6 |
| R4 | Same, before the evening slot | Same book, opened Thu 18:59 with an untimed task today | No change | The untimed task, not the book | Not on the Home ledger | S3 (the 18:59 test) |
| R5 | Two books at once | Dune touched Tue, Project Hail Mary touched Wed. `p 142` on Thu 19:10 | PHM page 142 (last touched). Dune unchanged | PHM, "Project Hail Mary, p 142". After `dune p 150`, Dune becomes last touched and takes Now | Both rows, last touched first | S2, S3, S4 rule |
| R6 | Page goes backwards | `p 120` after p 142 | Page 120, kept as said. No guard in S2 | "Dune, p 120" | "p 120 of 612" | S2. The op summary template "Read Dune, p 142 to 120" reads as if he read backwards. Proposal: "Dune, back to p 120" when the new page is lower (open question 3) |
| R7 | Undo a page | `p 142`, then Undo | Page back to 120 | Proposal: the book's last-touched time also goes back, so Now and the two-book choice are as before | "p 120 of 612" | S2 ("every action undoes cleanly"). Open question 9 |
| R8 | A workout is running at 19:00 | Workout started 18:30. Dune suspended | No change to the book | The workout. The book only in What's running | Workout first, then Dune | S3 (the 19:00 test with a workout) |
| R9 | A timed task is current at 19:00 | "Call mum" at 19:00, 30 min | No change | "Call mum" until 19:30, then Dune | Dune on the ledger if touched in the last 3 days | S3 (the timed-task test) |
| R10 | Resumed, then a workout starts | Dune running in Now at p 142. He starts Push Day | Dune suspended through the existing rule, resume point 142 saved by `SaveContext` | The workout. After it ends, Dune returns only through the evening slot, not as running | Dune suspended, "p 142 of 612" | S2, S3, S6 |

Finishing removes the book from What's running and Now (the process ends with reason done). Undoing `FinishBook` brings the process back suspended at its saved page.

## Finish-review lines

Rules from `../tess-voice.md`: past tense first, one line under 12 words, no "!", no praise, no grading, offers as "Want...?", silence when nothing changed. The ship list adds: no counts of books, no stats, no streaks.

| # | Moment | Line | Words |
|---|---|---|---|
| F1 | Finished, no review | Finished Dune. One line on it? | 6 |
| F2 | Finished with a review | Finished Dune: slow start, great end. | 6 |
| F3 | Review added later on the book page | Saved your line on Dune. | 5 |
| F4 | Bare `finished` with two books reading | Finished Project Hail Mary. Dune is still open. | 8 |
| F5 | Finished, and the queue has a next book | Finished Dune. Want Dune Messiah next? | 6 |
| F6 | Finished a re-read | Finished Educated, second time through. | 5 |
| F7 | Finish undone | Dune is back to reading, p 612. | 7 |
| F8 | Finished the book called It | Finished It. One line on the book? | 7 |

Silent cases: when he leaves the review line empty, Tess says nothing more. No line ever says how long the book took, how many books this year, or whether the review is good.

Self-check: every line names the book, none grades it, and none passes judgement on the review. F2 repeats his own words, which can contain a banned word ("great"); the automatic banned-word check must skip text in quotes from the user (open question 10). F8 avoids "One line on it?" because "It" and "it" would clash.

## Open questions

1. **Does a verb create a book?** The S4 table makes `read X`, `start X` and `started X` queue a new book when none matches. GC rule 5 says a verb never creates an object from a title that resolves to nothing. Suggestion: `read`, `reading`, `queue` and `to read` may create; bare `start` and `started` bind only to an existing book (rows 14, 20).
2. **Percent, location and audiobook time.** Book has only a page. Should `45%` convert to a page when the count is known and ask for pages when it is not (rows 29, 30)? Kindle locations and audiobook time (rows 31, 32) need a field or stay with the model. Suggestion: convert percent now, leave location and time for Later.
3. **Pages going backwards.** Keep the page as said (R6)? And should the op summary read "Dune, back to p 120" instead of "Read Dune, p 142 to 120"?
4. **Last page at the count.** The S4 rule says "past the known page count". Should p 612 of 612 also ask "Last page. Finished?" (R1)? Suggestion: yes, at or past.
5. **Re-reading a finished book.** Decision 5 restarts at the saved page, which for a finished book is the last page (row 28). Should a finished book restart at p 0 and a dropped one at its page?
6. **"it" as a pronoun.** Row 38 reads "finished it" as the reading book, with the title "It" as the alternative. Is that the right default?
7. **Bare numbers with a book in front.** GC rule 4 sends a bare N to a resumed book (row 11). The S4 table does not list it. Add it, or keep `p` required?
8. **A page on a queued book.** Should `1984 p 50` start a queued book (row 5)? Suggestion: yes, StartReading then SetBookPage, as one undo.
9. **Undo and last touched.** After an undone `SetBookPage`, does the book's last-touched time go back too (R7)? It decides which book `p 142` and Now pick.
10. **Banned words in echoed reviews.** The tone check bans "great"; F2 echoes his review. Exclude quoted user text from the check.
11. **Normaliser gaps.** "six twelve" becomes `6 12` (row 4); years like "nineteen eighty-four" have no rule (rows 5, 21); "percent" and a spoken "colon" have no rule (rows 29, 34). These need rules in `TessSpokenNormalizer` before the spoken rows can pass.
12. **Series.** No series field (rows 25, 26). Keep the series number in the title until lookup lands?
13. **Set-aside words.** Add `abandoned`, `gave up on`, `dnf` to the S4 table (row 39)?
14. **Titles with day words.** Row 16 needs the reading rule to match shelf titles before `TessDates` runs. Should the GC rule 7 stop list also include every book title on the shelf, so `read the sun also rises sat` is a task about that book?
15. **Question lead words.** Add "have i" so the spoken "Have I finished Dune" stays a question (row 40)?
