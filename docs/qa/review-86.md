# QA: recipe page and paste a recipe, PR #86 (head 25ab380)

*Repo maintainer (QA), 2026-10-15 19:10 UTC. Static read of the diff plus a contact sheet of `docs/recordings/13-recipe-and-paste.mp4`. The screens are reachable only through DEBUG launch arguments, so nothing here touches the phone build until the KITCHEN rail is wired.*

**Verdict: OK to merge after the install. Fix R1-R3 before the screens are reachable from Home.**

## Bugs
- **R1. Adding a recipe twice doubles the groceries.** `RecipePage.sendGesture` runs `AddRecipeToGroceries` every time, and `addGroceryShare` (`Groceries.swift:148-150`) appends another share for the same recipe, so the second swipe (the column comes back after 4 s, or on a later visit) sends 600 g instead of 300 g. The new `Groceries.share(of:)` isn't used by the page. Fix: in `addGroceryShare`, replace an existing share with the same recipe instead of appending (this also re-sizes it when the drum changed); on the page, when `share(of:)` is non-empty show "N to buy" in place.
- **R2. Cook does nothing from paste.** `PasteRecipeView` opens `RecipePage(recipeID:)` with the default `onCook` (a no-op). From `RecipeView` it starts a cook, but with no cook mode yet nothing visible happens. Fix: make starting the cook RecipePage's default, and until slice 12 lands, answer with one Tess line ("Cooking. It's on Now.") or go back to Home.
- **R3. Tapping a line to fix it can get stuck.** `PasteRecipe.cycle` picks the next kind from the line's resolved kind. A line `IngredientLine.parse` can't read resolves "ingredient" to `.ignored`, so taps go ignore, ingredient (shows ignored), ingredient... and never reach step. Tapping the title, a heading or "Serves 4" turns it into an ingredient attempt and the title is lost until Edit. Fix: cycle on `corrections[index]` (ingredient, step, ignore), skip ingredient when it doesn't parse, and leave title, heading and meta lines out of the cycle (or give the title its own "title" state).

## Polish
- R4. A paste reads twice: `onChange(text)` calls `read()`, which sets `editing = false`, and `onChange(editing)` calls `read()` again, restarting the brush. Around 0:28 in the recording the editor's text and the painted text are drawn on top of each other. Guard `read()` with `!reading`, and fade the editor out before the painted lines come in.
- R5. Small text: the drum's neighbour numbers and the step numerals use `.data` (about 13pt), below the 16pt floor (same as Groceries fix 1).
- R6. The total time shows twice: in the context line ("25 min") and again beside Cook ("25 MIN"). Keep one.
- R7. A line corrected to a step keeps its "1." numbering (`CreateRecipe.lines` skips `stripNumbering`).
- R8. The recording ends on black and doesn't show the three instruments: turning the drum, swiping the column to Groceries, tapping a line to re-read it. Add those when it is re-cut.

## Checked and fine
`RecipeParser.classify` gives the same result as the old parse (title, headings, meta, shape before headings); corrections index the same non-empty lines; `[Int: String]` round-trips in the op log; scaling at the recipe's own size leaves amounts as written; `share(of:)` filters open items by share.

## Follow-ups (19:30 UTC)
- **#97 (iOS W1/W2, merged): pass.** A typed set clears the live Undo and edit; `isEditing` follows `editingRow`; undo, swap and finish end editing. W3 still open (low).
- **#98 (head 369f840):** R2, R3, R4, R5, R6 and the swipe-with-scroll fixed. **R1b (should-fix):** the share replacement in `addGroceryShare` runs per ingredient line, so a recipe listing an ingredient twice ("200 g butter" and "50 g butter") ends up with only the last line's amount. Drop the recipe's old shares once at the start of `AddRecipeToGroceries.apply`, then append per line. OK to merge before the cut either way (not reachable from Home yet).
