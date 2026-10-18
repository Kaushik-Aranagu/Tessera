# Kitchen acceptance of #752, #756 and #758: static read

*Kitchen lead helper, Oct 17. Read-only walk of origin/master 17506eb (all three merged). Nothing was run: PASS means the clause is met by the code at the line given, "inferred" means it follows from the code and needs the phone. Paths are repo-relative; line numbers are in the file as it stands on master.*

**Merge commits.** #752 is 56aae0e (code in 5ce2997, 385b567, 4a1ae11). #756 is 6b45080 (code in 7951d23, 3392258). #758 is 17506eb (code in 4bbfd51; the same commit also carries unrelated Habits and ObjectPlate lows).

Test names below are Swift Testing functions. Files: `RecipeTitleWallTests` (#752), `RecipesOpeningTests` (#756), `PantryLedgerTests` and `PantryCopyTests` (#758).

## 1. K87.1 (G51), with the ruled interim

| Clause | Result | Evidence | Test |
|---|---|---|---|
| Shelf opens with all recipes, newest first, a tap opens a row's page | NOT BUILT (the row is the target; only the interim was ruled to land) | `Features/Recipes/RecipesEntry.swift:19-23` opens one page or Paste; no list view exists | no test |
| Top-left "Recipes" returns to the shelf, Close stays the only exit to Home | NOT BUILT | `RecipePage.swift:51-58` still `dismiss()`, which closes the whole cover to Home | no test |
| Deleted recipe: "Recipe gone." and "Back to the list" returns to the shelf | PARTLY: words PASS, destination NOT BUILT | `RecipePage.swift:165-168` (`dismiss()` to Home). Also, via Recipes the page cannot show "Recipe gone." at all, see note 1 | no test |
| Interim: Recipes opens the last opened recipe, not the oldest | PASS | `RecipesEntry.swift:44-53` (`opening`: requested, else max `lastOpenedAt`, else newest `createdAt`); caller `HomeSpatialView.swift:355` and `App/TesseraApp.swift:61` pass nil | `recipesOpensTheLastOpenedRecipe` |
| Interim: with none opened, a sensible pick (the newest, per the code comment quoting Product) | PASS (the ruling text in decisions.md says only "last opened"; "newest if none" is the builder's quote) | `RecipesEntry.swift:52` | `noneOpenedGivesTheNewest` |
| Interim: `lastOpenedAt` is what picks it, and each page open writes it | PASS | `RecipePage.swift:32,37-40` (`markOpened` on every page open, no op) | no test of the write |
| Deleted recipes never picked | PASS | `RecipesEntry.swift:16` filters `isDeleted` before the pick | `aRequestedRecipeWinsAndDeletedOnesAreNotRows` (checks the live filter in the book; the view's own filter line is not exercised) |
| No recipes: Paste opens | PASS (pre-existing) | `RecipesEntry.swift:21-23` | `noneOpenedGivesTheNewest` (empty rows give nil) |
| A requested recipe (backlink) wins | PASS | `RecipesEntry.swift:45-47` | `aRequestedRecipeWinsAndDeletedOnesAreNotRows` |
| No UserDefaults key | PASS | `RecipesEntry.swift` has none; commit 3392258 removed it | no test |

Note 1 (new, minor). With `recipeID == nil` the pick is recomputed on every `model.revision`. If the recipe on screen is deleted, the pick moves to the next recipe instead of showing "Recipe gone.". Inferred; not wrong under the interim, but the gone page is unreachable from Recipes until the shelf lands.

## 2. K87.3 (G53)

*Given* a recipe whose title the recipe rule treats as private. *Then* these four read "Private recipe".

| Clause | Result | Evidence | Test |
|---|---|---|---|
| Recipe page hero reads "Private recipe" | PASS | `RecipePage.swift:61-69` (masked button, `ObjectPrivacy.recipeLabel`); rule `RecipePage.swift:416-418` | `aPrivateTitleIsMaskedUntilShown` covers the helper (a weight title and a secret-word title); the view wiring has no test |
| Original page title reads "Private recipe" | PASS | `RecipePage.swift:362-363` | helper only, as above |
| Original page's pasted-title line also masked (beyond the row) | PASS | `RecipePage.swift:389`, `RecipeCopy.maskedSource` `:422-429` | `thePastedTitleLineStaysMaskedWhileTheTitleIs` (plain, case, `#`, `**`, colon forms) |
| Saved line on Paste reads "Private recipe" | PASS for the name; the receipt form is NOT BUILT | `PasteRecipe.swift:26-28` feeds the SaveBar, `:249` draws "\(title) saved." | helper only; no test of `savedTitle` |
| Receipt reads "Private recipe, on Recipes." | NOT BUILT (the whole saved line is still "<title> saved."; the K86.1 and G52 receipt form has not landed) | `PasteRecipe.swift:249` | no test |
| VoiceOver header reads "Private recipe" | PASS (inferred): the masked hero is a button carrying the header trait with text "Private recipe" | `RecipePage.swift:70,78` | no test |
| Original page header is a button to VoiceOver while masked | PASS (extra, from QA on #752) | `RecipePage.swift:366-369` | no test |
| Ingredient column and steps stay as written | PASS | `RecipePage.swift:90,119` untouched by the mask | no test |
| REMOVED by G102 (Oct 17): a private recipe title always reads "Private recipe" on every screen; no tap shows it (was: tap shows it for this visit; leaving or locking masks it again) | PASS (inferred) (superseded by G102; the build must now keep the title masked on tap) | `RecipePage.swift:28,66,156-161` and `:355,370,404-408` | `aPrivateTitleIsMaskedUntilShown` (shown flag only); the reset has no test |
| Test with a weight title and a secret-word title | PARTLY: secret words and money are tested ("Rent 1200 stew", "Wifi code lasagna"); no title that carries a body weight is used | `RecipeTitleWallTests.swift:16` | `aPrivateTitleIsMaskedUntilShown` |

Side effect to know: a masked hero is a button that shows the title; the ordinary tap into the original page needs a second tap (`RecipePage.swift:65-74`). That is a design choice in the PR, not in the row.

## 3. K87.5 (G55), ruled

| Clause | Result | Evidence | Test |
|---|---|---|---|
| The Cook key is not drawn until cook mode lands | PASS | `RecipePage.swift:13` (`cookModeReady = false`), `:126-134` | `noCookKeyUntilCookMode` (checks the flag only, not the drawn tree) |
| It never starts a cook with nothing to read, "Step 1 of 0" never drawn | PASS | key hidden; `RecipeCopy.cookStep` returns nil for zero steps, `RecipePage.swift:457-463` | no test of `cookStep` |
| A recipe with no steps shows, under the ingredients, "No steps yet. Paste them below." | PASS | `RecipePage.swift:119` with `stepCount` `:465-472`; sits below the ingredient block (`:87-107`) | `noStepsReadsAsAnInvitationNeverStepOneOfZero` |
| The peek line is omitted rather than "0 steps" | PASS (it is replaced by the invitation line; "0 steps" cannot be produced) | `RecipePage.swift:466-471` | same test |
| "N steps" and "1 step" otherwise | PASS | `RecipePage.swift:469-470` | same test |

Still reachable: the "cooking" line of text (`RecipePage.swift:135-140`) and the Tess phrase path (`StartCooking` through Tess) are not touched, so a cook can still start from a phrase with no screen to read it (see open items).

## 4. "A recipe with no steps" (`kitchen-first-use-empty-states.md`, line 84)

| Clause | Result | Evidence | Test |
|---|---|---|---|
| The cook key is not drawn | PASS | `RecipePage.swift:126` | `noCookKeyUntilCookMode` |
| No empty step view opens | PASS (no cook screen exists on master) | no `CookMode*View` | no test |
| One quiet line under the ingredients, "No steps yet. Paste them below." | PASS (proposed wording, now ruled by Product) | `RecipePage.swift:119-122` (body role, secondary ink) | `noStepsReadsAsAnInvitationNeverStepOneOfZero` |

Copy question to raise: "Paste them below" points at a paste field, but the recipe page has none below it (Paste is a separate screen). The words match the ruling; whether they lead anywhere is a Product and Builder B question.

## 5. K89.1 (FG9)

| Clause | Result | Evidence | Test |
|---|---|---|---|
| `lastCookUsedUp()` returns nil for a private recipe | PASS | `Features/Kitchen/PantryLedger.swift:97-100` (same `isPrivateRecipeTitle` rule as the label) | `aPrivateRecipeGetsNoCookLineAtAll` (a "Wifi code lasagna" recipe cooked; asserts nil) |
| Tess slot empty on Pantry | PASS | `Features/Kitchen/PantryFront.swift:27` maps nil to nil | `PantryFrontTests` line 29 covers nil with no cook only; no front test for a private cook |
| No string contains "Private recipe took" | PASS (the only producer is `PantryCopy.tess`, fed by this function) | `PantryFront.swift:27`, `PantryCopy.swift:27-30` | `aPrivateRecipeGetsNoCookLineAtAll` |
| Hero and OUT line still change ("1 out") after the private cook | PASS (inferred): `cookUses` does not skip private recipes | `PantryLedger.swift:152-166` | no test: the new test never reads `entries()` or the hero for the private cook |
| Ordinary recipe unchanged, "Tacos took the cilantro and limes." | PASS | `PantryCopy.swift:30`; ledger line `PantryLedger.swift:99-104` | `PantryCopyTests.swift:28`, `PantryFrontTests.swift:39`, `PantryLedgerTests.swift:69` |
| Over three names, "Tacos took 5 things." | PASS | `PantryCopy.swift:29-30` | `PantryCopyTests.swift:30` |
| Test in `PantryFrontTests` asserting `front.tess == nil` while the hero still counts | NOT BUILT as specced: the test lives in `PantryLedgerTests` and asserts the ledger only | `PantryLedgerTests.swift` (renamed in 4bbfd51) | gap |
| Accessibility tree holds no recipe words | NOT PROVABLE statically (needs VoiceOver on Pantry) | n/a | no test |

An earlier cook does not fill the empty slot: the latest cook decides, so a private cook after an ordinary one leaves the slot empty, which is what the row asks.

## 6. Rows that stay unaffected (K87.2, K87.4, K87.6 to K87.11)

The three PRs touch only `RecipePage.swift`, `RecipesEntry.swift`, `PasteRecipe.swift` (4 lines, the saved name) and `PantryLedger.swift`, so these rows are as the gap hunt left them.

| Row | Gap | State on master 17506eb |
|---|---|---|
| K87.2 | G52 Paste saved line, UNDO | Open. `PasteRecipe.swift:249` still "<title> saved."; the short-name receipt and the 4 s UNDO window not built |
| K87.4 | G54 link on Paste | Open. Untouched |
| K87.6 | G56 refuse Cook while a workout runs | Open in Core. The key is hidden so the key path is moot, but "cook carbonara" through Tess still reaches `StartCooking` with no refusal (inferred; not re-read in Core) |
| K87.7 | G57 portion drum stops at 12 | Open. `PortionDrum` untouched |
| K87.8 | G58 Groceries swipe failure, zero, VoiceOver | Open. `RecipePage.swift:221-222` still `try?` with a silent return |
| K87.9 | G59 title rule, rename, duplicate paste | Open |
| K87.10 | G60 context line | Open. `RecipePage.swift:449` still decimal hours; `:485` still "N days ago" |
| K87.11 | G61 key refusal on Paste | Open |

## 7. What these PRs closed, and what stays open in the same gaps

**Closed**
- G51 interim: Recipes opens the last opened recipe (not the oldest). The gap itself stays open for the shelf.
- G53: the hero, the original page and the saved line mask a private title; the ingredient column stays as written. The receipt wording is part of G52, not G53.
- G55 ruled part: no Cook key until cook mode lands; the no-steps line reads "No steps yet. Paste them below."; "Step 1 of 0" is gone.
- FG9 (K89.1): no Tess cook line for a private recipe. Closed in code; the front-level test the row asked for is missing.

**Still open in the same gaps**
- G51: the shelf (K87.1 proper), the top-left "Recipes" and "Back to the list" still close to Home, and the unreachable "Recipe gone." under note 1.
- G52: untouched (saved line, UNDO window, wrong words on the second recipe).
- G53: no title with a body weight in the test; saved line tests the helper only; the receipt "Private recipe, on Recipes." waits on G52.
- G54, G56 to G61: untouched, see section 6.
- G55: the Tess phrase route can still start a cook nobody can see; "Paste them below" has no paste field below it; Core's cook with no steps (the gap's Core half) not changed.
- FG9: no test that the hero and OUT line still change for a private cook, and none at `PantryFront` level; accessibility tree unverified.
- G46 (a cook keeps what it used) and G48 (scale cases) are not touched by these PRs.

## 8. Phone only

1. **Private recipe title on the three screens.** Paste "Rent 1200 stew" with two ingredient lines and a step, tap Save: the saved bar should read "Private recipe saved." (not the title). Open its page: the hero reads "Private recipe"; tap it and the title shows, tap again for the original page; leave and return, it is masked again. On the original page the title and the "As pasted" first line both read "Private recipe" until the title is tapped. Lock and unlock mid-visit: masked again. Repeat with a title that holds a body weight number.
2. **Pantry after a private cook.** Use a private-titled recipe with limes; cook it to DONE through Tess ("cook ...", then "done"). Open Pantry: the hero counts limes out ("1 out"), the Tess line under it is empty, and with VoiceOver on nothing reads "Private recipe took". Then do the same with Tacos: "Tacos took the ..." appears.
3. **Recipes opening last opened.** Save two recipes, open the older one from its page, close to Home, tap Recipes: the older one opens. Open the other, close, tap Recipes: that one opens. Delete the open recipe from a second route and watch whether Recipes jumps to the other recipe (note 1).
4. **No steps, no Cook key.** Paste only an ingredient list, save, open the page: no Cook key, and under the ingredients "No steps yet. Paste them below." Check a recipe with steps also shows no Cook key and "4 steps" style peek. Look at where "below" points.
5. **Mask on the VoiceOver rotor.** With VoiceOver on, the masked hero should say "Private recipe" and be found as a header. It has no "Shows it" hint and is not a button for a reveal (G102, Oct 17).
