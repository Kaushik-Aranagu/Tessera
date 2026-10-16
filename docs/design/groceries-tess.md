# Groceries with Tess (Design item 47)

**Kaushik's principle, in one line:** Groceries should sort itself, know which meal each thing is for, suggest what he usually runs out of, and remind him, without ever nagging.

The surfaces for the AI thread's "Groceries that know your recipes" (`docs/ai/first-features.md` section 3, as corrected with the Kitchen lead on 16 Oct): the phone sorts and works out a planned meal's missing lines; Claude's one job is matching a row to a recipe's ingredient by name; "usually" comes from his own check-off history; and reminding is the planned cook's Home line, never a notification (Product, 12:17 AM PT). This sheet redraws Groceries (`kitchen/13-groceries.md`, `kitchen/us-shop.md`) under today's rules and adds the four moments. At the shop (hold the title) is unchanged.
- Board: `mockups/groceries-tess.png` (source `studies/groceries-tess.html`), Porcelain: sorted, Claude's ask, the ghost rows, a usually word flying, and Home carrying the count.
- Recording: `recordings/groceries-tess.mp4` (11s). The ask, KEEP drying the link in, the tacos' two missing lines landing as ghost rows, and Oat milk flying from USUALLY into Dairy and eggs.

## The page under today's rules
| y | Element |
|---|---|
| 58 | ‹ KITCHEN, the back word (Groceries is one tap from the KITCHEN tab) |
| 84 | Title 44 "Groceries". Hold it to start shopping, as before |
| 140 | Body 21 `inkSecondary`: "9 to get, for tacos and two more". Not a context line (it sits under a title, not over a hero) |
| 200 to 640 | **The aisle window**, fading out over its last 50pt. Aisle words at Title 34 (ink 85%), items at Body 21 hanging from x 64 (amount 600, name 400), in the `us-shop.md` walk order |
| 664 | **USUALLY**: a Label 16 `inkSecondary`, and under it a line of ink words at Body 21/600 at 70% ("Oat milk  Bananas  Coffee") |
| 736 to 820 | Tess beside the soul, with her words under her line |

- **No dots.** The sage dab at a row's trailing edge goes (`no-dots.md`). A row that's for a recipe says so in a small line under it at 16 `inkSecondary`: "for tacos", "for tacos · 15 oz" when there's a pack size. The hold-to-see line from sheet 13 is no longer needed.
- **The basket fold** stays at the foot of the window (y 640 to 684 when something's in it), and USUALLY sits under it; with a basket the window shortens by 44.

## 1 · Sorted on the phone
As built (`Aisles.swift`). A typed item lands in its aisle as a wet cobalt ghost row and dries over 2s (sheet 13). Nothing new on screen; Claude never sorts. If Claude's name match teaches the phone an aisle, the row simply moves there on the next add, no line said.

## 2 · Claude's link is one ask
When Claude proposes that a row is a recipe's ingredient ("scallions" for the tacos' spring onions), it arrives as one ask in Tess's line (`one-ask.md`): "Scallions, for the tacos?" with **KEEP** and **NOT NOW** as ink words under it, KEEP first. The row itself shows a wet cobalt "for tacos?" line under it while the ask is open.
- **KEEP:** the "?" goes, the line dries from cobalt to `inkSecondary` over 900ms, Tess says "Scallions, for the tacos." and nothing else. That's the link written. UNDO under her line for 10s.
- **NOT NOW:** the wet line fades (300ms) and the ask leaves. Claude doesn't propose that pair again for the planned week.
- One ask at a time; a second proposal waits for the first. Never during shopping (the hold-the-title mode), never in a workout.
- Claude's ask never adds a row, never changes an amount, and shows nothing the phone didn't already have on the page.

## 3 · The planned meal's missing lines are ghost rows
When a recipe is planned (meal plan slice) the phone works out its lines not on the list and not staples (`AddRecipeToGroceries`). They land as wet cobalt ghost rows in their aisles, each with "for tacos" under it, flying in from Tess's corner 60ms apart (the sheet 13 arc) and drying to ink over 1.4s after they land. The rows below make room first (320ms). Tess: "Added 2 for tacos." with UNDO. The line under the title rolls to the new count.

## 4 · Usually
A line of ink words at the foot, from his own history: the things he checks off most weeks that aren't on the list now (at most 4, the phone's `checkedAt` rule). Tap a word: it wets in cobalt, flies to its aisle as a ghost row (520ms, house curve) and dries; Tess: "Oat milk, in Dairy and eggs." with UNDO; the word leaves the USUALLY line and the others close up. No "add" verb, no plus. When nothing qualifies, the label and line aren't there.

## 5 · The reminder is the Home line
Groceries never notifies. On the day of a planned cook, the cook's Home line carries the open count through `HomeLines`: context "2 to buy" over the hero "Tacos tonight", with **GROCERIES** as the ink-line key under it (it opens this page). When everything's in, the context line is the time again ("tonight") and the key reads COOK. No count ever appears in a badge, a dot or a notification.

## For Builder B and the Kitchen lead
- `GroceriesView`: the back word and Title 44 top, the recipe line under a row (replacing the trailing dab and the hold reveal), the USUALLY line and its flight, the ask line through the one-ask slot.
- Core: `usuallyOutOf()` from `checkedAt` history; the planned meal's missing lines on planning; the KEEP write (`linkItems` ghost kept) and the NOT NOW memory for the week.
- AI thread: the ask's words come from the phone ("{row}, for the {recipe}?"); Claude supplies only the pairs.

## Owners
- **Builder B:** the page and the four moments.
- **Core / Kitchen lead:** the rules and the link write.
- **AI architecture:** the `linkItems` call and its gate.
