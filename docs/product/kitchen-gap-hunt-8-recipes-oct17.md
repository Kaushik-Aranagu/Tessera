# Kitchen gap hunt 8: Recipes screens on master (G51 on)

*Read-only walk of master 321883a (PR #747), Oct 17, as a first-week user: Home Kitchen page, Recipes, Paste a recipe, the recipe page, the Cook key. Files read: `Features/Recipes/*` (RecipePage, PasteRecipe, PortionDrum, RecipesEntry), `Features/Kitchen/CookModeCopy.swift`, `Features/Home/HomeSpatialView.swift`, `TesseraCore/.../Kitchen/{Recipes,Cooking,RecipeParser,RecipeMath,Groceries}.swift`, `Processes/ProcessActions.swift`, `Diagnostics/ClaudeKeyGuard.swift`. Compared with `cook-mode-acceptance.md`, `recipe-edit-acceptance.md`, `paste-hardening-acceptance.md`, `kitchen-acceptance.md`, `kitchen-phrases.md`, `kitchen-phrases-2.md`, `kitchen-first-week-gap-rows.md` (K86), `kitchen-first-use-empty-states.md`, `kitchen-error-states-acceptance.md`, `kitchen-first-week-script.md`, `kitchen-cook-mode-accessibility-acceptance.md`. G1 to G50 were read and not repeated. No code was run; "verified" means read in the file at the line given, "inferred" means it follows from the code but needs a run to see it.*

**Not a gap (checked, dropped).** There is no cook mode screen on master (`CookModeCopy` has no caller and no `CookMode*View` exists); that is on the release map as slice 12, so it is not numbered by itself. G55 below covers only what the Cook key does to a first-week user in the meantime. The shelf is a known build target in `kitchen-first-use-empty-states.md` section 1, but no G row covers what Recipes does today (G51). The failed-save wording on the recipe page is ER14; G58 adds the cases ER14 does not name.

## Summary

| ID | One line | Owner | State |
|---|---|---|---|
| G51 | "Recipes" always opens the oldest recipe; a second recipe has no door | Builder B | Verified |
| G52 | Paste: first recipe loses its saved line and UNDO; later ones get 2 s and the wrong words | Builder B | Verified, one part inferred |
| G53 | A private recipe's title is drawn raw on the recipe page, the original page and the saved line | Builder B (Core for one helper) | Verified |
| G54 | A link on the Paste screen is never read, and Save does nothing with no line | Core (wire), Builder B (lines) | Verified |
| G55 | Cook key starts a cook nobody can see; a recipe with no steps reads "Step 1 of 0" | Builder B, Core | Verified |
| G56 | Cook key silently suspends a running workout | Core, Builder B | Verified in engine, inferred on screen |
| G57 | Portion drum stops at 12; a recipe that serves 24 breaks it | Builder B | Verified |
| G58 | Swipe to Groceries: failed send leaves the column stuck, "0 to buy" with UNDO, no VoiceOver route | Builder B | Verified, one part inferred |
| G59 | First line of a paste becomes the title; "Untitled recipe" cannot be renamed; same paste twice makes two | Core, Builder B | Verified |
| G60 | Recipe context line: "1.6 h", "94 days ago" | Builder B | Verified |
| G61 | Claude key refusal on Paste points at Settings; the engine's line says Review, and the whole paste is wiped | Builder B, Core | Verified |

## Rows

### G51. "Recipes" opens the oldest recipe and there is no list

- **What.** The Kitchen page's Recipes word opens `RecipeView(recipeID: nil)`, which shows the first recipe by creation time and nothing else. With two recipes saved (FW9 pastes Shakshuka and Overnight oats) the second one cannot be reached from Recipes. The page's own words promise a list that does not exist: top-left "Recipes" with hint "Back to the recipes", and the gone page's "Back to the list". Both call `dismiss()`, which closes the whole full-screen cover back to Home, while "Close" sits at the top right of the same cover (two exits, two names, one result).
- **Evidence.** `Features/Recipes/RecipesEntry.swift:15` (`recipeID ?? RecipeBook(...).recipes().first?.id`); `TesseraCore/.../Kitchen/Recipes.swift:56-59` (`recipes()` sorts oldest first); `Features/Home/HomeSpatialView.swift:355` (`.recipes: RecipeView(recipeID: nil)`) and `:163-175` (the cover and its Close word); `Features/Recipes/RecipePage.swift:46-53` and `:144-150`.
- **Why it matters.** Day two he has three recipes and can open one. The ingredient page's backlinks are the only other door. "Back to the list" on a deleted recipe names a list that is not there. The shelf is a build target (`kitchen-first-use-empty-states.md` section 1, K30.1) but nothing says what Recipes does until it lands, and nothing says the top-left word.
- **Owner.** Builder B (shelf, slice 14).
- **Proposed row (K87.1).** *Given* three saved recipes. *When* he taps Recipes on the Kitchen page. *Then* the shelf opens with all three, newest first, and tapping a row opens that recipe's page. Top-left on the recipe page reads "Recipes" and returns to the shelf, not to Home; Close stays the only exit to Home. A deleted recipe's page reads "Recipe gone." with "Back to the list" returning to the shelf. Interim (until the shelf lands): **RULED (Product, decisions.md 8:20 AM Oct 17):** Recipes opens the last opened recipe (`lastOpenedAt` is already written), not the oldest.

### G52. Paste: the saved line and UNDO are wrong in both paths

- **What.** (a) With no recipes yet, the Recipes word opens `PasteRecipe()` inside `RecipeView`, whose body reads `model.revision`. Save calls `model.touch()`, the body re-evaluates, `recipes().first` now exists and the group swaps to `RecipePage`, so the "saved." line and UNDO are replaced in the same frame (inferred from the view structure; needs one run to confirm the frame). (b) From "Paste a recipe" the saved line reads `"\(title) saved."` and the page moves on after 2 s, so UNDO lasts 2 s. The ruled receipt is "Shakshuka, on Recipes." (FW9, K30 "After one action") and a new capture gives 4 s. (c) The recipe page is pushed on the paste stack, so its "Recipes" word pops back to the paste screen still showing "saved." and a live UNDO with no time limit; UNDO there deletes a recipe he has already read and may have started cooking.
- **Evidence.** `Features/Recipes/RecipesEntry.swift:12-19` and `:30-39`; `Features/Recipes/PasteRecipe.swift:25-27` (`savedTitle`), `:219-224` (2 s sleep, then `onSaved`), `:247` (`"\(title) saved."`), `:10` (`onSaved` defaults to a no-op); `kitchen-first-week-script.md` FW9; `kitchen-first-use-empty-states.md` section 1 ("After one action").
- **Why it matters.** The first recipe he ever pastes is the one path with no receipt and no UNDO. The wording he was promised is not the wording on screen.
- **Owner.** Builder B.
- **Proposed row (K87.2).** *Given* the Paste screen with a read recipe. *When* he taps Save, as the first recipe and as the fifth. *Then* Tess's cobalt line reads the receipt with the short name (K86.1), for example "Shakshuka, on Recipes.", UNDO holds 4 s, and the screen moves to the recipe page only after the UNDO window closes (or at once, with the line carried onto the page). UNDO inside 4 s removes the recipe and returns to the read text. After the window UNDO is gone everywhere; back from the recipe page never shows the paste screen's saved bar again.

### G53. A private recipe's title is drawn raw on the recipe page, the original page and the saved line

- **What.** The rule is that a private recipe reads "Private recipe" on every surface, spoken or drawn (`kitchen-cook-mode-accessibility-acceptance.md` header, K84.8; FW52: "Title, shelf row, Week, Tess and index read Private recipe"). `CookModeCopy` and the engine apply it. The recipe page does not: the hero is `recipe.title`, the original page's title is `recipe.title`, and the paste saved line is `object.title`. Nothing on these screens calls `ObjectPrivacy.isPrivateRecipeTitle`. The VoiceOver header uses the same text.
- **Evidence.** `Features/Recipes/RecipePage.swift:57` (hero), `:330` (original page title); `Features/Recipes/PasteRecipe.swift:25-27` and `:247`; contrast `Features/Kitchen/CookModeCopy.swift:71-73` and `TesseraCore/.../Kitchen/Cooking.swift:94-98`. `grep isPrivateRecipeTitle Features/Recipes` finds nothing.
- **Why it matters.** He pastes "Rent 1200 stew" or a recipe titled with a body weight and the page shows it in full while Home, the Live Activity and Pantry say "Private recipe". The saved line is read aloud by VoiceOver.
- **Owner.** Builder B (the three views); Core only if a shared `ObjectPrivacy.recipeDisplayTitle` helper is wanted so Builder B does not repeat the weight lookup.
- **Proposed row (K87.3).** *Given* a recipe whose title the recipe rule treats as private. *When* he opens its page, its original text, or saves it from Paste. *Then* the hero, the original page title, the saved line and the VoiceOver header all read "Private recipe" ("Private recipe, on Recipes." for the receipt); the ingredient column and steps stay as written because they are his own screen. Test with a title that carries a weight and one that carries a secret word.

### G54. A link on the Paste screen is never read, and Save does nothing with no line

- **What.** The error-states and week-one rows assume the Paste screen reads a pasted link (ER1 to ER9, K33.1, FW54: "Recipe link, kept for later."). The Paste screen has no link path: `RecipeLinkReader` and `RecipeImport` are referenced by nothing in `Features/` or `App/`. A pasted link is classified as one title line, Tess says "I couldn't find ingredients. Tap a line to mark one.", and Save runs `CreateRecipe`, which throws, so `save()` quietly writes a capture-miss row (route "none") and returns. No line, no haptic, no retry. This is G2's silent Save, reached by the most likely first paste (a link) rather than by empty text.
- **Evidence.** `Features/Recipes/PasteRecipe.swift:33-34` and `:406` (via `PasteCopy.tess`), `:199-213` (`save()` returns with no line); `rg RecipeLinkReader Features App` returns nothing; `kitchen-error-states-acceptance.md` ER1 to ER9, ER14; `kitchen-first-week-script.md` FW54.
- **Why it matters.** The first thing a person copies from a cooking site is the address bar. He pastes it, sees "couldn't find ingredients", taps Save and nothing happens.
- **Owner.** Core (call the reader from the paste path under the existing switch and guard), Builder B (the lines and the disabled Save).
- **Proposed row (K87.4).** *Given* a single https link in the paste box. *When* the paste lands. *Then* Tess reads "Recipe link, kept for later." offline, or reads on his tap online (ER1, ER5), never the URL aloud or on screen in her line. With "Tess asks Claude: no" the on-phone reader alone runs (G32). When nothing can be read at all, Save is not drawn (or reads as a quiet inactive word) and a tap, if it exists, says "Didn't save. Try again." once. No path ends in silence.

### G55. The Cook key starts a cook nobody can see; a recipe with no steps reads "Step 1 of 0"

- **What.** (a) The page's `onCook` is nil in every entry, so the key calls `StartCooking` directly, wrapped in `try?`. The only evidence is the key turning to "Cooking" and a line "Step 1 of 4". The steps are never shown (the page says so), there is no Next, no DONE, no timers, no way to stop; tapping "Cooking" again re-runs `StartCooking`, which resumes the same cook and shows nothing. The only ways to move or end the cook are Tess phrases. (b) A recipe with ingredients and no steps (paste a list) still draws the Cook key and the peek reads "0 steps"; starting it reads "Step 1 of 0". The empty-state doc rules the opposite.
- **Evidence.** `Features/Recipes/RecipePage.swift:160-169` (`cook`, `try?`), `:109` (`"\(steps.count) steps"`), `:113-128` (key and hint), `:391-396` (`"Step \(index + 1) of \(steps)"`); `rg onCook Features App` finds only the property and the call; `TesseraCore/.../Kitchen/Cooking.swift:123-134` (an open cook is resumed, not shown), `:141-143` (`first` step is nil for a recipe with no steps); `kitchen-first-use-empty-states.md` the "A recipe with no steps" row (line 84) ("The cook key is not drawn ... 'No steps yet. Paste them below.'").
- **Why it matters.** Until slice 12 lands this is the whole Cook experience, and the phone can be left holding an open cook that Home shows as running with no door to finish it.
- **Owner.** Builder B (key, line), Core (a cook with no steps).
- **Proposed row (K87.5).** *Given* the build before cook mode. *When* he taps Cook. *Then* **RULED (Product 8:20 AM):** the key is not drawn until cook mode lands; it never starts a cook with nothing to read. A recipe with no steps shows no Cook key and, under the ingredients, "No steps yet. Paste them below." (ruled, as in the empty-states doc); the peek line is omitted rather than "0 steps". "Step 1 of 0" is never drawn.

### G56. The Cook key silently suspends a running workout

- **What.** `StartCooking` calls `StartProcess`, which calls `suspendRunning(except: nil)`; any running process (a live workout included) is set to suspended. The Cook key has no ask and no line. The phrase list has a cook-while-cooking row (20) but no cook-while-training row, and the cook-mode rows cover two kitchen things at once, not a cook and a set.
- **Evidence.** `TesseraCore/.../Processes/ProcessActions.swift:43` and `:241-249` (every other running process is suspended); `Kitchen/Cooking.swift:135-144` (a new cook goes through `StartProcess`); `Features/Recipes/RecipePage.swift:160-169`. Whether Home then reads the workout as resumable is inferred.
- **Why it matters.** He taps Cook on his rest between sets and the rest timer, the Live Activity and Now stop belonging to the workout. A set logged next may not find its process.
- **Owner.** Core (refuse or keep both), Builder B (the line).
- **Proposed row (K87.6).** *Given* a workout running. *When* he taps Cook or says "cook carbonara". *Then* **RULED (Product 8:20 AM): refuse.** The key reads "Workout running." and starts nothing; the workout is not suspended and its rest timer and Live Activity do not change. No UNDO (nothing was done).

### G57. The portion drum stops at 12

- **What.** The drum's range is 1 to 12. The parser reads "Makes 24", "Serves 16" and "yield 30" into `serves` with no cap, and `servesCount` takes the first number of "Serves: 2-3". For a recipe that serves 24 the drum is built from 1 to 12, `scrolled = 24` matches no row, so no number is highlighted; and the VoiceOver adjustable action is `min(12, serves + 1)`, so increment from 24 jumps down to 12 and rescales every amount to half. A recipe that serves 14 cannot be scaled to its own size by scroll.
- **Evidence.** `Features/Recipes/PortionDrum.swift:9` (`range = 1 ... 12`), `:34` (`scrolled = serves`), `:52-53` (`min(range.upperBound, ...)`); `TesseraCore/.../Kitchen/RecipeParser.swift:129-135`; `Features/Recipes/RecipePage.swift:87`.
- **Why it matters.** Cookie, batch and party recipes are the ones people scale. The first one pasted with "Makes 24" shows a drum with nothing selected.
- **Owner.** Builder B.
- **Proposed row (K87.7).** *Given* a recipe that serves 24. *When* the page opens. *Then* the drum shows 24 centred and highlighted, runs from 1 to at least twice the written size (and never less than 12), and the VoiceOver increment from 24 reads "25". Scaling to 12 and back to 24 returns the written amounts exactly. Test with serves 14 and "Serves: 2-3" (reads 2, as now; the context line says "serves 2").

### G58. Swipe to Groceries: failure, zero, and VoiceOver

- **What.** (a) If `AddRecipeToGroceries` throws, `onEnded` returns before `drag = 0`, so the column stays dragged left (inferred: it needs a failure, for example a deleted Groceries list). There is no "Didn't save. Try again." (ER14). (b) When every line is a staple, optional, to-taste or covered, the action returns an empty list; the page still shows "0 to buy, on Groceries" with UNDO and hides the column. The action's own comment says nothing is written then, "so no UNDO" (Product e1981a39), and the walk of Oct 17 only covers a second add. (c) The container's hint says "Swipe left to add them to groceries", but no accessibility action exists on the page, and VoiceOver's left swipe moves focus; the add is unreachable. Amount and name are separate stops per row, and the metric flip is a bare tap gesture on the amount (no button trait, no action).
- **Evidence.** `Features/Recipes/RecipePage.swift:192-193` (`guard let result = try? ...  else { return }`), `:194-199`, `:227` (`"\(count) to buy, on Groceries"`), `:283` (hint), `:262` (`onTapGesture`); `grep accessibilityAction Features/Recipes` finds nothing; `TesseraCore/.../Kitchen/Groceries.swift:355-371`.
- **Why it matters.** A stuck column with no words, a receipt for nothing with an UNDO that undoes nothing, and a feature a VoiceOver user cannot reach.
- **Owner.** Builder B.
- **Proposed row (K87.8).** *Given* the recipe page. *When* the add fails: the column springs back and Tess says "Didn't save. Try again." *When* nothing is left to add: no column move, no UNDO, one line "Tacos, nothing to add." (**RULED, Product 8:20 AM**; the recipe's short name first, no UNDO). *With VoiceOver*: the ingredient list carries the custom action "Add to Groceries" that runs the same add and speaks "Tacos, 7 added." (K84.25 form); each row reads as one stop ("2 cups flour, chopped") with the action "Show in metric" where a metric form exists.

### G59. Title, "Untitled recipe" and the same paste twice

- **What.** (a) The first non-empty line is the title unless it opens with an amount, so a paste that begins with a step ("Heat the oven to 200C.") or a bare name-first ingredient ("Flour") makes that line the title; the recipe page then wears a sentence as its hero. (b) When no line is a title the title is "Untitled recipe", and the app has no way to rename it: `EditRecipe` exists but no screen calls it (the in-place fix is a v2 slice). (c) Pasting the same recipe twice makes two recipes with the same title; nothing checks, and a recipe cannot be deleted from its page (the only removal is UNDO, G52).
- **Evidence.** `TesseraCore/.../Kitchen/RecipeParser.swift:53-54` (`index == 0, !startsWithAmount`), `:109` (`?? "Untitled recipe"`); `Kitchen/Recipes.swift:173-177` (`CreateRecipe` has no duplicate check), `:257-288` (`EditRecipe`); `rg EditRecipe Features` finds nothing; no acceptance file mentions "Untitled recipe".
- **Why it matters.** A first-week paste from a note or a message often has no title. He gets a sentence or "Untitled recipe" as the hero, forever, and cannot fix it; Cook then names the Cook object after it.
- **Owner.** Core (title rule, duplicate check), Builder B (rename gesture).
- **Proposed row (K87.9).** *Given* a paste whose first line is a sentence over 8 words, or no first line at all. *Then* the title is the first noun phrase up to 6 words (the K86.1 rule) or "Untitled recipe"; the sentence stays as the first step. Tapping the title on the recipe page edits it in place through `EditRecipe` (Return keeps it), receipt "Dal, renamed." with UNDO 10 s. *Given* a paste whose text equals a saved recipe's `sourceText`: Tess says "Weeknight dal is already on Recipes." and Save opens that recipe instead of writing a second.

### G60. The recipe context line shows decimal hours and a raw day count

- **What.** The line under the title writes a total of 95 minutes as "1.6 h" (`fractionLength(0 ... 1)`), 100 minutes as "1.7 h", and cooked dates as "94 days ago" or "400 days ago" with no month or year. The cook log rule is hours and minutes ("6 h 55 min", "1 h"; O2); the Cooked list on the original page has no year ("Tuesday, October 14" next year is ambiguous). No row names the context line's forms except the example in the source comment.
- **Evidence.** `Features/Recipes/RecipePage.swift:381-383` and `:398-400` (`hours`), `:402-411` (`relative`), `:419-422` (`cookLine`); `cook-mode-acceptance.md` O1, O2.
- **Why it matters.** "1.6 h" is not a time anyone says; the same recipe reads "1 h 35 min" in the log.
- **Owner.** Builder B.
- **Proposed row (K87.10).** *Given* totalMinutes 95, 100, 150, 60 and 45. *Then* the context reads "1 h 35 min", "1 h 40 min", "2 h 30 min", "1 h", "45 min". *Given* last cooked 3, 40, 94 and 400 days ago. *Then* "cooked 3 days ago", "cooked 40 days ago", "cooked 3 months ago", "cooked last year". Cooked entries on the original page add the year for any date outside the current year and the finish clock in the house form ("9:05 am", O3).

### G61. The Claude key refusal on Paste names the wrong place and wipes the whole paste

- **What.** The Paste screen hard-codes "That looks like a Claude key. It goes in Settings, not a recipe." The engine's shared line, used by the Bar, says "It goes in Review, under Claude." and the key section is in Review; the app has no Settings screen for it. Second, the check runs on the whole text, so a long recipe that contains one key-shaped fragment is cleared entirely (`text = ""`), including the 30 lines he pasted; the neighbouring paths cut only the private line (`SecretWords.cut`, `isPrivateLine`).
- **Evidence.** `Features/Recipes/PasteRecipe.swift:33` and `:117-123`; `TesseraCore/.../Diagnostics/ClaudeKeyGuard.swift:4` (`claudeKeyLine`) and `:18-20`; `Features/Command/BottomChrome.swift:467`; `Features/Review/ReviewView.swift:228` (`ClaudeSection()`); `PasteRecipe.swift:166-167` via `CreateRecipe.lines` (private lines already become ignored).
- **Why it matters.** Wrong directions on a safety line, and a recipe lost to a stray string. Whether to keep the rest of the paste is a ruling, so the second half is inferred as a gap, not a bug.
- **Owner.** Builder B (use `claudeKeyLine`), Core (a cut that removes the key line only), Product (keep or wipe).
- **Proposed row (K87.11).** *Given* a key-shaped string alone in the paste box. *Then* Tess says the shared line (`claudeKeyLine`: "That looks like a Claude key. It goes in Review, under Claude.") and the box clears. *Given* the same string inside a 20-line recipe. *Then* **RULED (Product 8:20 AM):** the rest of the paste is kept, the save is held, the string is never echoed, and the line says Review (the shared line above). The key is never shown, saved, logged, copied into a capture-miss row or placed in the original text. No row, fixture or log holds key-shaped text; test with a built string that is assembled at run time.

## Order of work

1. G51, G52 and G55 are what a first-week user hits in the first ten minutes (second recipe, first save, first Cook). They share one owner (Builder B) and should go together with the shelf.
2. G53 and G61 are wall and copy: small, testable, one helper each.
3. G54 and G59 are Core-first (link path, title rule, duplicate check).
4. G56 needs a Product ruling (keep both or refuse) before Core changes `StartProcess`.
5. G57, G58 and G60 are Builder B polish with exact rows above.

## Rulings (Product, decisions.md 8:20 AM Oct 17)

All five asked rulings are in and folded into the rows above.

- G51 interim: Recipes opens the last opened recipe until the shelf lands.
- G55: hide the Cook key until cook mode lands; a recipe with no steps shows "No steps yet. Paste them below."
- G56: refuse; the key reads "Workout running." and starts nothing.
- G58: "Tacos, nothing to add." with no UNDO.
- G61: keep the rest of the paste, hold the save, never echo the string, the line says Review. Open reading for Builder B: "hold the save" is taken here as the save waits until the key-shaped line is gone from the box.
