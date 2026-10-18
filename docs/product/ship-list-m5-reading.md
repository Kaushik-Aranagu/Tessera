# M5 Reading ship list (engine-first)

**Approved by Product, 2026-10-15 18:40, with every default in "Open questions" taken as written.** Drafted by Research lab. Comes after M4 in the priority order. Same rules as `../product/ship-list-lists.md` and `../product/ship-list-kitchen.md`: small end-to-end slices, velocity over perfection, engine first so Core can start now. **Engine** = logic and tests only; **Feature screen** = a self-contained screen in its own `Features/Reading/` folder that meets the UI bar (no cards, pills, capsules or stock lists). Source: the Reading part of `m5-money-reading.md`, its smallest version only. Owners: **Core** builds engine slices, **Builder B** builds screens.

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
| `read Dune`, `to read Dune`, `queue Dune` | `QueueBook` (state queued) | "Dune is in the queue." Superseded by amendment 1. |
| `read Dune by Frank Herbert` | `QueueBook` with author | "Dune is in the queue." Superseded by amendment 1. |
| `reading Dune`, `started Dune`, `start Dune` | `QueueBook` if new, then `StartReading` | "Reading Dune, p 0." Superseded by amendment 1. |
| `reading Dune 612 pages` | as above, with pages | "Reading Dune, p 0 of 612." Superseded by amendment 1. |
| `p 142`, `p142`, `page 142`, `pg 142` | `SetBookPage` on the last touched reading book | "Dune, p 142." (always names the book) |
| `p 142 of 612` | `SetBookPage`, and sets pages if unknown | "Dune, p 142 of 612." |
| `Dune p 142` | `SetBookPage` on the named book | "Dune, p 142." |
| `finished Dune` | `FinishBook`, no review | "Finished Dune. One line on it?" Superseded by amendment 1. |
| `finished Dune: slow start, great end` | `FinishBook` with review | "Finished Dune: slow start, great end." Superseded by amendment 1. |
| `finished` (no title) | `FinishBook` on the last touched reading book | "Finished Dune." Superseded by amendment 1. |
| `set Dune aside`, `dropped Dune`, `stop reading Dune` | `SetBookAside` | "Set Dune aside." Superseded by amendment 1. |

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

## Decisions (Product took every default)

1. **Does "reading Dune" take Now?** Default: no. A book starts suspended, so it shows in What's running and only becomes running (Now) on Resume. This keeps a weeks-long book from holding Now and from suspending a workout.
2. **When is the evening slot?** Default: from 19:00, only when nothing is running and no timed item is current. One time for every day. Superseded by amendment 5 (7 pm to 11 pm, house clock).
3. **Is the queue its own class state or a Lists list?** Default: book state (queued) inside `Book`, shown on the Reading shelf. Groceries-style built-in "To read" list on the Lists shelf is Later, to avoid two sources of truth.
4. **Do books follow the stale rules?** Default: they leave the Home ledger after 3 days like any process but are never put away at 7 days; the evening slot brings them back.
5. **Is set aside restorable?** Default: yes. "reading Dune" on a dropped or finished book starts it again at its saved page (a re-read starts at p 0 only if said: "rereading Dune").
6. **Reading app or a Lists sibling?** Default: its own small app, `Features/Reading/`, with the sibling rail later if Money joins it.
7. **Network lookup** (research question 1). Default: offline first, lookup off, typed title is the record.

## Amendments, Oct 17 9:45 pm PDT (hunt 19 and Product rulings)

Source: `kitchen-gap-hunt-19-money-reading-notes-lowpower-voiceover-oct17.md` and Product's rulings of Oct 17, 9:40 pm PDT. The text above stays as approved; where an amendment disagrees, the amendment wins. Build slice 1 from this list read with these rows.

| # | Item | Amended rule | Gap |
|---|---|---|---|
| 1 | Receipts and Tess lines | The thing comes first in every receipt, UNDO answer and op summary. "Dune, started." "Dune, p 0." "Dune, p 0 of 612." "Dune, in the queue." "Dune, finished. One line on it?" "Dune, finished: slow start, great end." "Dune, set aside." UNDO answers read "Dune, taken back." Op summaries read "Dune, p 120 to 142" and "Dune, finished: slow start, great end". The UNDO key reads "Undo <thing>". A test checks that every capture line begins with the thing. | G302 |
| 2 | Private book | A Book can be private. A private Book reads "Private book" wherever it is masked, and its review line shows on the book page only. `ObjectPrivacy.label(of:)` gets a Book case. Bare words never mask: a title alone does not make a book private. | G303 |
| 3 | House clock | Every clock reads "8:30 pm" through `HouseTime.clock`. Any line that shows the evening time reads "7 pm", never "19:00". The "p 142 of 612 · started 9 days ago" line uses US dates. | G306 |
| 4 | Low Power forms | Under the shared flag (Reduce Motion or Low Power) the page drum still turns under his finger but does not coast or tick on its own. The resume glint becomes a 150 ms highlight on the page number plus the same haptic (his own touch). The resume landing is a 150 ms crossfade. | G291, G289 |
| 5 | Tess-initiated slot | The Reading evening slot follows quiet hours (23:00 to 07:00): it runs 7 pm to 11 pm, then gives Now back. It never lands at night. No sound or haptic of its own. | G292 |
| 6 | Retry inbox and Claude calls | The retry inbox pauses in Low Power and resumes on power ok or his tap. Automatic Claude calls do not run in Low Power. A phrase he types himself is a call he asked for and still runs. | G293 |
| 7 | One UNDO slot | One app-wide UNDO slot: 4 s for a new thing (a queued or started book), 10 s for a change (`SetBookPage`, a review line), a flat 10 s under VoiceOver. Under VoiceOver the 2 s ghost row waits for a tap or an action before it commits. | G308 |
| 8 | Finish key | Finish is a named action only ("Finish <title>"), with no default double-tap completion, because a stray tap opens the review flow. Set aside stays a plain button. | G304 |
| 9 | Page drum without sight | The drum exposes a label, a value ("page 142 of 612") and an adjustable action. VoiceOver lands on a typed page field by default; focus moves there on open. | G305 |
| 10 | Spoken forms | Spoken labels use "page 142 of 612, started 9 days ago". "P 142" stays the drawn form only. | G307 |
| 11 | Shelf at large type | At accessibility sizes the shelf is one column: the page sits under the title. | G310 |
| 12 | Resume with VoiceOver | On resume, focus moves to the page value and "Dune, page 142" is announced once. | G311 |
