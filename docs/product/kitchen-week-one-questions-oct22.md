# Kitchen week one: the three questions for Thursday Oct 22

*Kitchen lead, prepared Sun Oct 18 (PDT). Docs only, no code, nothing run: no Swift toolchain here, and the counts below are the labels `scripts/kitchen-week-one.py` prints, read from the script, not from his data. The day it runs is Thu Oct 22: counts at 8 am PDT, message to Product by 9 am PDT, as `kitchen-v2-scope.md` says. The three questions are the ones in `kitchen-week-one.md`; the cut they set is the answer-to-slice table in `kitchen-v2-scope.md` ("How the answers set the cut"). Where a ruling since Oct 16 changes that table, the line below says so. No key or key-shaped text appears in this page or in the counts.*

**How to run the counts.** Copy `tessera.sqlite` (or a `.tessera` backup) first, then `python3 scripts/kitchen-week-one.py <copy>`. Add `--since 2026-10-15` for the week. It reads only the classes it needs and prints no title unless `--titles` is given; a private title then prints as "Private recipe". Never point it at the live store.

**Rules for the message.** One word per answer. Each option is a short line with a small picture beside it (Design draws it; the picture hint is in the first column), never a bare letter. One option per question carries the mark "Our pick". Counts go in the brackets of the Oct 22 message; no title, no price, no private word appears in it.

---

## Question 1: Did you ever want to know whether you already had something at home?

Plain words for him: "Standing in the kitchen or the shop, did you wonder if you had it already?"

| Picture hint | Answer (one word) | What it sets |
|---|---|---|
| An open fridge door with a question mark | **Yes** | Pantry v2 goes first and the CAN COOK shelf follows it (scope table, Q1 yes: P, then W). Pantry v2 is already ruled (R1 to R20, 4:30 pm Oct 17) and its 24 PE rows are acceptance, so Yes sets how soon, not whether |
| A full shelf with a tick | **No** | Pantry v2 keeps its place behind the cut below; nothing is pulled forward. If typed staples are over a third of his grocery items the scope table still sends nothing new (running-low-by-rhythm inside the Groceries asks covers it) |
| A shrug | **Not sure** | Treated as No, and the counts below decide |

**Our pick:** "Yes" is not ours to choose for him. The pick is on the cut: if he says nothing, the default cut stands (recipe edit in place first, then Pantry v2, then CAN COOK, then cook notes).

**Counts it will be answered from** (script lines, exact labels):
- `Grocery items: N (R from recipes, T typed, S typed staples)`. S over N/3 is the scope table's "typed staples are more than a third of items" row; it makes Yes look likely and No unlikely to change anything.
- `addGroceries by actor: ...`: how many were typed by hand against Tess grammar.
- `Item check/uncheck ops: N`: items struck then unstruck. Any above 0 are read by hand as misreads.
- `Shops: N started with the title hold, N finished`.
- Pantry itself is not counted by the script (there is no state to read until v2 lands). Say so in the message if he asks.

**Wired to the scope.** Q1 yes: "P. Pantry light, then W. CAN COOK". Q1 no with S over a third: "Nothing new". The scope page still calls Pantry "engine only, no screen"; since then the Pantry page shipped (#724, #727) and v2 state is spec'd, so read "P" as "Pantry v2 state" (`kitchen-pantry-v2-acceptance-pe.md`).

---

## Question 2: Did you try to save a recipe from a website?

Plain words for him: "Did you try to put a recipe in from a web page or a link?"

| Picture hint | Answer (one word) | What it sets |
|---|---|---|
| A web page with a recipe card | **Yes** | Read the link counts below first. If a link failed, the link reader's error lines get a review before any new slice (ER1 and ER5 keep the tap-only rule). If every link worked, nothing moves: link fetch already shipped (L1 to L3, 078cb54) |
| A hand pasting text | **No** | Nothing moves. The paste screen is the only route he used |
| A camera over a printed page | **Photo** | Photo import (K43) goes into the review pile instead of a new slice |

**Our pick:** "Yes" or "No" both leave the default cut as it is; the pick is **no new slice for this question** unless the capture-miss count below shows links that failed.

**Counts it will be answered from:**
- `Capture misses: N (by source; K were links)`: K is links he pasted that ended with nothing written. This is the only place a failed link shows; the script prints "no capture-misses.jsonl beside the store" when the log was not copied with the store, and then K is unknown (say so, do not guess).
- `Recipes saved: N (G ghost row, P pasted or from a link, O other)`. A link recipe is saved as text and the store keeps no URL, so paste and link cannot be told apart here (comment in the script). K above is the only link count.
- `Recipes opened but never cooked: N`: context for the shelf, not for this answer.
- `Recipe edits after saving (editRecipe ops): E`: see the note below.

**Wired to the scope, and one conflict to settle.** The scope page's own question 2 is "Did you fix a recipe after saving it, or want to?" (it replaced the links question because the data now answers links). This pack asks the website question as the Kitchen lead was told. Product picks one of two ways before Oct 22: (a) ask the website question here and read the "fixed a recipe" signal from E (scope row: edits on more than 1 in 3 pastes pulls **Recipe edit in place** forward), or (b) ask the scope's question 2 and read links from K. Recommended: (a), because E and K both come from data, so neither needs a spoken answer.

---

## Question 3: Was there a moment in the kitchen when you reached for something else instead of Tessera?

Plain words for him: "Did you ever pick up something else, a clock, paper, a message, instead of the app?"

| Picture hint | Answer (one word) | What it sets |
|---|---|---|
| A phone clock face | **Clock** | Hands-free cook mode moves up (scope table: Q3 names the clock app) |
| A paper list | **Paper** | At-the-shop mode gets a review before any new slice |
| A speech bubble | **Messages** | Same as Paper: the shop mode review |
| A tick in a circle | **Nothing** | Nothing moves; the cook-mode idle rule and timers are judged on the counts |
| A pencil | **Other** (he says what) | Product reads it and rules; no slice is pulled forward on a guess |

**Our pick:** **Nothing** is the expected answer and changes nothing. The counts decide the rest.

**Counts it will be answered from:**
- `Cooks: S started, F finished; cook processes by end: ...`: started but not finished, and how they ended. Cooks started with no cook finished in mode means the idle rule is re-checked before anything is added to it (scope row).
- `Timers: T (E stopped early); per cook: ...`: E over a quarter of cooks keeps 12b pause and extend in cook mode's scope and adds nothing (scope row).
- `Shops: N started with the title hold, N finished` and `Item check/uncheck ops`: a shop never started with the hold, with items struck at home instead, points at the same shop mode review as Paper and Messages.
- `Planned cooks (tasks linking a recipe): N, of which cooked: C`: whether the plan fed the cooking.
- The capture-miss log by source (`ghost row` or paste screen): a spoken or typed phrase that missed during a cook is the clock-app signal the answer should be checked against. Cook phrases stay on the phone and are not logged (4:10 pm and 3:38 pm rulings), so a quiet log in cook time does not mean no misses.

**Wired to the scope.** Q3 names the clock app: "Hands-free cook mode moves up; otherwise it stays Later". Q3 names paper or Messages: "At-the-shop mode gets a review". The aisle-order row (check-off order against walk order) is not asked; it reads from data only if he names it.

---

## The message, filled from the counts (Product sends)

> Kitchen week one: you saved [n] recipes ([p] pasted or from links, [g] by ghost row), cooked [c] times ([t] timers, [e] stopped early), and shopped [s] times with [i] items ([r] from recipes, [y] typed). Three questions, one word each:
> 1. Did you ever want to know whether you already had something at home? (Yes / No / Not sure)
> 2. Did you try to save a recipe from a website? (Yes / No / Photo)
> 3. Was there a moment you reached for something else instead of Tessera? (Clock / Paper / Messages / Nothing / Other)
>
> My pick for the next kitchen slices is below; your answers can swap the order.

**Default pick if he answers nothing** (unchanged from `kitchen-v2-scope.md`, with the Pantry wording updated): 1 Recipe edit in place; 2 Pantry v2 state, no screen first; 3 CAN COOK on the shelf, off by default, "1 to check" for unknowns; 4 Cook notes into the recipe.

## What could not be grounded

- No counts exist yet; every number is a label, not a value.
- The scope page's question 2 and this pack's question 2 differ (see Question 2); Product has to choose.
- "Not sure", "Photo" and the picture hints are proposals; nothing rules them. The scope page asks for yes / no and "name it / no".
- The script lines were read from `scripts/kitchen-week-one.py` on origin/master; the capture-miss log is read only when it sits beside the store.
