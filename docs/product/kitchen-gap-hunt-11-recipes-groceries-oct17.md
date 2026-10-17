# Gap hunt 11: Recipes paste/keep/duplicate (release 13) and Groceries private-title walk

Read against origin/master 47365b0. Static read only; no Swift toolchain, nothing run. "inferred" marks a reading that no
test or comment confirms. Merges: #854 (5f1e128, c527459), #859 (427f8d5, ffd5ef8), #865 (a30db72, c244337).
The "3:35 PM private-title rule" is not written in the repo (grep found no 3:35 PM ruling); I took it as given in the brief.

## Part A: acceptance table

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| First line is a title at 12 words or fewer | PASS | RecipeParser.swift:74-77 (`> 12`), 53 | RecipeTests theTitleRule (9, 12 words) |
| 13 words is not a title: "Untitled recipe" | PASS | RecipeParser.swift:76, 116 | theTitleRule (13 words) |
| Ends in "." "!" "?" is not a title | PASS (stops only; see G96) | RecipeParser.swift:76 | theTitleRule ("Mix everything.", "...dal?") |
| Trailing ":" is stripped, still a title ("Dal:") | PASS | RecipeParser.swift:75, 96 | theTitleRule |
| Starts with a quantity is not a title ("2 eggs", "1/2 cup", "A pinch of") | PASS (digit-first only; see G94, G95) | RecipeParser.swift:53, 171-175 | theTitleRule |
| Trailing space / blank first lines do not change the title | PASS | RecipeParser.swift:42-44 trims and drops empty lines | no test |
| Rejected line is kept as step 1 | FAIL for 5 words or fewer ending "!" or "?" (G93); PASS for "." and for 6+ words | RecipeParser.swift:56-60, 168 | theTitleRule asserts step 1 only for "Mix everything." |
| #859 duplicate paste in Tess capture says "<title> is already on Recipes." | PASS | TessCaptureEngine.swift:250-259; Recipes.swift:192-196 | GrammarMisfireTests aDuplicatePasteSaysSoAndIsNeverLogged |
| Tess duplicate is a refusal and is never logged as a miss | PASS | TessCaptureEngine.swift:59, TessCapturing.swift (isRefusal) | same test (`log.all().isEmpty`) |
| Private duplicate reads "Private recipe", never its words (Tess) | PASS | Recipes.swift:193-195 | same test ("Lexapro stew") |
| #865 paste-screen duplicate refused before any write | PASS | PasteRecipe.swift:552-554, 589-594 | PasteCycleTests aDuplicatePasteNamesTheRecipe |
| Paste duplicate logs nothing (private or not) | PASS | PasteRecipe.swift:552-554 returns before the catch at 563-572 | PasteCycleTests aPrivateDuplicateNeverReachesTheMissLog |
| Paste duplicate keeps his text, ink line, no haptic | NOT PROVABLE (view code) | PasteRecipe.swift:308-311, 51 | no test (viewer-only) |
| Engine refusal after corrections is also masked | PASS | PasteRecipe.swift:560-562; Recipes.swift:204-207 | RecipeTests theSamePasteTwiceIsOneRecipe |
| Same paste after UNDO may be saved again | PASS by read (`recipes()` skips deleted, ObjectStore.swift:88) | Recipes.swift:56-59 | no test (inferred) |
| Same text with trailing space, CRLF or newline is the same recipe | FAIL (G98) | Recipes.swift:63-66 | no test |
| Saved receipt for a private title is "Private recipe, on Recipes." | PASS | PasteRecipe.swift:36-39; RecipePage.swift:599-601 | RecipeTitleWallTests:51 |
| New recipe whose title equals an existing private recipe's reads "Private recipe" | PASS by read (mask is by title text) | RecipePage.swift:583-585; ObjectPrivacy.swift:60-63 | no test |

Edge checklist: 12 vs 13 words PASS (tested). Trailing space PASS (untested). "2 cups" PASS (tested for "2 eggs",
"1/2 cup"). Empty first line PASS (untested). Emoji: "Dal 🍲" stays a title (fine); "1️⃣ Dal" starts with a digit
character (inferred, G94). Non-English punctuation FAIL (G96, G97). Title equal to a private recipe: PASS but untested.

## Part A gaps

- **G93 (important)** Short rejected lines are not kept as step 1. A first line of 5 words or fewer ending "!" or "?"
  ("Is this the best dal?") fails `isSentence` but then goes to `looksLikeIngredient` (words <= 5 and no "." suffix), so it
  is read as an ingredient (inferred: if `IngredientLine.parse` returns nil it falls to step). The clause says the line is
  step 1. RecipeParser.swift:56-60, 168. Fix: in `classify`, when index 0 is a sentence, force `.step(stripNumbering)`.
  Test only covers "." (RecipeTests theTitleRule). Owner: Core engine.
- **G94 (important)** Titles that begin with a digit are read as a quantity: "30-Minute Dal", "5-Ingredient Chili",
  "7 Layer Dip", "3 bean chili" become "Untitled recipe" and the title line becomes an ingredient (first character
  `isNumber`, also "½" and keycap digits). RecipeParser.swift:171-175, 162-164. Fix: quantity means a number (or fraction)
  followed by a unit word, or a number followed by a lowercase noun; a digit joined by "-" to a word, or a number plus a
  capitalized word, stays a title. Owner: Product ruling on the definition, then Core engine.
- **G95 (low)** Written-out quantities pass as titles: "Two eggs", "Half a lemon", "A cup of flour", "Some salt".
  RecipeParser.swift:171-175 knows only digits and "a/an pinch|handful|bunch|clove|can|tin|slice|sprig". Fix: add number
  words and "half/quarter/a cup/a splash" to the quantity test, or rule they are accepted. Owner: Product ruling.
- **G96 (important)** A stop followed by a closing mark is not a stop. "Stir well.”", "Mix it.)", "Bake 20 min. 🙂" and
  "Mix well.\"" end in a curly quote, bracket or emoji, so a sentence up to 12 words becomes the title. Web and chat copy
  produce these often. RecipeParser.swift:74-77 (`hasSuffix` on the raw trimmed string). Fix: strip trailing quotes,
  brackets, emoji and spaces before the stop check. Owner: Core engine.
- **G97 (low)** Word count and stop set are Latin-only: words are split on U+0020 only (a tab or NBSP-joined 13-word line
  counts as 1), a CJK or Thai paragraph has no spaces so counts as 1 word, and "。 ！ ？ । …" are not stops, so a whole
  non-English sentence becomes the title. RecipeParser.swift:76. Fix: count with `enumerateSubstrings(.byWords)`, add
  full-width stops and "…", and cap a title at about 80 characters. Owner: Core engine.
- **G98 (important)** Duplicate check is an exact string match. A paste with a trailing newline, trailing space, CRLF or
  curly vs straight quotes is "new", so a second copy is written. The paste screen compares the raw box text
  (PasteRecipe.swift:590, Recipes.swift:204) while Tess trims before comparing (TessGrammar+Kitchen.swift:11), so a recipe
  said to Tess and then pasted on screen with a trailing newline is saved twice (inferred). `recipe(pastedAs:)` Recipes.swift:63-66.
  No test for trailing space, CRLF or undo-then-repaste. Fix: compare a normalized form (trim, CRLF to LF, trim each line)
  on both sides. Owner: Core engine.
- **G99 (low)** The duplicate line prints the full title, while every other recipe receipt uses the short name
  (RecipeCopy.shortName, RecipePage.swift:605). A 12-word title makes a 12-word line. The line is also built twice,
  Recipes.swift:192-196 and PasteRecipe.swift:589-594, so the two can drift. Fix: PasteCopy.duplicateLine should call
  `CreateRecipe.duplicateLine`; run the title through `shortName`. Owner: Builder B screen.
- **G100 (low)** Dead flag. `store.value("isPrivate", of: recipe)` is checked at Recipes.swift:193, PasteRecipe.swift:591
  and Groceries.swift:560, but the recipe class has no `isPrivate` field (SystemCatalog.swift:220, 264 are note and memory;
  ObjectPrivacy.swift:12 says a recipe has no flag). The checks never fire, and if a flag is added later
  `ObjectPrivacy.label` (ObjectPrivacy.swift:53-55) ignores it. Fix: delete the three checks or add the flag to all four.
  Owner: Core engine.
- **G101 (low)** Two different pastes whose first line is a sentence are both saved as "Untitled recipe". Nothing prompts
  him to name it, and Tess "cook untitled recipe" is ambiguous (inferred). Old comment said "until he names it". Fix:
  say "Untitled recipe" with a rename nudge on the saved line, or number them. Owner: Product ruling.

## Part B: Groceries surface walk (raw private title?)

| Surface | Verdict | file:line |
|---|---|---|
| Row in list / SHOP mode (item) | masked "Private item" until tapped; RAW after one tap (G102) | ShopTrip.swift:23-26, 42-48; GroceriesView.swift:239-254, 489-490 |
| Basket rows | masked always | ShopTrip.swift:30-32; GroceriesView.swift:244-246, 663 |
| Row "for <recipe>" (long press) | masked "Private recipe" | ShopTrip.swift:51-54; GroceriesView.swift:216-220, 503 |
| Row VoiceOver label / hint | follows the masked label (hint "Shows it") | GroceriesView.swift:525-527 |
| Add receipt / UNDO (typed or Tess) | masked for medicine or body fact | Groceries.swift:642-688; TessCaptureEngine.swift:243-246, 383-405; BottomChrome.swift:761-767 |
| Recipe add receipt, recipe page | masked "Private recipe, N added." | Groceries.swift:557-573; RecipePage.swift:547-560 |
| Check / uncheck receipt | masked via `shownTitle` (health only, G105) | Lists.swift:346-357 |
| Clear basket, finish shop | no titles ("Cleared 3 from the basket.", "Shopping, finished.") | GroceriesView.swift:757-773 |
| Tess lines (cook, planned cook task, cooking) | masked by `ObjectPrivacy.label` | TessCaptureEngine.swift:406-419 |
| Tess pasted-recipe line | counts only, no title | TessCaptureEngine.swift:453-460 |
| Home / Now (cook, planned cook, shop, list) | masked | HomeLines.swift:593-601, 547; shop title is "Groceries" |
| Day log: cooked, saved | masked via `cookTitle` | DayStory.swift:261, 474-483 |
| Day log: "New list: <title>" | RAW (G104) | DayStory.swift:90-91, 322-323, 474-483 |
| Generic object page, Contents, Linked from, item page | RAW for listItem, list, ingredient (G103) | ObjectPrivacy.swift:40-56; ObjectPage.swift:260, 304-305, 331-334 |
| Op log summaries | RAW title in some (G106) | Groceries.swift:607; Recipes.swift:283, 322; Lists.swift:347-348 |
| Shared export | masked, but by a wider wall than screens (G105) | PrivateWords.swift:28-38, 55-73, 168-199 |
| Share sheet | NOT BUILT (no ShareLink anywhere); export row not yet wired | ExportRow.swift:5-15 |
| Notifications, widgets, Spotlight, intents | NOT BUILT for Groceries or Recipes | TesseraRuntime.swift:62-72 lists them in-app only |

## Part B gaps

- **G102 (important, Product ruling)** Tap-to-reveal prints the raw private item on screen. `ShopTrip.tap` inserts the id
  into `revealed`, and `label` then returns the item's own words. That was the K51 / B8 decision (kitchen board line 58,
  "decisions 3:12 #4"); the 3:35 PM rule as given forbids any raw title in Groceries. ShopTrip.swift:23-26, 42-48,
  GroceriesView.swift:239-254, 526. Fix if the rule supersedes: drop `revealed`, the row always reads "Private item", one
  tap strikes it, remove the "Shows it" hint. Owner: Product ruling, then Builder B screen.
- **G103 (important)** The generic object page prints raw Groceries titles. `ObjectPrivacy.label(of:)` has branches for
  note, memory, task and recipe only, so a list item ("Lexapro") returns nil, and so do a list, an ingredient, a cook and
  recipe lines. The item's own page title (ObjectPage.swift:260), the Groceries list's Contents rows (331-334) and any
  "Linked from" row (304-305) then show the raw words; a private list name shows raw instead of "Private list".
  ObjectPrivacy.swift:40-56. Reach: Objects browser or a link (inferred). Fix: add listItem to "Private item" (health,
  secret, money or title wall), list to "Private list", ingredient to the label its private users get (PrivateWords.swift:193-199
  already does this for export). Owner: Core engine, then Builder B screen to test the page.
- **G104 (important; same path as G75 in gap hunt 10, which rates it a blocker - fix once)** Day log "New list: <title>" prints a private list name raw. `StoreDayLookup.title` masks cook and
  recipe only, then returns `object.title`. DayStory.swift:322-323, 474-483. The Lists receipt masks the name
  (Lists.swift:149 uses `shownName`), so the Day log disagrees with it. Adjacent, inferred: "Done: <task titles>"
  (DayStory.swift:297, 353) uses the same lookup. Fix: in `title(of:)` use `ListContents.shownName` for lists and
  `ObjectPrivacy.label` for tasks. Owner: Core engine.
- **G105 (important, Product ruling)** Three different private-item walls. Receipts, UNDO and Tess lines use
  `EngineWall.isHealth` (Lists.swift:281-283, 310-312, Groceries.swift:644-648, TessCaptureEngine.swift:244-246); screens
  use `isPrivateRecipeTitle` (ShopTrip.swift:18, which adds secret words, money and facts); the shared export uses
  `PrivateWords.isPrivateTitle` with `titleWords` (PrivateWords.swift:28-38, so "dentist", "therapy", "clinic" mask).
  Example (inferred): a row "dentist" reads raw on screen and in its receipt but "Private item" in a shared file; a
  recipe "Dentist cake" is raw on every screen yet "Private recipe" in the export. Fix: one `ObjectPrivacy.isPrivateText`
  function used by receipts, screens and export. Owner: Product ruling on which words, then Core engine.
- **G106 (low)** Op summaries are stored with raw titles: "Took <recipe title> off groceries" (Groceries.swift:607),
  "Saved <title>" (Recipes.swift:283), "Changed <title>" (Recipes.swift:322), "Back on the list: <title>" and "Got <title>"
  (Lists.swift:347-348, health-only mask). No screen found prints them (Receipts.swift:5 says summaries are never shown
  raw), but they sit in the op log, and the export judges them with the narrow wall. They are also not thing-first, unlike
  the receipts. Fix: build summaries through the same label function. Owner: Core engine.
- **G107 (low)** Recipe-to-Groceries rows skip the Add-line wall. `addGroceryShare(text: ingredient.title.lowercased())`
  only swaps in "Private item" for `isSecretListLine` (Groceries.swift:365, 506); a medicine or body-fact ingredient is
  stored raw as the row title (screens mask it by text, G105). Fix: run the text through `AddListItem.shownTitle` before
  `createGroceryRow`. Owner: Core engine.
- **G108 (low)** UNDO names the wrong thing for a 3+ item add. `UndoCopy.takenBack` cuts at the first ", ", and the
  receipt "Oat milk, eggs and 2 more, on Groceries" becomes "Oat milk, taken back." although four things went. Not a
  privacy leak (a private first item reads "Private item, taken back."). BottomChrome.swift:763-767; Groceries.swift:682-687.
  Fix: cut at the last ", on " instead. Owner: Builder B screen.

Counts: 16 gaps (G93-G108): 0 blocker, 8 important (G93, G94, G96, G98, G102, G103, G104, G105), 8 low
(G95, G97, G99, G100, G101, G106, G107, G108). Acceptance rows: 17 (13 PASS, 1 FAIL, 1 PASS-with-gap, 1 NOT PROVABLE,
1 untested PASS by read); NOT BUILT surfaces: share sheet, notifications, widgets, Spotlight, intents.

## Still open

- Whether the 3:35 PM rule overrides tap-to-reveal (G102) and which words count as private (G105).
- Definition of "quantity" in the title rule (G94, G95).
- No test for: trailing space or CRLF duplicate, undo then repaste, private-title collision, "!" or "?" kept as step 1.
- Who owns the Tess "Done:" task titles in the Day log (G104, adjacent).
- Export UI row is not wired to the masked export yet (ExportRow.swift:11), so the masked path is untested end to end.

## Phone only

- Paste screen ink line, no haptic, text kept after a duplicate Save; the Save bar after the line.
- VoiceOver reading of masked rows and the "Shows it" hint; Dynamic Type at AX sizes on the duplicate line.
- The generic object page for a Groceries item and for the Groceries list (G103) on a real private item.
- Day log with a private list name (G104).
- Paste of a real web recipe with curly quotes and emoji (G96) and a CJK recipe (G97).
