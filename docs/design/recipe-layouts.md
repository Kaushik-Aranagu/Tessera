# Three recipe layouts (Design item 45)

**Kaushik's principle, in one line:** the recipe page should be more than a list with a button; show him a few real layouts of a real recipe and let him pick.

From his first review of the build (16 Oct, 11:58 PM PT): Recipes is basic, show a few layout examples. Three distinct layouts of one US recipe (sheet-pan paprika chicken with sweet potatoes, serves 4, 45 min, `us-shop.md` units), each in Porcelain and Obsidian with the item-43 tokens. All three keep what's settled: ‹ RECIPES, Title 44, the ink-line COOK word with its minutes, tap the name for the pasted text and history, swipe the ingredients left to send them to Groceries, Tess beside the soul, the portion drum's rounding (`us-kitchen-pages.md`).
- Board: `mockups/recipe-layouts.png` (source `studies/recipe-layouts.html`).
- Recording: `recordings/recipe-layouts.mp4` (12s). A: the serves word turns 4 to 6 and every amount rolls inside the prose. C: tap COOK, the clock starts and the now mark walks down the time stroke.

## A · The prose
The method is the ingredient list. There is no list: each step is a paragraph at Body 21, and every amount sits inside it as a value word (600): "Rub **1½ lb** chicken thighs with **1 tbsp** olive oil, **1 tsp** smoked paprika and **½ tsp** salt."
- The line under the name: "serves **4** · 45 min · cooked 12 days ago". The serves word is the drum: tap it and it opens in place (3 and 5 at 30% beside it), swipe to turn, and every amount on the page rolls (220ms, 15ms stagger). No separate drum column.
- Shopping: swipe left anywhere on the paragraphs and the amounts lift out of the prose and fly off left to Groceries, as a column. Tess: "Added 7 to Groceries." with UNDO.
- Cook mode (sheet 12) steps through the paragraphs, one per screen, as it does now.
- It needs the parser to know which step each ingredient belongs to (Core: `RecipeParser` matches amounts to the step that names the ingredient; a pasted recipe that lists ingredients separately is rewritten into its steps, with any unplaced ingredient in a last line "Also: **1** lemon, a handful of parsley").
- Reads like a cook wrote it, and it is the one layout that is pure words. A long recipe is a long page, which is fine; it scrolls.

## B · Two columns
The whole recipe on one screen: ingredients down a 150pt left column at 16pt (amount 600, name 400), a hairline, and the numbered steps down the right at 16pt. SERVES **4** heads the left column and is the drum.
- Nothing scrolls for a recipe of up to 9 ingredients and 4 steps; longer ones scroll both columns together.
- The densest of the three. It's the one that looks most like a recipe card, and at 16pt it's the hardest to read at arm's length on the counter.
- Needs nothing new from Core.

## C · The clock
y is time. A vertical ink-line stroke runs from 0 to 45 min, and each step sits at its minute with the ingredients it uses under it, so the page says what to do when: "0 Oven 425°F, potatoes on", "5 Chicken in, on the pan", "10 Roast", "45 Lemon over, parsley, serve".
- Steps get at least 90pt each, and the long spans (the roast) take the rest, so the stroke is time with a floor.
- **COOK starts the clock on this page.** The stroke wets from the top in `now`, the now mark walks down it, the current step's minute turns `context`, and the word becomes STOP with "33 MIN LEFT". Tess: "Roasting. 33 min to go." Timers come from the stroke itself: a step with a duration is its span. There's no separate cook mode screen; sheet 12's timers, hold and finish fold into this page running. Lock Screen and the Dynamic Island keep the cook Live Activity.
- Shopping: swipe left on the ingredient lines, as today.
- Needs from Core: a start minute per step as a running sum of the durations the parser already reads. Kitchen's defaults, which the clock draws without trouble: an untimed step is 0 minutes wide, so it sits at the same minute as the step after it and the 90pt floor stacks them in order; a "meanwhile" step starts with the step before it, so it sits under that step at the same minute with the word "meanwhile" at 14 `inkSecondary` in place of its minute, and the stroke doesn't advance between them.

## Recommendation
**C, the clock.** It's the one layout that makes the page do something a paper recipe can't: it tells him what to do when, which is the part of cooking that's hard, and it turns the recipe page and cook mode into one page, so there's one screen less (the screen is the resource). It's also the most Tessera: y is time, as on the Day log and the day strip.

A is the runner-up, the best page to read and the most "his words". B is the fallback if he wants everything at a glance and nothing new built.

## After he picks
- Builder B and the Kitchen lead build the pick as sheet 10's replacement; the sheet gets a pointer line.
- If C: cook mode (sheet 12) becomes C running; Design redraws the cover's timers and finish on this page.
- If A: Core's parser change first; B needs no Core work.

## His pick (Oct 16, 9:47 AM PT)
C, deepened, with B's list as a peek: `recipe-clock.md` (Design 69) is the build sheet now. A is out.
