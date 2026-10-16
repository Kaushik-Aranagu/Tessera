# QA review 356: AI-7 Tess's memory store (Core)

*QA, Oct 16, about 2:40 AM Pacific. PR #356, `core/tess-memory`, head `e098e7e`, rebased on master (with #344 and
#348). Static review. Trial merge: clean, 7 files (+893 / -2). Checked against Design 49 (`tess-knows.md`), the
data-safety rules, and Research's four findings from 117.*

## Verdict: FIX FIRST (Research F1 and F2 aren't met yet; one screen gap)

### F1. A forgotten noticed line comes back (Research F1)

`recomputeNoticed` soft-deletes every noticed line and rewrites what the counts show
(`TessMemory+Turnover.swift:120-133`). Nothing remembers that he forgot one, so "Usually trains 6 pm to 8 pm",
swiped away on Monday, is back at Sunday's 04:00.

It's worse than that. The turnover also recomputes whenever there are no noticed lines (`:30`). So if he forgets
all of them, they all return at the next 04:00, Sunday or not.

**Fix:** keep a suppression per rule, with no text, as Research asked: a rule key such as `training.hour` or
`training.perWeek`, stored on the settings object or as a tiny `forgotten` field. `recomputeNoticed` then skips
those rules. A test should forget one, run the Sunday turnover, and check it stays gone.

### F2. Redaction isn't complete (Research F2)

- **Nothing calls `redact`.** It exists (`TessMemory.swift:356`), but no app code calls it after the 10 s window
  (no hits in `App/` or `Features/`). Until it's wired, the words stay in the RememberFact op's create row and its
  summary ("Kept. You train after work."), and in the soft-deleted object's title, which every backup copies.
  The page is AI-9, but the hook belongs here: it could be redact-after-window inside ForgetMemory's completion,
  or a sweep at the turnover of memories deleted more than 10 s ago that aren't yet "[forgotten]". The sweep is
  sturdier, because it also covers a quit within the 10 s.
- **ForgetAllMemory** (`:209-225`) gets no redaction path at all. The same sweep fixes it.
- **The capture op.** `redact` only touches ops whose `objectIDs` hold the memory. If "remember that…" first lands
  as a capture op without the memory's id (a ghost, a Tess route op, a miss-log row), those words survive. Core
  should confirm the capture PR writes RememberFact as the one op with the id, or have redact also match the text in
  same-minute capture ops.
- **Older backups.** Restoring a backup from before the forget brings the line back with its words. Research asked
  for a guard. One option: keep a text-free list of forgotten memory ids (the suppression store from F1 can hold
  it), and after a restore, run `redact` over any memory id on that list. Backups never include settings flags,
  so this list would have to live where restores read it.

### F3. Body words switch off the health screen for the whole line

Any line containing a body-part word skips the health refusal and is kept private (`TessMemory.swift:162-167`).
The match is a substring, so it is very loose:
- "back" matches "back from work".
- "I weigh 82 kg and my back hurts" is kept as a private memory with a weight in it.

Research F3 says private body facts are kept, but architecture section 4 still says memory never holds a health
value or a weight. **Fix:** let the body-part word exempt only the "sore"/"pain" class of words. Still refuse
`weigh`/`weight`/`kg`/`lb`/`bpm`/`kcal` and digits next to them. Match whole words (`back` as a token, not a
substring).

## Lows

- **L1. The turnover runs on every launch and foreground** (`AppModel.tidyProcesses`). On Sundays that means
  remove-and-rewrite of the noticed lines each time; with fewer than 4 workouts it's every day. Every pass leaves
  soft-deleted objects in the store and in backups. Fix: store the last turnover day and run once per 04:00 day.
- **L2. Copy against Design 49.**
  - ForgetAll's summary is "Everything forgotten." Design says "Everything forgotten, 12 things."
  - `thing(of:)` takes the first three words, so "I train after work" reads "I train after, forgotten."
    Design's example is the value word ("Left shoulder, forgotten.").
- **L3. Research F4 isn't wired yet.** No capture path calls RememberFact here, so there's no auto-keep, and that's
  fine. The KEEP / NOT NOW ghost belongs to the capture PR; I'll check it there.
- **L4.** `markUsed` writes `lastUsedAt` without an op, as designed ("weather"). It still dirties the object, so
  every Claude job rewrites the memory rows. That's fine at 40 lines.

## Checked and fine

- **Catalog v7 is additive.** It adds one new class, `tessMemory`, with seven fields, and the version goes 6 → 7.
  Nothing is renamed or removed. The PlanDaysTests version check is relaxed to `>= 6`.
- **No new LaunchFlags or ProcessInfo reads.** The AppModel change is the turnover call plus one stored note.
- **The pack never carries private lines.** It filters `!isPrivate` first and holds to its budget (test `:120`).
  Told lines come first, then up to 10 noticed lines for the area, then 7 recent.
- **The screen** refuses health, money, a key prefix and unlicensed numbers (test `:56`). Noticed and recent lines
  are counted on the phone, with only the numbers the counts license.
- **The 40 cap** drops the oldest unpinned told line not used in 90 days, and returns its words for Tess's one-time
  "I let one go to make room: …" (Design 49).
- **UNDO.** Remember, forget and forget-all each undo in one step (test `:71-118`).

## Addendum: re-check at `d6527ac` (Oct 16, about 2:55 AM Pacific): FIX FIRST (two items)

Rebased on master; trial merge clean. 7 files (+1118/-2). Static trace against Research's fixtures
(`docs/research/fixtures/tess-memory.md`: acceptance M1-M12, screen S1-S20, turnover T1-T9, section 4). Catalog v7
is still additive (one class, eight fields incl. `rule`); no LaunchFlags or ProcessInfo reads; the AppModel change
is the one turnover call.

### Closed
- **F1.** `write` refuses a rule in `suppressedRules()` (deleted objects that still carry a `rule`) and any text whose
  hash is in the forget log. The recompute clause is now `Sunday || (no noticed && nothing suppressed)`, so M3 and T6
  hold on the Monday and the Sunday after; a rule that simply stops holding has its `rule` cleared before removal,
  so it can come back. Rule lines update in place with the same id (T9).
- **F3.** Whole-word tokens for the screen, `guessArea` and the body words. `weigh/kg/lb/bpm/…` are refused private
  or not (S9, test `aPrivateLineIsKeptAsSaid`); other health words keep the line private with "Kept, on this phone
  only." (M4, S6, S7). "back from work" stays public (S10). card/target/steps no longer misfire (S11, S13, S14);
  espresso/weather/sunset no longer misfire (S18, S19). Shops refuse as places (S12, "I don't keep places.").
- **Research S1, S3/S11, S4, S6, S7, L1, L2.** No week lines, 14-day cut (T3); "About you"; told lines stored in the
  second person (M1); "I don't keep sums of money." (M5); the 41st told line refused with the cap line (M10); one
  turnover per 04:00 day; "Everything forgotten, N things." (M7) and "Left shoulder, forgotten."; "Nothing kept yet."
  (M9). A recent line is cut at a word, never mid-word (T2).
- **F2, in-store part.** `sweepForgotten` redacts every memory deleted over 10 s ago (a quit inside the window and
  forget-everything included), and logs the hash.

### F2b (must fix). The forget log doesn't survive a real restore
The log is `tessMemory` objects of kind `forgotten` **inside the store**. A restore replaces the whole store file
(`TesseraBackup.stageRestore`, BackupView.swift:268-271), so restoring any backup made before the forget brings the
line back with its words and with no hash to catch it: `reapplyForgets()` finds an empty log. That is fixture M8,
and the rolling backups keep 7 days, so it's the ordinary case. The test (`TessMemoryTests.swift:230-240`) creates
the "restored" object in the same store, with the log still there, so it can't see this.
**Fix:** keep the hash log outside the store too (a small file beside `tessera.sqlite`, or carried across by
`stageRestore` into the incoming store), and run `reapplyForgets()` on the first launch after a restore
(`TesseraBackup.restoredAt`). Nothing outside the turnover calls `reapplyForgets()` today.

### F5 (must fix). A body fact without a sore word goes to Claude
"my left knee clicks on squats" (fixture S5): the body word needs a sore word to count, there's no health word, so
the line is kept **public**, area Training, and `pack` sends it. Product's rule is "body facts never to Claude".
**Fix:** a body word alone makes the line private (the S10 false positive is already gone with whole words; "back"
can keep needing a sore word, since "back from work" is common).

### Should fix
- **S8.** "my resting heart rate is 52" is kept private, not refused: "heart" isn't a value word, and the number
  check never runs once a health word matched. Research's rule: a health word next to a number is refused. Kept
  private never leaves the phone, so this is not a block.
- **T4/T8.** Noticed lines are still third person: "Usually trains 6 pm to 8 pm.", "Trains about 6 days a week.",
  "Cooks most on Sundays." (TessMemory+Turnover.swift). Told lines are second person, so the page mixes both.

### Lows
- `area`'s catalog default is `.choice("other")`, which isn't in its options (`about` is). `read` falls back to
  `.about`, but the spec should say `about`.
- S16 "I don't eat pork" lands in About you ("eat" isn't a kitchen word); S20 "my sunset walk is my rest" lands in
  Training ("rest" is needed for M1). Both are the fixtures' calls to settle with Research.
- `recentLine` cuts at a word but can drop a dish: "…, cooked." Dropping whole parts ("and 3 more") reads better.
- `ForgetAllMemory.summary` counts with `Date.now` and `classDef(named: "Memory")`, not the injected clock and key.
- `lastTurnoverDay` is a process-wide static keyed by `ObjectIdentifier(store.context)`; a new context at a reused
  address would skip a turnover (tests mostly).

### Deferred to AI-8 (agreed, not blocking)
S5 `valueRanges`, F4 KEEP / NOT NOW, redaction of the raw capture text (M2's capture op).

## Addendum: re-check at `f55bb0e` (Oct 16, about 3:05 AM Pacific): FIX FIRST (one item, plus a conflict)

**The trial merge onto master e9bfef0 conflicts** in `PlanDaysTests.swift`: #363 already changed the same
`version == 6` line and moved that test. Merge master into the branch and keep master's version of that test; #356
needs no change there, because `>= 6` is already on master.

### Closed
- **F2b.** The forget log is also a hashes-only file, `Application Support/Tessera/tess-forgotten.json`. It's
  written atomically with complete file protection, never inside a `.tessera`, and read together with the in-store
  log. AppModel calls `reapplyForgets()` before the turnover at every launch and foreground. The M8 test restores
  into a second store that shares the log file, so it catches the real case. Tests use a temp file; only the app
  takes the default URL.
- **F5.** A body word on its own makes a line private. "back" still needs a sore word, so "back from work" stays
  public (S5 and S10).
- **S8.** A health word together with a number is refused as a measured value ("resting heart rate is 52").
- **T4/T8.** Noticed lines are now in the second person: "You usually train 6 pm to 8 pm.", "You train about 2 days
  a week." and "You cook most on Sundays."
- **Lows.** The `area` default is `about`. The recent line drops whole parts ("Thu: Push A done, 2 tasks.") and only
  cuts at a word when a single part is over 80 characters.

### F6 (must fix). He can never tell Tess a line again once he has forgotten it
The hash matches the words, and nothing ever removes a hash. Here's the sequence:
1. He forgets "You train after work."
2. Weeks later he says "remember that I train after work" again.
3. `RememberFact` writes it, and Tess says "Kept."
4. The next foreground runs `reapplyForgets()`, which matches the hash and silently redacts and deletes the line.

He's told it's kept, and it's gone. This existed with the in-store log, but it only bit at 04:00. Running at every
foreground makes it immediate.
**Fix:** a told line he says again is consent. On a successful `RememberFact`, remove its hash from both logs; the
store side can run in the same transaction, the file side right after. Also run `reapplyForgets()` only on the
first launch after a restore (`TesseraBackup.restoredAt`), not on every foreground. Add a test: forget, remember the
same words, foreground, still kept.

### Lows
- **Over-refusal.** The measured check refuses any line that has a health word and any digit, so "my knee hurts
  after 3 sets" is refused rather than kept private. Research's rule was a number *next to* the health word. Within
  three words would do.
- **The forget log is never cleared.** It isn't touched by a reset or by deleting the app's data from inside the
  app. It's hashes only, so this is a note for whoever writes "erase everything".

## Addendum: re-check at `f934bfa` (Oct 16, about 3:15 AM Pacific): PASS

Master is merged in, and `PlanDaysTests` keeps master's side. The trial merge onto master is now clean. The rest of
the delta since f55bb0e is #363 coming in through master, plus TessMemory.swift, the turnover and AppModel.

- **F6 closed.** The forget log is now `{forgotten: [hash: date], reappliedAt}`. A bare list in the old file format
  reads as forgotten long ago. `reapplyForgets()` redacts a line only if it was written before its words were
  forgotten. A successful `RememberFact` deletes the quiet in-store hash object in the same transaction, so UNDO
  puts it back. Forget, re-tell, foreground: the line is kept (test added). The re-apply no longer runs in the
  turnover or on every foreground. AppModel calls `reapplyForgetsIfRestored`, which runs once when
  `TesseraBackup.restoredAt` is newer than the log's `reappliedAt`.
- **Measured-value low closed.** A number counts only within three tokens of a health word, and never next to a
  feeling word. "my knee hurts after 3 sets…" is kept private; "my resting heart rate is 52" is still refused.
- The forget file is noted for "erase everything".

### Should fix (not a block)
- **S1. A second forget keeps the first forget's date.** `logForgotten` only writes a date when the hash is new
  (`if log.forgotten[hash] == nil`), and `forgottenAt()` takes the earliest of the file and store dates. The steps:
  1. He forgets a line on day 1.
  2. He says it again on day 3.
  3. He forgets it again on day 5.
  4. He restores the day-4 backup.

  The day-3 line is newer than the day-1 date, so it comes back with its words. **Fix:** on every forget, set the
  date to now (`log.forgotten[hash] = now`), and have `forgottenAt` take the latest date. It's a narrow path, but
  it's the same promise as F2b.

### Lows
- `logForgotten` stamps `.now` while the sweep and the turnover take an injected `now`, so tests mix two clocks.
  Passing `now` through would make the F6 test independent of the wall clock.
- `reapplyForgetsIfRestored` is only tested on the nil-marker path. A test with a restore marker newer than
  `reappliedAt` (runs once, then not again) would cover the real path.
