# Gap lane, Oct 17, part 2: eval rulings, key-shape audit, phrase cap, Home masking, facts follow-through

For: Product (Core gets the fix designs). From: AI architecture. Read against master 47365b0, Research #880 and #876. No Claude calls were made; no key was used or read.

## 1. Research #880 against `architecture.md` (4:10 PM rulings)

| Ruling (decisions.md, 4:10 PM Oct 17) | `architecture.md` before | Fits? | Doc change |
|---|---|---|---|
| Cook timer phrases never leave the phone; Core adds a cook check before the route | Section 7 "never leaves" list names cook timers | Doc is right; the route has no cook check yet (#880 trace) | Add "enforced by a cook check before the route (Core, pending); until it lands the route does not stop them" |
| A number after "at" or "by" in clock shape ("dinner at 7.30") is a time, not money | Money wall says "a money screen", no clock exception | Does not fit | Money bullet: add the clock-shape exception; money still needs a currency sign or amount words |
| The capture pack carries no open tasks | Capture row lists "open task titles" in the pack | Does not fit, and the code agrees with the ruling | Remove "open task titles" from the capture row; add "a move with no local match is a plain miss, not a guess" |
| Number-word weights ("eleven stone four") are body facts, walled like digit weights | Body wall lists weight numbers | Fits; add the number-word form | One clause on the body bullet |

The doc edits ride with this PR (architecture.md capture row, the never-leaves bullet and the money bullet). Core's two code items are the cook check and the clock-shape test in `isMoneyShaped`; the test names are in #880 section 2b (`cookPhraseNeverReachesClaude`, `cookCheckRunsBeforeTheRouter`).

## 2. Key-shape refusal audit (Research #876 gaps) and one fix design

#876 lists nine gaps (G1 to G9). They share a cause: the key guard runs in the view (`PasteKeyFilter`) and in the router, but not at the places that **store** text. A guard at the view is a convenience; a guard at the write is the wall. Design for Core, one change in three parts.

**Part A: one normalizer in front of the guard (fixes G4, G5, G2).** `ClaudeKeyGuard` gets a private `normalized(_:)` used by `looksLikeClaudeKey` and `withoutClaudeKeys`: Unicode compatibility form (fullwidth letters become plain), drop format and ignorable characters (zero-width, soft hyphen, joiners), percent-decode once, then remove whitespace **inside** the prefix match, not only around dashes. After a cut, also cut a following run of 8 or more letters or digits whether or not it holds a digit (G2): the prefix is gone, but a leftover half-key in a title is worth removing and costs nothing. The missing-last-dash shape without a digit (G3) stays as it is; there is no prefix left to match and the false-positive cost on recipe words is high.

**Part B: guard at every store (fixes G1, G6, G8).**
- `RecipeLinkShelf.keep`: refuse when `looksLikeClaudeKey` on the full absolute string, query names included.
- `RecipeLinkShelf.waiting()`: drop any stored entry that trips the guard, and rewrite the file once.
- `CreateRecipe.apply`: run `withoutClaudeKeys` on title, each ingredient, each step and `sourceText`; if anything key-shaped remains, refuse with the key line and write nothing.
- Same two checks wherever a miss or inbox text is stored; `CaptureMissLog` and `TessInbox.add` already use the guard and gain Part A for free.

**Part C: guard at echo and at the redirect (fixes G7, G9).**
- `duplicateLine`, `shownTitle` and `savedTitle` mask a key-shaped title the way they mask a private one ("Recipe", never the title).
- `RedirectGuard` (RecipeLinkReader.swift:616) runs the key test on each hop's URL as well as `safeURL`; a hop that is key-shaped ends the read with the "too big or odd" line, and `sourceURL` is key-checked before it becomes a recipe's source.

**Tests:** the 27 names in #876 section 5 are the acceptance list; the rows #876 marks as differing today (PL06, PL13, PL17, PL18, PL19, PL20, PL23, PL26, PL27, PL30, PL32, PL35, PL37) should pass with A, B and C, except PL17 without a digit, which stays as decided. Add one table test over the normalizer: every shape in `KeyShapeTests` plus the zero-width, fullwidth and percent-encoded forms, built from halves, never a literal.

## 3. Phrase cap and "What was sent" row for walled phrases (spec)

**Cap.** The Claude capture route sends at most **500 characters** of the phrase. Longer: nothing is sent, the rules line shows, and the phrase is handled as a miss on the phone ("That's long. Paste it as a note?" with the usual keep). 500 is a guess, well above a spoken or typed capture; Research should check it against the 913-row suite before Core builds it. A pasted recipe or email never reaches Claude by this route. The count is of the trimmed phrase after the key refusal, before any wall test. A test `longPhraseNeverReachesClaude` with a 501-character phrase and a 500-character phrase.

**What was sent row.** Every capture-miss request writes one row to the log in `what-was-sent-log.md`:
- Walled phrase (secret, money, body or health word per `SecretWords` or `PrivateFacts`): the row reads "Sent to Claude: a private phrase, <time>" with the job, the cost and the outcome. The phrase text is not stored (the log is on the phone, but a log that held the words would be the one place the walled phrase is kept in plain text). A tap shows "Sent whole because you chose All but the key."
- Unwalled phrase: the row holds the phrase as the pack showed it, as today.
- The one-time notice stays as built in #860.
- Test: `walledPhraseRowHasNoPhraseText`, and the existing key-shape test over the log file.

## 4. Home lines final check against `HomeLines.swift:505`

Finding (one fix, high value): `HomeFacts.fact(done:)` at line 503 builds the Home fact from `summary.title`, which is unmasked (`WorkoutSummary.doneLine` is internal on purpose, QA on #787; only `doneLine(in:)` masks). `NowPage.swift:305` feeds that fact to `HomeLines.line`, and I found no masking in `HomeLines.swift` (the only privacy check there is the cook title at line 599). So a done workout from a private routine shows its real title on the Home hero. The same holds for the running or paused workout branch at line ~512, which uses `store.displayTitle(of:)` (not read for masking).

Roughly 15 line variants use `fact.title` for a workout (the done, running, paused and glance forms, lines 253 to 309). Fix once, in the builders, so every variant inherits it: in `fact(done:)` and in the workout branch of `fact(process:)`, set `title: ObjectPrivacy.routineTitle(summary.title, in: store)`. That returns "Private workout" for a private title (Product 12:35 PM, decisions on #849). Then:
- A Home test over all 15 variants with a private routine title: none contains the title; each reads "Private workout ...".
- `HomeDonePack` and the Claude Home done job already refuse a walled pack (reviewed in #658), so Claude is covered; this fix covers the phone's own lines, the Live Activity and Siri.
- The exercise short names in `records` stay (exercise names are not private; a private routine's exercises are named in the history anyway). Flag to Product if a private routine's best should also read "Private workout best".

## 5. Claude-facts storage follow-through (corrects part 1 of the gap lane)

The gap-lane page said Exercise gains new `primaryMuscles` and `secondaryMuscles` text lists. That is wrong: the catalog already has both as **reference lists to Muscle objects** (`SystemCatalog.swift:84-85`, 18 built-in muscles). The fill must not add text.

- **Exercise fill:** Claude's tool returns muscle names; the phone matches them to the 18 `MuscleSeed` names and writes the existing `primaryMuscles` and `secondaryMuscles` links. A name that matches no seed writes nothing for that muscle. `factsSource` and `factsAsked` are the only new Exercise fields.
- **Ingredient fill:** no nutrition fields exist yet. Add `kcalPer100g`, `proteinPer100g`, `fatPer100g`, `carbsPer100g` (optional numbers) plus `factsSource` and `factsAsked`. Additive, next catalog number (v11 if v10 is #407); `TesseraLegacyStore` untouched.
- **Ledger:** add a `fillFacts` case where the ledger `use:` values live (`TessUse`), Sonnet 5.5 low effort, tool choice auto, 8 s, no retry, priority: runs to $50 (worst month $0.26).
- **Gate unchanged:** `claude_facts_eval.py` stays dry; a live run needs Kaushik's own yes in the running thread. Nothing in this page asks for one.
