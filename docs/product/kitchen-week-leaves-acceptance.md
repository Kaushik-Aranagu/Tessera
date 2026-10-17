# K11: Kitchen jobs on the week side, WHAT LEAVES THE PHONE

*Kitchen lead, 2026-10-17. Draft, docs only. Sources: decisions 7:28 PM Oct 16 (Sheet 80), `ai/what-was-sent-log.md` section 1 (job names), `ai/first-features.md` AI-12, `design/sides-77.md`, `docs/product/groceries-ai-acceptance.md`, `kitchen-sides-acceptance.md`. "(inf)" marks my inference, not a found rule.*

**Names in the log (`TessUse` raw values):** homeLines, planMyDay, askSubject, misses, ask, recipe, groceries, weekStory, colour. The side shows display words ("Today's lines", "Plan my day", "Your week", "Recipe reading"; sides-77). 7:28 (4): a job shows by its own name once it has rows; Recipe reading is named then, not before.

## Kitchen jobs and what each sends
| Row | Job (log name / side word) | Class | Sent / never sent |
|---|---|---|---|
| K11.1 | `recipe` / Recipe reading | Page text | Sent: the fetched page's text, money-shaped spans cut first (2:22 test, M1-M4). Never: anything when the switch is off or a secret word is on the page (M6) |
| K11.2 | `recipe` | Titles | Sent: only what is in the page text (inf). Never: his own recipe titles, notes, private recipes |
| K11.3 | `recipe` | Prices, money | Never sent: stripped before the call, not after (M4); not stored from the fetch (M7) |
| K11.4 | `groceries` (link ask, AI-12) | Titles | Sent: planned recipes' handle and title, each uncovered ingredient's handle and title, candidate rows' handle and ingredient title. Never: his typed text; a title holding a shop or brand (G-R12) stays out |
| K11.5 | `groceries` | Ingredient keys, memory | Sent: handles, enums of handles, told food memory ("coriander means cilantro"). Never: real ids, handle map |
| K11.6 | `groceries` | Amounts, prices | Never sent: quantities, prices, shops, `checkedAt`, notes, history, other lists |
| K11.7 | `groceries` | Pantry state | Never sent: no pantry in the pack; no state, no bought date (kitchen-sides 6.7) |
| K11.8 | `groceries` | Private items | Never sent: a money or secret line becomes a private note, never a row, never a candidate (W2, W3) |
| K11.9 | `groceries` | Reply | Back: handle pairs only, at most 6 per call; nothing written until KEEP |
| K11.10 | `ask` or `askSubject` (inf: the fill rides the subject ask; name not stated) | Ingredient fill (missing nutrition row) | Sent: the ingredient's key and nothing else; once per key. Never: note, recipe, amount; a private recipe's ingredient; a secret word; with the switch off |
| K11.11 | Plan wording | all | No Kitchen plan-wording job found. Planned-cook lines are phone rules ("Tacos tonight, 2 to buy", first-features). If one is added, it needs its own log name first |
| K11.12 | Body or money facts | any Kitchen job | Never sent. `weekStory` is the only job carrying a week (tasks, cooks as counts); it excludes health, body weight, money, notes (first-features) |

## The side itself
| Row | Check |
|---|---|
| K11.13 | The side lists the last 30 days' calls by job (7:28 (3)), each with what it sends in titles and counts |
| K11.14 | The glance big fact is the call count ("38 calls"); no dollar figure on the side, the cost stays on the spend line (7:28 (3), sides-77) |
| K11.15 | Titles and counts only; no payload text, no recipe text, no handle map (log section 2: never stored) |
| K11.16 | Private items appear only as counts ("N held back"); no title, no words (inf from log section 1 "Held back" and 2:41 "never show a private fact") |
| K11.17 | No controls on the side; nothing on a side goes to Claude (2:41 (a)) |
| K11.18 | Failed and timed-out calls count as sent; the key Test does not (7:28 (1)) |
| K11.19 | Walls line reads "Never notes, places, health or money." (7:28 (5)) |
| K11.20 | **Names match:** every job name on the side equals a name in the log. Mapping: Today's lines=homeLines, Plan my day=planMyDay, Your week=weekStory, Recipe reading=recipe, link ask=groceries. "Captures" and "Questions" are accepted names (7:28 (4)) but I found no log value for them: Core to map (open) |

## Open, defaults taken
1. **Name for the nutrition fill.** Default: it logs as `ask`/`askSubject` until Core names it.
2. **"Your week" vs `weekStory`.** Default: the side word is "Your week"; the log keeps `weekStory`.
3. **Groceries has no side word** in sides-77's example list. Default: "Grocery links" (inf), shown only once it has rows.
4. **"Captures" and "Questions"** have no `TessUse` value in the log's list. Default: they are display words for existing jobs; Core confirms.
5. **Held-back counts** per job on the side. Default: one total, as the log's "Held back" count.
6. **Not run.** Nothing here was built or tested; rows are acceptance text.
