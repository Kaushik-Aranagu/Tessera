# Kitchen v2 scope: the Oct 22 pick, drafted ahead

*Kitchen lead, 2026-10-16. Kaushik's first kitchen week started Oct 15. This page turns `kitchen-week-one.md` (what to read) and `kitchen-v2-backlog.md` (what could be built) into the one message Product sends him on Oct 22, with the cut already ranked so his three one-word answers settle it. Numbers get filled in from his data on the morning of Oct 22; nothing here needs him before then.*

## Where v1 stands (master 73a734d)

| Slice | State |
|---|---|
| Recipes, paste, Groceries, US shop, timers, cook log | Shipped, in his hands since Oct 15 |
| Recipe from a link, L1-L3 | Shipped (078cb54): card, page text, Claude when he lets Tess ask |
| Capture-miss log, `Recipe.lastOpenedAt` | Shipped (2537cad), so week one's "recipes opened but never cooked" row reads from data |
| Cook mode 12 and 12b | Builder A, against `cook-mode-acceptance.md` |
| Meal plan feeds groceries | Core, against `meal-plan-groceries-acceptance.md` as amended Oct 16 (rows land on planning) |
| Groceries with Tess (AI-12): link ask, USUALLY, Home count | Spec'd (`groceries-ai-acceptance.md`); Core then Builder B after Return, Review 46 and AI-1 |
| Lists 9-12 | Builder B after its Home work |

So by Oct 22 the backlog's **Running low by rhythm** (R) and **Week of dinners** (the dated cooks plus the Home count) are already on their way inside AI-12 and the meal plan. v2 picks from what's left.

## The Oct 22 message (Product sends; fill the brackets from the data)

> Kitchen week one: you saved [n] recipes ([p] pasted, [l] from links, [g] typed), cooked [c] times ([t] timers, [e] stopped early), and shopped [s] times with [i] items ([r] from recipes, [y] typed). Three questions, one word each:
> 1. Did you ever want to know whether you already had something at home? (yes / no)
> 2. Did you fix a recipe after saving it, or want to? (yes / no)
> 3. Was there a kitchen moment you reached for something else instead of Tessera? (name it / no)
>
> My pick for the next kitchen slices is below; your answers can swap the order.

Question 2 replaces week one's old question 2 (links), which the data now answers on its own.

## How the answers set the cut

| Signal | Reads from | Pulls forward |
|---|---|---|
| Q1 yes | his word | **P. Pantry light** (engine only, no screen), then **W. CAN COOK** |
| Q1 no, but typed staples are more than a third of items | item shares with no recipe, `isStaple` | Nothing new: R inside AI-12 covers it |
| Q2 yes, or the re-parse diff shows corrections on more than 1 in 3 pastes | `sourceText` re-parse against saved lines | **Recipe edit in place** (same paint-over surface) |
| Timers stopped early on more than 1 in 4 cooks | `stopKitchenTimer` against `endsAt` | **12b pause and extend** stays in cook mode's scope; nothing else |
| Cooks started but no cook finished in mode | ProcessTable `endReason` | Cook mode's idle rule gets re-checked before anything is added to it |
| Cook notes written | Notes with @recipe | **Cook notes into the recipe** (small, Core) |
| Q3 names the clock app | his word | **Hands-free cook mode** moves up; otherwise it stays Later |
| Q3 names paper or Messages for the list | his word | At-the-shop mode gets a review before any new slice |
| A shop whose check-off order fought the aisle order | check-off order against walk order | **Store-specific aisle order**, only if he names it |

## The default cut, if he answers nothing

In order, each its own small PR, engine first:
1. **Recipe edit in place.** Corrections are the one thing every paste week shows, and the surface exists.
2. **P. Pantry light**, engine only: `Ingredient.state` and `lastBoughtAt` from shop clears, `FinishCooking` and "out of milk". It shows only as the dim out line on the recipe page and the state sentence on the Ingredient page.
3. **W. CAN COOK** on the shelf, off by default, "1 to check" for unknowns, after P.
4. **Cook notes into the recipe.**

Not in v2 unless he asks: leftovers and cook double, recurring groceries (USUALLY covers the need), share extension (needs a paid account), nutrition.

## What I'll do on Oct 22

Pull the numbers with the week-one reads (op log and store, on master), fill the brackets, and send the message to Product by 9 AM Pacific with this page's default marked as the recommendation. Then write the acceptance page for whichever slice goes first, the same day.
