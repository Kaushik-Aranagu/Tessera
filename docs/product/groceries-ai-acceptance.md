# Groceries with Tess (AI-12): kitchen rules and acceptance

*Kitchen lead, 2026-10-16. The rules behind Design 47 (`docs/design/groceries-tess.md`, 05d14dd) and the AI thread's feature 3 (`docs/ai/first-features.md`, as corrected on Oct 16), so Core and Builder B can build without asking. Kaushik's line: Groceries sorts itself, knows which meal each thing is for, suggests what he usually runs out of, and reminds without nagging. Product can overrule any row.*

**The one rule.** The phone decides everything about the list: what a planned meal still needs, where a row goes, what he usually runs out of, and what Home says. Claude gets one narrow job: saying that a row he typed is the same thing as a planned recipe's ingredient under another name. It returns pairs, never rows, amounts, aisles or words.

## Who does what

| Moment (Design 47) | Phone | Claude |
|---|---|---|
| 1 Sorted | `Aisles.swift`, the learned aisle on the ingredient, as built | Nothing |
| 2 The link ask | Picks which rows are worth asking about, words the ask, checks the pairs, writes the link on KEEP, remembers NOT NOW | Returns pairs |
| 3 Planned meal's missing lines | `AddRecipeToGroceries` minus staples minus what's covered, on planning | Nothing |
| 4 USUALLY | `usuallyOutOf()` from `checkedAt` history, Research's rules 1-9 | Nothing |
| 5 The Home line | `HomeLines`: the planned cook's row carries the open count | Nothing (the count is a fact; AI-1's wording job may word the line, under its own number check) |

## 3 · Missing lines (changes the meal plan defaults)

Design 47 lands the rows when the meal is planned, not at 17:00 the day before. That replaces the **When** and **Tess** rows of `meal-plan-groceries-acceptance.md`; everything else there (only once, moved, deleted, undone, cooked early, merging) stands.

- **When:** the moment the cook task is captured or its recipe set, for any date. No tidy pass is needed for the add itself; the pass still catches a recipe linked to a task later.
- **What:** the recipe's lines at its own serves, skipping staples (`isStaple`, `AisleGuide.staples`), "to taste" lines and optional lines ("optional", "for serving", "for garnish": skipped on the list, still shown on the recipe page; Research G-R4). An ingredient already on the list is **covered**, two ways (G-R2): a same-key **open** row takes the share and gets the recipe line (a bare row shows the recipe's amount, "8 eggs"; a row with an amount sums as today); a same-key **checked** row covers the line and nothing is added. A row kept for it through the ask (section 2) covers it too.
- **How it shows:** wet cobalt ghost rows in their aisles with "for tacos" under each, drying over 1.4 s. Tess: "Added 2 for tacos." with UNDO for 10 s; N counts new rows only, and joined rows still get the recipe line (G-R14). A row two meals share reads "for tacos and chili"; three or more, "for curry and two more", sooner meal first (G-R9). A pack size sits after the meals: "for chili · 28 oz". Two different pack sizes of one thing stay separate rows; a loose amount joins the pack's row with "+", pack first (G-R8, Design to confirm). UNDO removes exactly those rows (`RemoveRecipeFromGroceries`). No sage dab anywhere any more (`no-dots.md`); the recipe line replaces it on every recipe-sourced row, including rows from the recipe page's swipe.
- **Nothing to add** (everything covered): no rows, no Tess line.
- **Several meals in one capture** ("tacos tue, dal wed"): one Tess line per meal, in order, each with its own UNDO.
- The line under the title counts open items and names the meals: "9 to get, for tacos and two more" (one meal: "for tacos"; none: "9 to get").

## 2 · The link ask

**What the phone tries first, with no Claude.** For every typed row (a share with no recipe) and every planned recipe's uncovered ingredient:
1. Same key (`IngredientLine.key`): link silently, no ask. On master the key only lowercases and singularises; the alias fold (whole, 2%, skim and semi skimmed milk to milk; yellow onion to onion, red onion apart) is Core's G-R6. Until it lands, "whole milk" against a typed "milk" is a Claude candidate.
2. Everything else is a candidate for Claude, at most 12 rows and the week's planned recipes per call.

**When Claude is asked.** On planning (before the missing rows land, with an 8 s wait; on timeout the rows land anyway and the asks come when the reply does) and when a typed row is added while a meal is planned (debounced 10 minutes). Never while shopping (hold-the-title mode), never in a live workout, never with the switch off, offline, at the cap or in demo: then the list works without asks, and nothing is queued for later except the next natural trigger.

**Pack** (everything that leaves the phone for this job, snapshot-tested):
- Planned recipes this week: handle, title, and each uncovered ingredient's handle and title.
- Candidate rows: handle and the **ingredient's title**, never the typed text, never the amount, never `checkedAt`. A new ingredient is titled as typed, so a candidate whose title holds a shop or brand name (Trader Joe's, TJ's, Costco, Kirkland, Whole Foods, 365) stays out of the pack altogether (G-R12).
- Told memory lines that mention food ("coriander means cilantro").
- Nothing else: no quantities bought, prices, shops, notes, history, other lists.

**What Claude may return** (strict `linkItems`): `{pairs: [{row, ingredient}]}`, at most one pair per row, at most 6 pairs per call, nothing else. No text, no aisle, no amount, no new row.

**Checks on the phone before anything shows.** A pair is dropped silently when:
1. Either handle isn't in the pack, or the ingredient isn't in a planned recipe.
2. The row already has a recipe share, or the ingredient is already covered.
3. The pair is in this week's NOT NOW memory.
4. Both titles are the same key (the phone would have linked it; a stray return is ignored).
5. The row is a staple.

**How it shows.** One ask at a time through the one-ask slot: "{Row}, for the {recipe}?" with KEEP then NOT NOW. The words come from the phone. A second pair waits until the first is answered or leaves. An ask left unanswered leaves when the page is left and comes back next visit; it dies with the planned week.

**KEEP** writes, as one undoable op by `.tess`:
- A recipe share on the kept row, flagged as a link only: the row's amount stays as typed, and the recipe line under it reads "for tacos".
- If the recipe's own ghost row for that ingredient is open and unchecked, it folds into the kept row (its share moves; the row leaves). The list never shows the same thing twice.
- The aisle, when the kept row sits in Other: the recipe ingredient's aisle as shown (learned, else the guide) is written as the kept ingredient's learned aisle, and the row moves (G-R11).
- Tess: "Scallions, for the tacos." with UNDO for 10 s. UNDO puts all three back.

**NOT NOW** writes nothing to the list. The pair (row ingredient key, recipe) is remembered on the phone until the planned week ends, applied before packing, never sent. Tess says nothing.

## 4 · USUALLY

The engine is slice R as decided on Oct 15 (`kitchen-v2-backlog.md`, Research's `pantry-light.md` rules 1-9): three or more typed buys in 56 days at a steady gap U, due from 0.85 U to 2 U days after the last buy, recipe-only items never, irregular items never. Two changes from Design 47, both taken:
- **At most 4 names** (was 3), most overdue first.
- The surface is the USUALLY label and a line of ink words, replacing "Usually have: milk, eggs". The words are the names; no verb, no plus.

Unchanged: one shop run each (shown and not bought when the shop clears, or swiped away, goes quiet until the next buy); never notifies, never badges, never a Home offer, never red, never Claude. Tap: the word flies to its aisle as a ghost row, Tess: "Oat milk, in Dairy and eggs." with UNDO. Long-press: "Bought 6 times in 8 weeks, about weekly."

## 5 · The reminder

The only reminder is the planned cook's Home row through `HomeLines`: context "2 to buy" over "Tacos tonight", key GROCERIES, which opens this page. The count is the open, unchecked items carrying that cook's share. At 0 the context is the time again and the key is COOK. It appears on the cook's day, as the task already does. No notification, badge, dot, Live Activity or Tess line, ever, for groceries.

## Done when

**Core**
1. `swift test`: planning "tacos tuesday" with the 10 seed recipes' tacos adds its non-staple, uncovered lines at once with a share carrying the recipe and the task; planning again adds nothing; UNDO removes exactly them; "tacos tue, dal wed" adds both, each undoable alone.
2. A typed "spring onions" before planning is linked silently (same key); "scallions" is not, and appears in the pack as a candidate with its ingredient title, not the typed text.
3. KEEP on (scallions, spring onions) moves the recipe share onto scallions, removes the open spring onions ghost row, keeps the typed amount, sets the learned aisle, and UNDO reverses all of it. NOT NOW writes nothing and the pair is filtered from the next pack until the task's date passes.
4. The five checks drop bad pairs: an unknown handle, a linked row, a NOT NOW pair, a same-key pair, a staple.
5. Pack snapshot for the fixture week holds no amounts, typed text, prices, shops, notes or `checkedAt`; a candidate titled with a shop name is absent; a pack containing `sk-ant-` is refused.
6. No call while a shop process runs, in a live workout, with the switch off, offline, at the cap or in demo; in each, planning still adds the rows.
7. `usuallyOutOf()` passes Research's 20-week fixture row by row with the cap at 4.
8. `HomeLines` gives "2 to buy" / "Tacos today" before 17:00 and "Tacos tonight" after, the time when the task has one, for a planned cook with two open items; at zero the context is the day word and the key is COOK (G-R13).
9. Research's five-meal week (`docs/research/fixtures/groceries-recipes.md`) gives 36 rows, the 28 oz and 14.5 oz tomato cans apart, kosher salt and the optional lines absent, "Added 10 for tacos." and "Added 3 for frittata.", and its 13 `linkItems` probes pass with the gate fixture.

**Match eval (gate, AI thread runs it with `docs/research/fixtures/groceries-link-eval.md`).** Four planned seed recipes, 24 typed rows, 3 runs: the 10 must rows (scallions / spring onions, capsicum and bell pepper / red pepper, ground beef / beef mince, tinned tomatoes / chopped tomatoes, tomato paste / tomato puree, parmigiano / parmesan, beef stock cube / beef stock, cherry toms / cherry tomatoes) pair correctly in every run; the never rows (coriander, lemongrass, lemons, spring greens, sour cream, chilli flakes, sweet potatoes, coconut milk, rocket, veg stock cubes) get no pair in any run; 0 false pairs in all 72 row-runs. A pair the model can't be sure of is better left out: a missed link costs one duplicate row he can delete, a wrong link puts the wrong thing in his basket.

**Shared ingredients.** An ingredient two planned recipes use is one handle in the pack listing both recipes; the ask names the sooner recipe; KEEP covers both.

**Builder B** (recording at 60fps, `docs/recordings/groceries-tess.mp4` beats)
1. ‹ KITCHEN back word, Title 44, the count line "9 to get, for tacos and two more", aisle window fading over its last 50pt.
2. Recipe line "for tacos" at 16 `inkSecondary` under every recipe-sourced row; no trailing dab anywhere on the page.
3. Planning a meal: rows fly in from Tess's corner 60 ms apart, rows below make room in 320 ms, rows dry over 1.4 s; "Added 2 for tacos." with UNDO; the count line rolls.
4. The ask: "Scallions, for the tacos?" with KEEP then NOT NOW as ink words; the wet "for tacos?" line under the row; KEEP dries it over 900 ms and the spring onions row leaves; NOT NOW fades it in 300 ms. Only one ask on screen; none while shopping.
5. USUALLY: Label 16 and words at 21/600 at 70%; a tapped word flies to its aisle in 520 ms and the line closes up; gone when nothing qualifies.
6. Home: "2 to buy" over "Tacos tonight" with GROCERIES as the key, opening Groceries; "tonight" and COOK once everything is in.
7. UI bar: nothing under 16pt, no pills or buttons, Inter Tight, cobalt for Tess's wet ink only, Reduce Motion gives crossfades, Dynamic Type wraps the count line.

## Open questions, defaults taken

1. Rows land on planning for any date, not 17:00 the day before. DEFAULT: on planning (Design 47); he can delete a row he won't need yet.
2. A kept row keeps its typed amount even when the recipe wants more. DEFAULT: yes; the ask never changes an amount.
3. USUALLY cap. DEFAULT: 4 (Design 47), over R's 3.
