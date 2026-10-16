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
