# Pantry area: defaults and acceptance (kitchen v2, after a week of real v1 use)

*Kitchen lead, 2026-10-16, drafted ahead. Kaushik (Oct 16) wants a Pantry area that knows what he has, feeds Groceries and Recipes, and lets the ingredient peek show need against have; Product places it as the home for the held R (usually have) and P (pantry light) slices, after a week of Kitchen v1, not in the next builds. Engine rules come from Research's `docs/research/pantry-light.md` (rules 1-9), Design's `kitchen-v2.md` §P, §R, §W, and `kitchen-v2-backlog.md` ("Pantry area"). The screen rows wait for Design's sheet; the engine rows do not.*

## The one rule

The phone infers what he has from what it already sees: shop clears, finished cooks, and what he tells Tess. It never counts, never asks, never guesses a quantity, and never sends any of it to Claude (body facts and pantry facts stay on the phone). An unknown is shown as unknown.

## Engine (Core), in order

**P. State.** `Ingredient.state` (in, low, out, unknown) and `lastBoughtAt`, set by:
- a shop clear (`ClearDoneItems` on Groceries): every checked item's ingredient → in, `lastBoughtAt` = the check date;
- `FinishCooking`: each non-staple ingredient the recipe used → low; fresh produce and herbs (the Produce aisle) → out; staples untouched;
- "out of milk", "no more rice", "we're out of eggs" → out, and the row goes onto Groceries with the last typed amount (one op, one UNDO, "Milk, out. On Groceries."); "have rice", "got milk" → in;
- tapping the state word on the Ingredient page cycles in → low → out, undoable.
Unknown is the state of every ingredient until one of these happens. State never changes by time passing.

**R. Usually.** As `groceries-ai-acceptance.md` §4 and Research rules 1-9 with the cap at 4; unchanged by this area except that the same names also show in the Pantry area's USUALLY line. `usualSkippedAt` stays the quiet rule.

**W. Can cook.** `RecipeMath.missing(recipe)` counts non-staple lines whose ingredient is out or unknown, ties by not cooked lately; "0 missing", "1 missing: lemons", and an unknown reads "1 to check: lemons" (opens the Ingredient page, never adds). CAN COOK replaces FROM THE BASKET on the shelf, off by default (decided 2026-10-15).

**Feeds.**
- Groceries: an out line is offered as a ghost row from the Pantry area's key (ADD N TO GROCERIES, dry run of the same add as the recipe peek), never auto-added; planning a recipe skips lines whose ingredient is in (a new cover rule, after the covered row and the checked row), and still adds low and unknown ones.
- Recipes: the ingredient peek (Design 69) reads need against have per line, state words only: "have" at 42%, "low" and "out" in ink; "used" during a cook; with no state the row carries no value. The key adds only out, low and unknown lines ("ADD 2 TO GROCERIES", "Chicken, 2 added.").
- The recipe page's out lines drop to 400 weight at 55% with the faint ring (Design §P); low and unknown show nothing there.

## Defaults taken

| Point | Default |
|---|---|
| Where it opens | A word on KITCHEN under Groceries, "Pantry", and by asking Tess "pantry" or "what do I have". Back word ‹ KITCHEN. |
| What it shows | A counts line ("4 out, 2 low"), then ingredients grouped by state (out, low, in) and inside a state by aisle in the shop's walk order, each as one plain line with the name and, for in, when it was bought ("bought Sat"); unknown ingredients are not listed (they are the long tail). USUALLY at the foot as on Groceries. Tess's band. |
| Nothing known | The page shows the counts line as "nothing known yet" and one line: "Clear a shop or finish a cook and this fills in." No empty-state art. |
| Tap | A line opens the Ingredient page (state sentence, cycle). |
| Swipe | Left on an out or low line adds it to Groceries as a ghost row ("Milk, on Groceries." UNDO 4 s). No remove: the area is a view, not a list. |
| Notifications | None, ever. No badge, no Home offer, no Live Activity. |
| Claude | Nothing leaves the phone. |

## Done when

**Core**
1. `swift test`: a shop clear with 3 checked items sets their ingredients to in with `lastBoughtAt`; `FinishCooking` on the tacos sets chicken, onion and tortillas to low and cilantro and limes to out; staples untouched.
2. "out of milk" sets milk to out and adds "milk" (last typed amount) to Groceries in one undoable op; "have rice" sets in; UNDO restores both.
3. The Ingredient page cycle writes one op per tap and UNDO reverses it.
4. Planning a recipe skips an in line and adds low and unknown ones; the peek's dry-run count matches the rows added (on `research/fixtures/recipe-clock-steps.md` D1 Paprika chicken with the list empty and states chicken thighs in, lemon low, Greek yogurt out, the rest unknown: the peek reads "have", "low", "out" on those three lines, and the key gives "ADD 6 TO GROCERIES", every line but the chicken).
5. `RecipeMath.missing` gives 0, 1 and "1 to check" for the three seed cases; CAN COOK ranks by missing then not-cooked-lately.
6. Research's 20-week fixture still passes with the cap at 4 (R unchanged).
7. The pack snapshot for AI-12 holds no state and no `lastBoughtAt` (nothing new leaves the phone).

**Builder B** (after Design's sheet; recording `docs/recordings/pantry.mp4`)
1. Pantry opens from KITCHEN and from "pantry" to Tess, with the counts line and the grouped lines; nothing under 16 pt, no cards or pills.
2. A shop clear and a finished cook change the counts line and move lines between groups with the house dry.
3. The peek on three seed recipes reads have / low / out per line and the key's count matches.
4. "nothing known yet" state; Reduce Motion crossfades; Dynamic Type one column.

## Screen rows: the Pantry front and index (Design sheet 78, Kitchen lead 2026-10-17)

*Rows for Builder B, one per state of the front. Where this page's Defaults table above and sheet 78 differ, the sheet wins: the front groups OUT, LOW, USUALLY HAVE (not an IN group); "bought Sat" lives on the side's lines; the empty and quiet words are "Nothing yet" and "Nothing out". The side (OUT AND LOW) is `kitchen-sides-acceptance.md` section 6, rows 6.1-6.8. Nothing here shows or sums nutrition (`never-sums-audit.md` N6).*

| # | State | Pass when |
|---|---|---|
| S1 | Front, things known | Frame as the other areas: PANTRY at 52, the weekday at 138, the context line "since Saturday's shop" at 186 with the side word OUT AND LOW at its right, the hero at 212. No title and no back word (a tab-level area). Groups OUT, LOW, USUALLY HAVE from 296, labels at 13/700. No card, pill or badge, nothing under 16 pt, nothing red |
| S2 | Hero | Digits: "4 out, 2 low". It is also Pantry's line on the index and Home, the same string. 1 out reads "1 out", never "1 outs" |
| S3 | Out line | One Body 21 line, 40 pt pitch: name in ink, state word "out" at the right (700, pantry colour mixed 72% with ink), the faint ring (11 pt, 1.3 pt stroke, ink 42%) at x 6. The recipe page's out line uses the same ring |
| S4 | Low line | Same line with "low" (600) and no ring |
| S5 | USUALLY HAVE, 1 to 4 names (ruled Oct 17: shows 4) | The names as is on one line ("Rice, coffee, eggs"). Under it nothing else. Tapping a name joins Groceries: "Milk, on Groceries." with UNDO 4 s (a new add); a left swipe skips it until its next gap (`usualSkippedAt`) |
| S6 | USUALLY HAVE, 4 or more | "Rice, coffee and 2 more": two named, then the count; "and 2 more" at 55%. Cap 4 holds (Research rules 1-9) |
| S7 | State-word tap | Cycles in, low, out, in. One `.selection`, one op, one UNDO of 10 s (a change; 10 s under VoiceOver). The receipt names the thing first, "Limes, in.", in the one app-wide UNDO slot, replacing Tess's line for its window; UNDO restores the row and her line returns. The hero's digits just change, nothing counts up. The line closes up in 320 ms |
| S8 | Row leaves and joins | A line that becomes in leaves the front (in things are the long tail and show only on their Ingredient page). A line that becomes low or out joins that group. A group with no lines is not drawn, not even its label |
| S9 | Tap a name | Opens that ingredient's page (state sentence, cycle, PER 100 G side). Back lands on the same scroll position |
| S10 | Left swipe on an out or low line | Adds it to Groceries as a ghost row, receipt "Milk, on Groceries." with UNDO 4 s (a new add). A line already on Groceries is not added twice; the receipt then reads "Milk, already on Groceries." and there is no UNDO. In and USUALLY HAVE names are not swiped here (S5) |
| S11 | Nothing out | Known state, none out or low: hero "Nothing out". Groups OUT and LOW are not drawn; USUALLY HAVE still shows if it has names. The side reads "Nothing out." with no key (K26.9; row 6.4 is the nothing-known side) |
| S12 | Nothing known | Hero "Nothing yet" and, under it at 55%, "Clear a shop or finish a cook and this fills in." No art. Tess: `Say "out of milk" and I'll keep it.` Index line "Nothing yet". Never "0 out, 0 low" |
| S13 | Tess's line | The only thing in 736 to 820. After a cook it is the phone's fact, "Tacos took the cilantro and limes." (the names `FinishCooking` set out or low). Never a notification, a badge, a Home offer, "running out" or any forecast. Tess's line and Home never disagree: Home's Pantry line is the hero verbatim |
| S14 | Index, five rows | REVIEW, TODAY, TRAINING, KITCHEN, PANTRY at a 104 pt pitch from 96; glass 700 tall, hint at 652, ending above Tess's band at 736. KITCHEN's line reads "Tacos, 7 pm" (no "at" before a time). Under the finger Pantry's word takes the pantry colour, scaled 1.06 |
| S15 | Walls | A private or secret-looking ingredient name never appears: the line reads "Private item" and is not tappable into its words (`product-decisions-walls.md`). No Pantry fact is sent to Claude (Core row 7) and no receipt, line or widget carries money or body words |
| S16 | Reduce Motion, Dynamic Type, VoiceOver | Reduce Motion: a 150 ms crossfade through MotionPolicy for the side and the index, no spring. AX sizes: one column, the state word under the name, nothing clipped. VoiceOver (proposed wording): "Limes, out", the cycle as the default action and "Add to Groceries" as a custom action in place of the swipe |
| S17 | Pantry colour | Ochre (Porcelain #A4601A, Obsidian #E3A857) appears only on state words and the index row. Cobalt stays Tess's voice only; a test or grep of the theme tokens finds no other use |

**Recording:** `docs/recordings/pantry.mp4` shows a shop clear moving lines to in, a finished cook adding out and low lines, a state-word tap with UNDO, and the nothing-yet state (as in Builder B's done-when 1-4 above).

**Open, default taken:** S10's "already on Groceries" receipt wording is Kitchen's; Design confirms it with the next copy pass. Sheet 78 says nothing on it.

## Open questions, defaults taken

1. Does "in" expire (milk bought three weeks ago)? DEFAULT: no; a state only changes on an event, and USUALLY already says what is probably gone.
2. Does cooking set low or out for pantry goods (rice, pasta)? DEFAULT: low; only produce and herbs go out.
3. Is a planned recipe's in line skipped or shown as covered? DEFAULT: skipped silently, like a staple; the peek still shows it as "have".

*Receipt preposition ruled by Product (decisions 10:06, Oct 16): "on" everywhere, "Milk, on Groceries." Design sheet 78's "in Groceries" is superseded; Builder B matches the rows above.*
