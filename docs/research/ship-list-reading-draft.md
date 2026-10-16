# Reading ship list: first slice for M5 (engine-first), DRAFT for Product

**DRAFT for Product to review.** Research lab, 2026-10-15. Not approved; nothing here is a decision until Product signs it. Same rules as `../product/ship-list-lists.md` and `../product/ship-list-kitchen.md`: small end-to-end slices, velocity over perfection, engine first so Core can start now. **Engine** = logic and tests only; **Feature screen** = a self-contained screen in its own `Features/Reading/` folder that meets the UI bar (no cards, pills, capsules or stock lists). Source: the Reading part of `m5-money-reading.md`, its smallest version only. Owners: **Core** builds engine slices, **Builder B** builds screens.

**The idea in one line.** A book is a process: you start it, the page you are on is its resume point, and it lives in What's running until you finish it or set it aside. It reuses `Process`, `StartProcess` / `SaveContext` / `EndProcess`, `ProcessTable`, `NowPicker` and the ghost row as they are; the only new class is `Book`.

**Progressive disclosure rule.** A book opens as its title and the page you are on. Author, page count, review line and the queue are one gesture away. No stats, no counts of books, no goals, no streaks.

## Slices

| # | Slice | Done when | Type | Owner |
|---|---|---|---|---|
| 1 | **Book class and queue** | `SystemCatalog.Key.book`: title, author (optional), pages (optional), isbn (optional, stored only), state (queued, reading, finished, dropped), page (resume page, default 0), review (one line), finishedAt. `QueueBook` and `EditBook` (title, author, pages) and `DeleteObject`, all undoable through the op log. `Bookshelf` (in `TesseraCore/Reading/`, shaped like `ListContents`) returns reading books by last touched, queued books by added, finished books newest first. `book(named:)` matches exact title, then every word contained (the `recipe(named:)` rule). Queuing a title that exists returns the existing book, never a second copy | Engine | Core |
| 2 | **Reading as a process** | `StartReading(book)` sets state reading and opens a Process with ownerApp "Reading", subject the book, resume point `ResumePoint(index: page)`, next step "Dune, p 142". It opens **suspended**, so it sits in What's running and never takes Now from a workout or task (open question 1). Resume makes it running through the existing `ResumeProcess`. `SetBookPage(book, page)` saves the page through `SaveContext` without changing state, and its op summary reads "Read Dune, p 120 to 142". `FinishBook(book, review?)` sets finished, finishedAt and review, and ends the process with reason done ("Finished Dune: slow start, great end"). `SetBookAside(book)` sets dropped and ends with reason closed ("Set Dune aside"). Every action undoes cleanly, including the process | Engine | Core |
| 3 | **Books in What's running and on Now** | `ProcessTable.tidy` never puts a book away at 7 days and never wraps it up: a book idle 3 days leaves the Home ledger for the full list, as now, and stays reading. `NowPicker` gains one rule after the timed items: from 19:00 (open question 2), if nothing is running and no timed item is current, Now is the most recently touched suspended book, with next step "Dune, p 142". A test at 18:59 and 19:00 with a workout running, a timed task, and neither shows the book only in the last case | Engine | Core |
| 4 | **Reading phrases** | `TessGrammar+Reading.swift`, a `.reading` parse case, checked after notes and pasted recipes and before lifts. All phrases in the table below map as written, with their feedback line. "p 142" during a live workout never becomes a set, and every kitchen and task phrase in `../product/kitchen-phrases.md` and the existing grammar tests still parses the same | Engine | Core |
| 5 | **Book page** | Object page for one book, see design steer | Feature screen `Features/Reading/` | Builder B |
| 6 | **Resume a book** | The ledger row and Now slot for a book, and the landing on resume, see design steer | Feature screen `Features/Reading/` | Builder B |
| 7 | **Reading shelf** | The Reading app front page: reading, then the queue, then finished, see design steer | Feature screen `Features/Reading/` | Builder B |

Build order: 1 → 2 → 4 → 3; screen 5 after 2, 6 after 3, 7 after 1.

## Capture phrases (slice 4)

| Phrase | Maps to | Feedback line |
|---|---|---|
| `read Dune`, `to read Dune`, `queue Dune` | `QueueBook` (state queued) | "Dune is in the queue." |
| `read Dune by Frank Herbert` | `QueueBook` with author | "Dune is in the queue." |
| `reading Dune`, `started Dune`, `start Dune` | `QueueBook` if new, then `StartReading` | "Reading Dune, p 0." |
| `reading Dune 612 pages` | as above, with pages | "Reading Dune, p 0 of 612." |
| `p 142`, `p142`, `page 142`, `pg 142` | `SetBookPage` on the last touched reading book | "Dune, p 142." (always names the book) |
| `p 142 of 612` | `SetBookPage`, and sets pages if unknown | "Dune, p 142 of 612." |
| `Dune p 142` | `SetBookPage` on the named book | "Dune, p 142." |
| `finished Dune` | `FinishBook`, no review | "Finished Dune. One line on it?" |
| `finished Dune: slow start, great end` | `FinishBook` with review | "Finished Dune: slow start, great end." |
| `finished` (no title) | `FinishBook` on the last touched reading book | "Finished Dune." |
| `set Dune aside`, `dropped Dune`, `stop reading Dune` | `SetBookAside` | "Set Dune aside." |

Rules:
- Phrases are ghost rows like everything else: pending, commit after 2 s or on tap, undo.
- "p 142" with no book reading: "No book open. Try: reading Dune."
- With two books reading, "p 142" goes to the last touched one, and the feedback line names it (research pitfall 2).
- A page past the known page count is kept as said; the feedback line says "Last page. Finished?" It never finishes a book on its own.
- "read Dune thu" (a day cue) stays a task, as the task grammar does today. Linking the task to the book is Later.
- "finished" only means a book when a book is reading or the title matches a book; otherwise the phrase goes on to the task grammar unchanged.

## Design steers (one per screen)

Shared: light ground, the house paper and washes; Design picks the Reading lean in its build sheet. Vermilion only for a running book, cobalt only for Tess. No covers in v1 (lookup is off), so type carries the page.

**5. Book page.** The hero is the title. One context line in Body: "p 142 of 612 · started 9 days ago" (or "p 142" when pages are unknown). The page number is a **page drum**, the reps drum's sibling: turn it to set the page, and it writes `SetBookPage` on release. Author, pages and the review line sit one level deeper under the title, as words that edit in place, never a form. **Finish** is a hold key; on release one faint line opens for the review ("One line on it?") and saves as a ghost row. **Set aside** is a single word under it, calm copy, no red.

**6. Resume a book.** On the ledger and on Now a book reads like any process: the title in the big tier, "p 142 of 612" in the second, state in the seam. Tap to resume zooms straight to the book page with the page drum at eye level and one glint sweep across it (a haptic under Reduce Motion), so the loud cue is "where I stopped". Leaving the page suspends it through the existing rules.

**7. Reading shelf.** Not a grid of covers: titles as a typographic column. Books being read come first at the largest size with their page in Label tier ("P 142"); the queue follows smaller, oldest first; finished books sit last, dimmer, newest first, with their review line on tap. Never a count anywhere ("47 to read" never appears). New book is the ghost row ("read Dune"). Empty state is one cobalt line from Tess: "Tell me what you're reading."

## Depends on

- From master: `Process` and its actions, `ProcessTable` (ledger and `tidy`), `NowPicker`, the ghost row and `TessCaptureEngine`, the op log and undo, `DeleteObject`.
- Nothing from Lists or M3 is required. Lists slice 7 (Pick one) is Later for "what to read next".
- M4 slice 5 (Day log) is not on master. The op summaries from slice 2 ("Read Dune, p 120 to 142", "Finished Dune: slow start, great end") are written now so the Day log can show them when it lands.

## Later

Beyond the smallest version, not in this list:
- Open Library lookup by title or ISBN, and covers from the Covers API (opt in and cached; waits on Kaushik's yes, research question 1).
- Barcode scan of the ISBN with VisionKit `DataScannerViewController`.
- Queued books older than 30 days fading to Later (research pitfall 1). Until then the shelf simply never shows a count.
- The Day log line, once M4 slice 5 lands.
- Pick one from the queue (Lists slice 7), a reading Live Activity, widgets, session timing, stats, yearly goals, mood tags, and linking a dated task to a book.

## Open questions for Product (each with a default)

1. **Does "reading Dune" take Now?** Default: no. A book starts suspended, so it shows in What's running and only becomes running (Now) on Resume. This keeps a weeks-long book from holding Now and from suspending a workout.
2. **When is the evening slot?** Default: from 19:00, only when nothing is running and no timed item is current. One time for every day.
3. **Is the queue its own class state or a Lists list?** Default: book state (queued) inside `Book`, shown on the Reading shelf. Groceries-style built-in "To read" list on the Lists shelf is Later, to avoid two sources of truth.
4. **Do books follow the stale rules?** Default: they leave the Home ledger after 3 days like any process but are never put away at 7 days; the evening slot brings them back.
5. **Is set aside restorable?** Default: yes. "reading Dune" on a dropped or finished book starts it again at its saved page (a re-read starts at p 0 only if said: "rereading Dune").
6. **Reading app or a Lists sibling?** Default: its own small app, `Features/Reading/`, with the sibling rail later if Money joins it.
7. **Network lookup** (research question 1). Default: offline first, lookup off, typed title is the record.
