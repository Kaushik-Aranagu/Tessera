# Kitchen stale re-check (K50, Oct 17)

*Kitchen lead, 2026-10-17. Docs only. Re-checked the Kitchen acceptance files in `docs/product/` for dead row ids, wrong file names, rows that contradict code on master, and copy against the current rulings. Row ids that cite another file (K, S, ER, KW-W, CM, WK, PF, GS, PS, RC and numbered rows) were all matched to a defining row; CM ids live in `grocery-capture-miss-acceptance.md`.*

## Fixed

| File | Row | Change |
|---|---|---|
| `pantry-acceptance.md` | S11 | Cited row 6.4 for "Nothing out."; now cites K26.9 (6.4 is the nothing-known side) |
| `kitchen-sides-acceptance.md` | 6.8 and the "Everywhere" line | Reduce Motion 200 ms to 150 ms (sheet 78, S16, K26.7) |
| `kitchen-refill5-pantry-acceptance.md` | Flag on 6.4 and 6.8 | Open "confirm and fix" replaced by the Oct 17 result |
| `kitchen-overnight-acceptance.md` | K6.9 and the open-questions list | "Default taken" for cook timers in quiet hours now reads ruled (decisions 3:00 Oct 17) |
| `recipe-clock-dst-acceptance.md` | RC4 | Quiet-hours ring "(default taken)" now "(K6.9, ruled)" |
| `kitchen-widget-wash-acceptance.md` | Open list; KW-W17 | Private copy "Private" replaced by "Private recipe, 7 pm." (KW-W8); KW-W17 notes the private face |
| `groceries-ai-acceptance.md` | "When Claude is asked" | Planning and typed-row triggers replaced by "only on his tap" (job-trigger-table wins); no daily cap |
| `kitchen-acceptance.md` | "Fix" heading | Marks the six fixes as landed in #70 |
| `cook-mode-acceptance.md` | Line 78 | Dropped "at" before a time |
| `kitchen-refill5-acceptance.md` | K32 setup; K32.12 | Dropped "at" before a time |

## Checked, left as is

- `kitchen-v2-acceptance.md` G1 and G3: master still splits "mac and cheese" and still draws "This recipe is gone. Undo brings it back." so both rows correctly say they fail today.
- `kitchen-gap-hunt-2.md` G6 to G11: line references still match master (`finishLine`, `StartKitchenTimer`, `ClaudeSection.remove()`).
- `paste-hardening-acceptance.md`: Oct 17 re-check stands; gaps 11 to 15 still unbuilt.
- Receipts already use "on"; the only "in Groceries" is the superseded-sheet note in `pantry-acceptance.md`.

## Not resolved

- Board decisions "2:40" and "3:00 Oct 17" have no text in `decisions.md` on master; rows cite them as given.
- Design files (`lists-9-12.md`, `us-shop.md`, `12-cook-mode.md`, `groceries-tess.md`) live outside the repo, so those cites cannot be checked.
- `kitchen-error-states-acceptance.md` ER5, ER8 and ER9 say "self-retries"; whether that means a retry on his tap for link and reader asks needs a ruling.
- `kitchen-week-one-rows.md` WK20 cites "E6" with no row in this folder.
