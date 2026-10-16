# Recipe edit in place: defaults and acceptance (kitchen v2, slice 1 of the default cut)

*Kitchen lead, 2026-10-16. Drafted ahead of Oct 22: `kitchen-v2-scope.md` makes this the first v2 slice unless his answers reorder the cut (Q2 "did you fix a recipe after saving it, or want to"), and the re-parse diff of his pastes is its data signal. The surface is Design 11's paint-over (`docs/design/kitchen/10-11-recipe-page-and-paste.md`, "tap a word or line to cycle it"); nothing new to draw beyond the way in and the way to change a word. Core builds the engine first.*

## What it is

Fix a saved recipe without pasting it again: a line read as a step that is an ingredient (or the reverse), a line to ignore, a typo in an amount or a name, a step to split in two or join, two steps in the wrong order, the title, the serves. The recipe keeps its identity: the same object, the same cook log, the same planned tasks, the same learned aisles, the same `lastOpenedAt`, the same links from notes.

## Defaults taken

| Point | Default |
|---|---|
| Way in | A plain word on the recipe page, FIX, at the right of the key row (the swipe-for-more house rule in Design 69 gives the page one side page, the ingredient peek, so the fix surface opens as a push, not a side page). Design names the word; FIX is the default. |
| The surface | Design 11's paste surface opened on `sourceText` with the saved kinds already painted (no brush read: the marks are there when the page lands, the brush is for a first read). Tap a word or line to cycle ingredient → step → ignore, as 11 says. |
| Changing words | Long-press a line to edit its text in place with the system keyboard, one line at a time; Return keeps it. Design confirms the gesture; it is the only text entry on the page. |
| Split and join | A line break typed inside a step splits it; deleting the break joins. Reorder is a drag on the step's number, the same drag as list rows. |
| Title and serves | The title line and the "Serves N" line are text like the rest; `EditRecipe` already renames and resizes, and the fix surface writes through it. |
| Save | The same `PaintKey` as 11, reading "Save". Tess: "Carbonara, fixed." with UNDO for 10 s (a change: the 10 s length, Product dce3675). UNDO restores the previous text and kinds in one op. |
| Nothing changed | Save with no change: the page closes, no line, no op. |
| Groceries | The list follows the recipe silently. For a planned recipe: an ingredient line added or re-kinded to ingredient lands as a ghost row under the same rules as planning (covered, staples, optional skipped); a line removed or re-kinded away leaves its ghost row if unchecked and leaves a checked row alone; a renamed ingredient moves its share to the new ingredient. No second Tess line. The count line rolls. |
| Cook log and timers | Past cooks keep the old steps as cooked (the log does not rewrite history). A cook running now keeps its step list until it ends. |
| Scaling | A serves change re-bases every amount the way the portion drum does (`RecipeMath.scaled`); amounts he typed over keep the written form. |

## Engine (Core)

- `EditRecipe` gains `text: String?` and `corrections: [Int: String]?`, the same shape as `CreateRecipe`; it re-parses, rewrites the recipe's lines, keeps `sourceText` current, and records one `editRecipe` op whose summary is the receipt ("Carbonara, fixed."). Renaming and resizing stay as today.
- Lines keep their `packSize` and `optional` flags from the parse (G-R1, G-R4).
- Re-link: an ingredient line whose key is unchanged keeps its Ingredient object; a renamed one links to the ingredient of the new key (created if new), and any Groceries share for this recipe moves with it.
- UNDO reverses the op: text, kinds, links and the Groceries rows it moved.
- The capture-miss log is not touched; fixing a recipe is not a miss.

## Done when

**Core**
1. `swift test`: a saved recipe with one step line re-kinded to ingredient gains the line in `RecipeBook.lines(of:)`, keeps its id, `cookedAt` history, planned task links and `lastOpenedAt`; `sourceText` holds the corrected text; one `editRecipe` op with summary "Carbonara, fixed."
2. An ingredient line renamed ("2 limes" → "2 lemons") links the recipe to lemons; a planned recipe's open "limes" ghost row becomes "lemons" in Produce with "for carbonara" under it; a checked row stays as it was.
3. A step split by a line break gives two steps with their own `durations`; a joined step gives one; a reordered step keeps its text and timer.
4. UNDO within 10 s restores text, kinds, links and the rows; after 10 s the op stands.
5. Save with no change writes no op.
6. The counts script (`scripts/kitchen-week-one.py`) reads the edit as one `editRecipe` op.

**Builder B** (recording `docs/recordings/recipe-edit.mp4`)
1. FIX on the recipe page opens the paste surface with the marks already painted, no brush pass.
2. Tap cycles a line's kind with its mark repainting; long-press edits the words in place; Return keeps them.
3. Save: "Carbonara, fixed." with UNDO; the recipe page behind updates in place with amounts rolling, no reload.
4. UNDO puts the old line back on the page.
5. UI bar: nothing under 16 pt, no fields or forms except the one line being edited, Reduce Motion gives crossfades.

## Open questions, defaults taken

1. Does a fix to a recipe he has cooked rewrite past cook entries? DEFAULT: no, history keeps what he cooked.
2. Does Tess offer the fix when a paste read looks wrong ("3 lines look like steps")? DEFAULT: no in this slice; the week-one re-parse diff says whether the parser or the surface needs it first.
3. Text entry gesture. DEFAULT: long-press a line; Design can swap it for a tap on the already-selected line.
