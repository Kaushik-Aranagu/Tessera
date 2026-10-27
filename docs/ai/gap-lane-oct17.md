# Gap lane, Oct 17: capture-miss review, spend refresh, facts storage, kept-link failures

For: Product. From: AI architecture. Read against master ae3796f (after Core #860). No Claude calls were made. Code lines are named, not quoted.

## (a) Capture-miss route: what can reach Claude, and what it costs

**What leaves the phone on a miss** (`ClaudeTessModel`, `TessModelCapture`): the phrase, the date line, the current exercise name, the last set (kg x reps), and the tool definitions. Since #860 the phrase itself may hold money, body, health or secret words (his "all but the key"). Nothing else gains access.

**What still cannot leave on this route**
- The Claude key and key-shaped text: refused in `TessRouter` and again in the Claude route.
- Siri and Shortcuts captures: they commit at once and never send (`siriAndShortcutsNeverReachClaude`).
- A walled phrase the grammar already answered with a question or refusal stays on the phone.
- The count tool `answerQuery` reads an allow-list of classes only; money, body and his own classes are never counted for Claude. (Send side superseded by Kaushik's Oct 27 11:59 AM ruling, docs/product/decisions.md; the backup, log, widget and screen walls stay.)
- Claude's reply is not spoken back for a walled phrase: the masked receipt shows, and the notice does not quote the phrase.

**Money and body, plainly:** they can reach Claude only inside the phrase he typed or spoke. They cannot come from the pack, the tools or any stored object. Product's wording "money and body never" is true for every job except this one door.

**Findings (all low)**
1. The phrase has no length cap before it is sent. Cost is not the worry (a 10,000-character paste is about 3,000 tokens a round, 3 rounds, about $0.001 on Haiku), but a long paste would leave whole. Suggest a cap of 500 characters for the Claude route, with the rules line above it.
2. The walled-phrase test in `ClaudeTessModel` is `SecretWords` or `PrivateFacts.isWalled`, but the money screen in `TessRouter` is a third test. A money phrase the router's screen catches and `PrivateFacts` does not could get Claude's own line spoken back. Core to confirm both functions agree on the same list.
3. The What was sent list should name a walled phrase as "sent whole" so he can find it; see `what-was-sent-log.md`. Check that #860 writes that row.

**Cost:** unchanged. Misses stay at $0.0006 typical, $0.0015 at the 3-round ceiling; a walled phrase adds a few tokens. The change is volume: phrases that used to stop at the wall now go. Even 20 a day at the ceiling is $0.90 a month.

## (b) Spend projection against the $50 cap (refresh)

Source: `spend-projection.md` and `model-effort-cost-table.md`, with these changes since Oct 16.

| Change | Effect on month |
|---|---|
| Home done job is one Sonnet call per finish, steps aside at $40 | typical $0.06, worst $0.68, as the table already says |
| linkItems (groceries) runs to $50 and never steps aside | about $0.03 at 60 calls |
| Capture misses now include walled phrases | at most a few more calls a day, under $0.10 a month |
| Facts fill and Ask about this are still off until switched on | worst $0.26 and $2.77 if used every day |

**Totals:** typical **$0.79** (2% of $50), worst **$7.46** (15%) with misses at their held ceiling. Headroom to $40 is $33.10 at worst. No job is near either line, so no step-aside rule changes. These are assumed numbers (A) except groceries link and the Home done shape (measured). The first real month in the ledger replaces the assumptions: ask Core for a monthly export of `TessUsageLedger` rows by job once a month exists.

## (c) Claude-facts storage spec

Design source: `side-jobs.md` section 3. This is the storage contract Core builds from.

- **Fields (additive, next catalog number, v11 if v10 is #407).** Ingredient: `kcalPer100g`, `proteinPer100g`, `fatPer100g`, `carbsPer100g` (optional numbers), `factsSource` (text), `factsAsked` (date). Exercise: `factsSource`, `factsAsked`; the muscles use the existing `primaryMuscles` and `secondaryMuscles` links to Muscle objects (corrected in part 2).
- **Source text.** Empty for a table value. "From Claude, Oct 16" for a fill: house date style, written by the phone, never by Claude.
- **Asked once.** Any answer, including a decline or a refusal, sets `factsAsked`; nothing asks about that thing again. A decline writes nothing else.
- **Table wins.** A table row that lands later replaces a fill and clears `factsSource`.
- **Writes.** Only through `ObjectStore`, as a pending ghost row with KEEP and NOT NOW; only KEEP writes. Same shape as `remember`.
- **Walls.** Only public per-100 g food facts and exercise muscles are stored or sent. A measured body value, an intake or an amount is never stored. The pack sends the name only.
- **Ledger.** Job `fillFacts`, Haiku or Sonnet per the eval (Sonnet 5.5 low effort, tool choice auto), 8 s timeout, no retry, priority: runs to $50 (worst month $0.26; it is data, not words). Needs a `TessJob` entry (open gap 6 in `offline-retry-table.md`).
- **Backup, forget, export.** In backups with the object. Forgetting the object removes the fields. Not in the forget log: nothing private is in them.
- **Gate.** Off until `claude_facts_eval.py` passes and Kaushik says yes in the running thread.

## (d) Kept links: failure modes and what each says

The kept-link rule is Kitchen's ruling on #845. A link is kept only when the failure may pass; a firm refusal drops it with "Paste the text instead."

| Failure | Kept? | Line (`RecipeLinkLine`) |
|---|---|---|
| Offline, or the 15 s page cap ran out | Kept | "Recipe link, kept for later." |
| Site 429 or 5xx | Kept | "Recipe link, kept for later." |
| Claude 429 or 5xx (busy) | Kept | "Recipe link, kept for later." |
| Claude timeout | Kept | "Recipe link, kept for later." |
| Paused at the $50 cap | Kept | "Recipe link, kept until Claude is back." (the read screen says "Claude's paused until <date>. Paste the text instead.") |
| Bad or refused key | Kept | "Recipe link, kept. Check the Claude key in Settings." |
| Switch off ("Tess asks Claude") | Dropped | "Claude is off. Paste the text instead." |
| No key | Not checked in code | Core to confirm which line shows; suggest "Add your Claude key in Settings." |
| Blocked, paywalled, no recipe, too big, video without text, password in the link | Dropped | the firm line for each |

**Findings:** (1) offline, busy site, Claude busy and Claude timeout share one line, so he can't tell a bad connection from a busy Claude; fine for a calm app, flag only if he asks. (2) A kept link is retried only when he taps it; nothing retries in the background, which matches "nothing waits on Claude". (3) Confirm the no-key case has its own line that names Settings. (4) The kept-link line never shows the key or any part of it, as required.
