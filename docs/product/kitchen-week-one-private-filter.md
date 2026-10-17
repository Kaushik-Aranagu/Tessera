# Kitchen week-one script: private filter

*Kitchen lead, 2026-10-17. Spec for Core or Builder B, who own the data access of `scripts/kitchen-week-one.py`. Extends WK13, WK24, WK25 in `kitchen-week-one-rows.md`. Anything marked "default taken" is my inference, not a ruling.*

## What the engine marks (read from TesseraCore/Sources)

Recipe and Grocery item have no `isPrivate` field. Only Note has one (Catalog, "Private"). Privacy elsewhere is by word: `SecretWords` (title "Private note"), `EngineWall.isHealth` (list item label "Private item"), and `RecipeParser` ignoring secret-and-value lines. So the script must classify by text. Default taken: a recipe is private when its title is secret-worded or money/body-shaped; "Private recipe" is the printed stand-in.

## Rules

| ID | Input fixture | Expected output line |
|---|---|---|
| PF1 | Read set: Recipe (title, createdAt, lastOpenedAt, deletedAt), Cook, Kitchen Timer, Process, List item (parent, shares, createdAt), Ingredient (isStaple), Task, Op, Link. | No other class or field is read. Note, Event, Training, Body weight and money fields never queried. |
| PF2 | Recipe titled "Tacos"; another titled "Private recipe". Both opened, never cooked. | `Recipes opened but never cooked: 2` (count only; no title list). Default taken: drop titles entirely, as WK13 asks. |
| PF3 | Option `--titles` (off by default), 2 recipes as PF2. | `Recipes opened but never cooked: 2: Tacos, Private recipe`. Private title is replaced, never printed. |
| PF4 | Recipe titled with a secret word and a value (e.g. a title SecretWords.mentions flags). | Counted in `Recipes saved: N`; title shown as `Private recipe` wherever a title can print. |
| PF5 | Recipe title shaped as money ("Rent 1200") or body ("Weight 80 kg"). | Counted; title `Private recipe`. Default taken: same stand-in as PF4. |
| PF6 | Groceries item "Private item" (health item) and "Milk". | `Grocery items: 2 (0 from recipes, 2 typed, 0 typed staples)`. Counted, no item name printed. |
| PF7 | Groceries item whose title is a secret-word line. | Counted as typed; never printed. Default taken: no staple credit (Z) for it. |
| PF8 | Cook, timer, process linked to a private recipe. | Cooks, Timers, Shops count it. Per-cook figures are numbers only. |
| PF9 | Deleted private recipe (`deletedAt` set). | Not counted, as for any recipe. |
| PF10 | Any object with a price, amount or "$" in a title. | Output contains no `$` and no amount. Item names not summed. |
| PF11 | Capture-miss log with a line whose text is a secret phrase. | Prints count and source only. Never `text` content. The `startswith("http")` link count stays. |
| PF12 | Store file in the live Application Support path. | Script exits with a message asking for a copy. Opens with `mode=ro`. Never writes, never creates `-wal` beside the original. Default taken: refuse when the path contains `Application Support`. |
| PF13 | Any run. | Output has no title of a Note, Task or Event, and no Note body. |

## Test plan (Python, demo store copy)

1. Seed a demo store (`-demo -resetDemo` on the simulator), copy `tessera.sqlite` to a temp dir. Run the script on the copy; compare the store file hash before and after (PF12).
2. Insert fixtures in the copy with sqlite3: the PF2 to PF9 rows (private titles use the exact strings "Private recipe", "Private item").
3. Assertions on stdout: no fixture title appears except stand-ins; no `$`; counts equal the expected lines above; run with and without `--titles`.
4. Run on an empty week and a thin week (WK9, WK11) to confirm the filter does not change counts.
5. Add a grep guard: the script source contains no query on `note` or `event` classes.

## Open, defaults taken

1. **Title classifier.** Python cannot import SecretWords. Default taken: Core exports the word list into a small JSON the script reads, so the two cannot drift. Until then the script prints no titles (PF2).
2. **Private flag on Recipe.** Default taken: not added for this; text rules stand.
3. **Stand-in wording.** "Private recipe" for recipes, "Private item" for list items, "Private note" never needed here.
4. **Live store.** Refuse rather than warn (PF12).
