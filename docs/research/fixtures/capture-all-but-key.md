# Capture misses go to Claude whole: what moves, what stays, and key-shape rows for TessRouter

For: Core (`TessRouter`, `ClaudeTessModel`), QA. Date: 2026-10-17 · Research lab
Decision: Kaushik tapped "All but the key" on Product's capture card at 2:32 AM PT Oct 17. When the grammar cannot read a captured phrase, it may go to Claude whole, money, body, health and secret words included. Only the key and anything key-shaped stay on the phone. Every other Claude job keeps its walls.
Code read: origin/master `ea53f66`. Nothing run, no key used. No key-shaped text is in this file; shapes are built in the test (see section 3).

## 1. Where the walls stand today (what the change touches)

| Site | Today | Under the decision |
|---|---|---|
| `TessModel.swift:86-95` (`TessRouter.run`) | `secret` drops every non-grammar route; `walled` drops Claude | for `use == .capture` neither drops anything; the key check at the top stays |
| `ClaudeTessModel.swift:57` | refuses a request holding a secret word or a walled fact | same exception, capture only |
| `TessInbox.swift:30` and `:65` | the retry inbox skips secret and walled text | capture retries follow the same rule; Core decides, Product may want these two kept (section 4, Q2) |
| `TessCaptureEngine.swift:59` | a miss with a secret word or a walled fact is not written to the miss log | unchanged: the miss log is a file that backups copy (section 4, Q1) |
| `ClaudeKeyGuard.swift:15` | `looksLikeClaudeKey` is a case-insensitive substring test | unchanged |

Finding: the grammar already claims most of these phrases before the router sees them. `parseSecret` (`TessGrammar.swift:487-510`) turns any phrase with a secret word into a private note, and the privacy grammar claims a body-shaped phrase. So for those the decision changes nothing today. It only matters for phrases the grammar returns nil on (a miss) that also carry a secret word or a walled fact, which the grammar cannot do for a secret word while `parseSecret` runs first. Core should confirm this with a one-run grammar check on the rows in section 2 before building anything.

## 2. Existing fixtures: what the decision changes

`walls-ui-phrases.json` (114 rows):
- **Unchanged (grammar claims, Claude is never asked):** A01 to A05, A08 to A17, the notes, Siri, paste and objectPage rows.
- **Question use, unchanged (marked `allButKey` in the file):** A06, A07, BN01 to BN04, BN11, BM31. These end in `?`, so they take `TessUse.question`, not capture. The decision covers capture misses only. If Product extends it to questions, these eight flip from `expectNoClaude: true` to false, and BM26/BM27 stay as they are.
- **Output wall, unchanged:** BM01 to BM10 (what a model writes into a stored title) and BM21 to BM24 (Plan my day packs). They are other jobs, or the stored-data mask, and the decision does not name them. Core to confirm in the PR.
- **Claude must not receive (pack):** the Claude pack still holds no money, body, notes or habits (PM35, PM36, `grammar-miss-claude.md` "Never in any pack"). Only the phrase itself may now carry them.

`grammar-miss-claude.md` (186 rows): the 39 "local, zero requests" rows stay local for their own reasons (cook timers, Habits, Reading, Money slice gating, `errands:`). H609 and H610 ("spent 30 dinner sat", "spent 12.40 lunch thu") stay local only because Money is not built; when Money lands they are the first rows to re-read against this decision.

## 3. TessRouter key-shape rows

`PFX` is the Claude key prefix, assembled in the test from two halves; `FILL` is 40 characters of `0`. The test builds each phrase from these, so the file holds nothing key-shaped. Expected for every KEY row: `TessRouter.keyLine`, `source == .none`, no route's `run` called, no record, no miss-log entry, no backup text.

| ID | Phrase built in the test | Expected |
|---|---|---|
| KS01 | `PFX + FILL` | KEY |
| KS02 | the same, upper-cased | KEY (the guard is case-insensitive) |
| KS03 | `"my key is " + PFX + FILL + " thanks"` | KEY (anywhere in the text) |
| KS04 | `"call mom\n" + PFX + FILL` | KEY (multi-line capture) |
| KS05 | `PFX + "short"` | KEY (length does not matter) |
| KS06 | the prefix with a space inserted after its first dash, then `FILL` | **not caught** by the substring test today; it goes on as a capture miss and may now be sent whole. Core decides whether the guard should fold whitespace |
| KS07 | the prefix without its final dash, then `FILL` | not caught, same as KS06 |
| KS08 | a phrase the grammar misses, with no key and no wall word | not KEY; goes to Claude as before |
| KS09 | a phrase the grammar misses that carries a made-up money fact, such as `"put 40 dollars toward the thing for mum"` | not KEY; goes to Claude whole once the grammar has been traced to return nil (section 1) |
| KS10 | `PFX + FILL` typed while Claude is switched off | KEY (the key line still shows; nothing is stored) |

Counts: 10 rows, 5 KEY, 2 boundary, 3 positive controls. Boundary rows KS06 and KS07 are not a request to change the guard, only to make the answer a decision.

## 4. Questions for Product (one line each)

- Q1. Should a captured phrase with a secret word, money or body fact that goes to Claude still stay out of the miss log (a file that backups copy)? Recommend yes: keep it out.
- Q2. Should the retry inbox (`TessInbox.swift:30`, `:65`) send those phrases later, or only live ones? Recommend live only, so nothing sensitive waits in a queue.
- Q3. Should the "what was sent" screen show a phrase like this with its words? Recommend yes, since it is his own record and the key line already excludes the key.
