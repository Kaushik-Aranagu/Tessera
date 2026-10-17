# Pantry light: "usually have" from the grocery log

For: Kitchen lead, Core
Date: 2026-10-15 · Research lab
Inputs: `../product/ship-list-kitchen.md`, `../product/kitchen-v2-backlog.md` (rows P and R), `../product/kitchen-week-one.md` (question 1), `tess-voice.md`, `context-packing.md`, `kitchen-v2.md` §1, and TesseraCore on origin/master at e55d6d4.

## 1. The answer in one paragraph

No pantry inventory, no states, no counts. Read the Groceries history he already makes, find the few things he buys on a steady beat, and when one is due and not on the list, offer it once as a single dim line at the foot of the list: "Usually have: milk, eggs". A tap adds it. Nothing is ever added on its own and nothing ever notifies. This can ship **before** slice P (pantry state), so if week one's question 1 comes back "yes", this is the cheap first answer and P can wait for more evidence.

## 2. What the grocery log records today (origin/master e55d6d4)

There is no separate purchase log. The history is the Groceries list items themselves, which survive being cleared, plus the op log.

| Fact | Where | Notes |
|---|---|---|
| Added, and when | `AddListItem` creates a `List Item` under the list, `Lists/Lists.swift:121-140`; the item's `createdAt`, `Model/Models.swift:271` | Typed lines go through `AddGroceries`, `Kitchen/Groceries.swift:282-295` |
| Typed or from a recipe | Each item keeps `shares` JSON, `Kitchen/Groceries.swift:62-65`; field at `Catalog/SystemCatalog.swift:217`. Typed share has `recipe: nil` (`Groceries.swift:287`); recipe share has the recipe id (`Groceries.swift:213-214`) | This is how we tell "he wanted milk" from "the carbonara wanted lemons" |
| Which ingredient | `about` link to an `Ingredient`, `Groceries.swift:54-57` and `166-172` | One open item per ingredient: merges only into items not done, `Groceries.swift:147-150`, so one item is one buy |
| Checked (bought) and when | `CheckListItem` sets `isDone` and `checkedAt`, `Lists/Lists.swift:163-169` | `checkedAt` uses `.now` (`Lists.swift:167`), not the app clock, and the action has no `time` input, unlike `StartShop`/`FinishShop`. Unchecking clears it |
| Quantity | Free text `quantity`, `Lists.swift:130-131`; summed from shares, `Groceries.swift:164-165` ("600 g") | Per-share amount and unit sit in `shares` |
| Cleared after the shop | `ClearDoneItems` soft-deletes checked items, `Lists.swift:263-273`; `FinishShop` calls it, `Kitchen/Shopping.swift:60-67` | `softDelete` only sets `deletedAt`, `Engine/ObjectStore.swift:53-60`, so `checkedAt`, `shares` and links stay. No purge exists on master. But `objects(of:)` hides deleted rows (`ObjectStore.swift:82`), so the reader must include them |
| Removed without buying | `RemoveRecipeFromGroceries` deletes unchecked items, `Groceries.swift:250-255` | `checkedAt` is nil, so it never counts as a buy |
| Op log | `OpRecord` with `action`, `summary`, `createdAt`, `objectIDs`, `Model/Models.swift:496-540` | Backup source; the item rows are enough |
| Ingredient fields | `aisle` and `isStaple` only, `SystemCatalog.swift:220-225`. No `lastBoughtAt` | Name match is `IngredientLine.key`, `Kitchen/Quantities.swift:180-182`: lowercased and singular, so "semi skimmed milk" and "milk" are two ingredients |

**So a buy is:** a Groceries item (live or soft-deleted) with a `checkedAt`, linked to an ingredient, with at least one typed share (or no shares at all, for items added through `AddListItem` directly).

## 3. The rule (exact thresholds)

1. **Buy days.** For each ingredient group (see 5), take the dates of its buys. Buys less than 3 days apart merge into the first (a Saturday shop and a Monday top-up are one buy).
2. **Recipe-only buys don't count.** An item whose shares all name a recipe is skipped. It comes back with the recipe, not by habit.
3. **Enough history.** Look at the buys in the 56 days ending at the **last buy**. At least 3 are needed. Anchoring at the last buy, not today, lets a monthly item (every 28 days) qualify.
4. **Usual gap.** U = the median of the gaps between those buys, in whole days.
5. **Steady.** The longest gap is at most twice the shortest. With 4 or more gaps, the single longest gap is left out of this check (a week away doesn't break milk). Anything that fails is **irregular** and is never offered, however often it is bought.
6. **Due.** Days since the last buy is at least ceil(0.85 x U) and at most 2 x U. The 0.85 lets a shop a day early still count (U 7 gives 6, U 14 gives 12). Past 2 x U he has likely stopped, or buys it elsewhere, so it goes quiet.
7. **Not already there.** Skip it if an open or checked Groceries item already links any ingredient in the group.
8. **Once per gap.** When a shop run ends (`ClearDoneItems` on Groceries, which `FinishShop` also calls) while an item was shown and not bought, write `usualSkippedAt` on its ingredients. It stays quiet until the next buy. Swiping a name left (Design §R) writes the same field.
9. **Usually 4 names, never more** (ruled Oct 17), most overdue first (days since / U), then more buys in the window, then name.

This differs from backlog row R ("past 1.5x the median gap"). At 1.5x, weekly milk shows only after he has gone a whole week without it; the point is to catch it on the shop he is about to forget it. Proposal: replace R's 1.5x with rule 6.

## 4. Quantities

Ignore them for the rule. A buy is a buy, whether it was 6 eggs or 12. Don't stretch U by pack size: that is stock counting by the back door. A tap adds the text and quantity of the last typed buy ("12 eggs", or "2 l" on "milk"), so the list reads the way he writes it.

## 5. Name variants

Group key = `IngredientLine.key` after dropping a short list of describing words: `semi skimmed`, `semi-skimmed`, `skimmed`, `skim`, `whole`, `full fat`, `low fat`, `free range`, `organic`, `large`, `medium`, `small`, `fresh`, `salted`, `unsalted`. So "semi skimmed milk", "Milk" and "whole milk" are one group; "oat milk" and "coconut milk" stay apart because "oat" and "coconut" aren't on the list. The line shows the name he typed most recently. Ingredient objects are never merged; the group exists only inside the rule. Learned aliases are left out.

## 6. Where it shows, and Tess's words

- One line, last in the Groceries aisle window and in at-the-shop mode, never pinned, no space when empty. Design §R (branch `claude/project-thread-b3tu3f`, `docs/design/kitchen/kitchen-v2.md:84-88`) already draws it: labels at 55%, names at 21/400 and 55%.
- Text: **"Usually have: milk, eggs"**. Design's label reads USUALLY BY NOW; the Kitchen lead picks one. "Usually have" is a fact about him; "by now" sounds like a deadline, so this note leans "Usually have".
- Tap a name: it joins its aisle. Tess: **"Milk, in Groceries."** with Undo (same line as Design §R and the W slice).
- Swipe left: no words, it just goes (rule 7 of the voice guide: silence is fine).
- Ingredient page, one level down: **"Usually every 7 days. Last bought 9 days ago."** For irregular items: **"No usual rhythm yet."**
- Never: a notification, a badge, a Home offer, auto-add, red, "running out", "don't forget", "you should".
- Long-press why (context-packing §5): **"Bought 6 times in 8 weeks, about weekly."**

## 7. Fixture: 20 weeks (week 1 is Sat 2026-05-30)

Groups: milk (weekly, sometimes typed "semi skimmed milk"), eggs (2 weeks), bread (Saturdays plus Wednesday top-ups, irregular), bananas (weekly, stops after week 10), rice (4 weeks), coffee (3 weeks), yoghurt (weekly from week 11), lemons (recipe-only). "Typed" is what was on the list before the shop. The line is read when the shop starts.

| Wk | Shop | Typed before the shop | Expected line | He taps |
|---|---|---|---|---|
| 1 | Sat | milk, eggs, bread, bananas, coffee | none | |
| 2 | Sat | milk, bread, bananas, rice (+ bread Wed) | none | |
| 3 | Sat | milk, eggs, bread, bananas; lemons (recipe) | none | |
| 4 | Sat | milk, bread, bananas, coffee (+ bread Wed) | none (all due ones typed) | |
| 5 | Sat | eggs, bread, bananas (+ bread Wed) | Usually have: milk | milk |
| 6 | Sat | semi skimmed milk, bread, bananas, rice | none | |
| 7 | Sat | milk, bread, bananas, coffee (+ bread Wed) | Usually have: eggs | eggs |
| 8 | Sat | milk, bread, bananas; lemons (recipe) (+ bread Wed) | none | |
| 9 | away | no shop run | none | |
| 10 | Sat | milk, bread, bananas, rice | Usually have: eggs, coffee | eggs |
| 11 | Sat | milk, bread, yoghurt, coffee (+ bread Wed) | Usually have: bananas | |
| 12 | Sat | semi skimmed milk, eggs, yoghurt | none (bananas quiet) | |
| 13 | Sat | milk, yoghurt; lemons (recipe) | none | |
| 14 | Sat | milk, eggs, coffee | Usually have: rice, yoghurt | rice, yoghurt |
| 15 | Sat | milk | Usually have: yoghurt | |
| 16 | Sat | semi skimmed milk, eggs, yoghurt | none | |
| 17 | Fri | yoghurt, coffee | Usually have: semi skimmed milk | it |
| 18 | Sat | milk, eggs, rice, yoghurt; lemons (recipe) | none | |
| 19 | Sat | milk, yoghurt | none | |
| 20 | Sat | nothing | Usually have: coffee, milk, yoghurt | |

What each row proves: 5 and 7, a forgotten staple shows; 10, a week away (eggs at 21 days, U 14, ordered first); 10 to 11, coffee shown and not bought goes quiet, then a buy resets it; 11 to 12, bananas offered once then quiet, though still inside 2 x U; 14, rice qualifies on a 28-day beat and yoghurt appears after its 3rd buy; 15 to 16, yoghurt quiet after one refusal; 17, a day early still counts (6 days, U 7) and the line uses the latest typed name; 20, four are due (eggs too) and only three show, coffee first at 22 days over U 20.5. Bread and lemons never appear. Checked with a 70-line script against rules 1 to 9.

## 8. Leave out

Expiry dates, stock counts, "how much is left", pack sizes, use rates from cooking, prices, store choice, learned name aliases, a pantry screen, `Ingredient.state` (that is slice P), notifications, Home offers, Shortcuts or widgets.

## 9. Smallest slice: U0 "Usually have" (Core engine, then a small change to sheet 13)

- `GroceryHistory.buys(store:classes:)` reads Groceries items including soft-deleted ones, per section 2.
- `GroceryHistory.usual(at:)` returns up to 3 `(name, quantity, ingredients, why)` by rules 1 to 9.
- `Ingredient` gets `usualSkippedAt` (`.date`). `ClearDoneItems` on Groceries writes it for shown, unbought groups; `SkipUsual(ingredient:)` is the swipe. Both undoable.
- `CheckListItem` takes an optional `time` (defaults to `AppClock.now`) so fixtures and `-demoTime` work.
- The tap reuses `AddGroceries(lines:)`.

**Done when:**
1. The 20-week fixture above passes in `swift test` row by row, on a pinned clock.
2. A cleared, soft-deleted item still counts as a buy; an item removed with its recipe does not.
3. Recipe-only items (lemons) never appear; an item with one typed share among recipe shares does count.
4. "semi skimmed milk" and "milk" form one group; "oat milk" doesn't join it.
5. Two buys 2 days apart count once; 3 days apart count twice.
6. Due, but already on the list (open or in the basket): not shown.
7. Shown, then the run ends without it: quiet until the next buy; undoing the clear undoes the quiet.
8. Usually 4 names, never more than 4; the line is empty, and takes no space, with fewer than 3 buys.
9. No code path adds an item without a tap; grep the slice for `AddGroceries` callers.
10. Groceries screen: the line shows at the foot, the tap says "Milk, in Groceries." with Undo, and `-demoTime 18:10 -resetDemo` shows a demo row with one name.

## Outside sources

- Bhagat et al., "Buy It Again: Modeling Repeat Purchase Recommendations", KDD 2018 (Amazon): repeat items are offered by their own purchase interval, and items with no steady repeat pattern are kept out ([PDF](https://cdn.amazon.science/40/e5/89556a6341eaa3d7dacc074ff24d/buy-it-again-modeling-repeat-purchase-recommendations.pdf)).
- Target Tech, "Buy it again" (two parts), on the same feature for repeat grocery buys ([part 1](https://tech.target.com/blog/buy-it-again), [part 2](https://tech.target.com/blog/buy-it-again-part-2)). Not re-read in detail today.
- Both use models fitted on millions of baskets; for one person a median and a steadiness check are enough and can explain themselves.
